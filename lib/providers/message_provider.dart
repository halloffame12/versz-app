import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../core/services/appwrite_service.dart';
import '../core/services/realtime_service.dart';
import '../models/message.dart';
import '../core/constants/appwrite_constants.dart';
import 'package:appwrite/appwrite.dart';

final messageProvider = StateNotifierProvider.family<MessageNotifier, MessageState, String>((ref, roomId) {
  final appwrite = AppwriteService();
  return MessageNotifier(appwrite, RealtimeService(appwrite.client), roomId);
});

class MessageState {
  final List<Message> messages;
  final bool isLoading;
  final Set<String> retryingMessageIds;
  final Set<String> retrySuccessMessageIds;
  final String? currentUserId;
  final String? error;

  MessageState({
    this.messages = const [],
    this.isLoading = false,
    this.retryingMessageIds = const {},
    this.retrySuccessMessageIds = const {},
    this.currentUserId,
    this.error,
  });

  MessageState copyWith({
    List<Message>? messages,
    bool? isLoading,
    Set<String>? retryingMessageIds,
    Set<String>? retrySuccessMessageIds,
    String? currentUserId,
    String? error,
  }) {
    return MessageState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      retryingMessageIds: retryingMessageIds ?? this.retryingMessageIds,
      retrySuccessMessageIds: retrySuccessMessageIds ?? this.retrySuccessMessageIds,
      currentUserId: currentUserId ?? this.currentUserId,
      error: error ?? this.error,
    );
  }
}

class MessageNotifier extends StateNotifier<MessageState> {
  final AppwriteService _appwrite;
  final RealtimeService _realtime;
  final String _roomId;

  MessageNotifier(this._appwrite, this._realtime, this._roomId) : super(MessageState());

  Future<bool> _antiSpamAllowsMessage(String userId) async {
    try {
      final execution = await _appwrite.functions.createExecution(
        functionId: 'anti-spam-check',
        body: jsonEncode({'userId': userId, 'action': 'message_sent'}),
        xasync: false,
      );
      final body = execution.responseBody;
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded['allowed'] != false;
      }
      return true;
    } catch (_) {
      // Anti-spam function is fail-open by design.
      return true;
    }
  }

  Future<void> _ensureCurrentUserId() async {
    if (state.currentUserId != null && state.currentUserId!.isNotEmpty) return;
    try {
      final me = await _appwrite.account.get();
      state = state.copyWith(currentUserId: me.$id);
    } catch (_) {
      // Keep null if unavailable.
    }
  }

  void subscribe() {
    _realtime.subscribeToCollection(
      AppwriteConstants.messagesCollection,
      (data) {
        final message = Message.fromMap(data);
        if (message.roomId == _roomId) {
          final exists = state.messages.any((m) => m.id == message.id);
          if (exists) return;
          state = state.copyWith(messages: [message, ...state.messages]);
        }
      },
    );
  }

  Future<void> fetchMessages() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _ensureCurrentUserId();
      final response = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.messagesCollection,
        queries: [
          Query.equal('chatId', _roomId),
          Query.orderDesc('\$createdAt'),
          Query.limit(50),
        ],
      );
      final messages = response.documents.map((doc) => Message.fromMap(doc.data)).toList();
      state = state.copyWith(messages: messages, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> sendMessage(String content) async {
    final clientNonce = 'msg-${DateTime.now().microsecondsSinceEpoch}';
    String tempId = '';
    try {
      final user = await _appwrite.account.get();
      final allowed = await _antiSpamAllowsMessage(user.$id);
      if (!allowed) {
        state = state.copyWith(error: 'Rate limit reached. Please wait and try again.');
        return;
      }
      await _ensureCurrentUserId();
      String? senderName;
      String? senderAvatar;
      try {
        final profile = await _appwrite.databases.getDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.usersCollection,
          documentId: user.$id,
        );
        senderName = (profile.data['displayName'] ?? profile.data['username'])?.toString();
        senderAvatar = profile.data['avatar']?.toString();
      } catch (_) {
        // Optional denormalized sender fields.
      }

      tempId = 'temp-${DateTime.now().microsecondsSinceEpoch}';
      final optimistic = Message(
        id: tempId,
        chatId: _roomId,
        senderId: user.$id,
        senderName: senderName,
        senderAvatar: senderAvatar,
        content: content,
        type: 'text',
        status: 'sending',
        createdAt: DateTime.now(),
      );
      state = state.copyWith(messages: [optimistic, ...state.messages]);

      // Idempotency guard: if the same nonce was already persisted, do not create a duplicate.
      final existing = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.messagesCollection,
        queries: [
          Query.equal('chatId', _roomId),
          Query.equal('senderId', user.$id),
          Query.equal('clientNonce', clientNonce),
          Query.limit(1),
        ],
      );

      if (existing.documents.isEmpty) {
        await _appwrite.databases.createDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.messagesCollection,
          documentId: ID.unique(),
          data: {
            'chatId': _roomId,
            'senderId': user.$id,
            'senderName': senderName,
            'senderAvatar': senderAvatar,
            'clientNonce': clientNonce,
            'content': content,
            'type': 'text',
            'status': 'sent',
            'createdAt': DateTime.now().toIso8601String(),
          },
        );
      }

      state = state.copyWith(messages: state.messages.where((m) => m.id != tempId).toList());
      await fetchMessages();
    } catch (e) {
      if (tempId.isNotEmpty) {
        state = state.copyWith(
          messages: state.messages
              .map((m) => m.id == tempId ? m.copyWith(status: 'failed') : m)
              .toList(),
          error: e.toString(),
        );
        return;
      }
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> retryFailedMessage(String messageId) async {
    if (state.retryingMessageIds.contains(messageId)) return;
    final target = state.messages.firstWhere(
      (m) => m.id == messageId,
      orElse: () => Message(
        id: '',
        senderId: '',
        content: '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );
    if (target.id.isEmpty || target.content.trim().isEmpty) return;

    state = state.copyWith(
      retryingMessageIds: {...state.retryingMessageIds, messageId},
      messages: state.messages
          .map((m) => m.id == messageId ? m.copyWith(status: 'sending') : m)
          .toList(),
      error: null,
    );

    try {
      await sendMessage(target.content);
      final success = {...state.retrySuccessMessageIds, messageId};
      state = state.copyWith(retrySuccessMessageIds: success);
      await Future.delayed(const Duration(milliseconds: 240));
      state = state.copyWith(
        retrySuccessMessageIds: {...state.retrySuccessMessageIds}..remove(messageId),
      );
    } finally {
      state = state.copyWith(
        retryingMessageIds: {...state.retryingMessageIds}..remove(messageId),
      );
    }
  }

  Future<void> editMessage(String messageId, String newContent) async {
    try {
      await _appwrite.databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.messagesCollection,
        documentId: messageId,
        data: {
          'content': newContent,
        },
      );
      await fetchMessages();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _appwrite.databases.deleteDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.messagesCollection,
        documentId: messageId,
      );
      await fetchMessages();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
