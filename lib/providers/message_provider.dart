import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final String? error;

  MessageState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  MessageState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? error,
  }) {
    return MessageState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class MessageNotifier extends StateNotifier<MessageState> {
  final AppwriteService _appwrite;
  final RealtimeService _realtime;
  final String _roomId;

  MessageNotifier(this._appwrite, this._realtime, this._roomId) : super(MessageState());

  void subscribe() {
    _realtime.subscribeToCollection(
      AppwriteConstants.messagesCollection,
      (data) {
        final message = Message.fromMap(data);
        if (message.roomId == _roomId) {
          state = state.copyWith(messages: [message, ...state.messages]);
        }
      },
    );
  }

  Future<void> fetchMessages() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
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
    try {
      final user = await _appwrite.account.get();
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

      await _appwrite.databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.messagesCollection,
        documentId: ID.unique(),
        data: {
          'chatId': _roomId,
          'senderId': user.$id,
          'senderName': senderName,
          'senderAvatar': senderAvatar,
          'content': content,
          'type': 'text',
          'status': 'sent',
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
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
