import 'dart:convert';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/appwrite_service.dart';
import '../core/services/realtime_service.dart';
import '../core/constants/appwrite_constants.dart';
import '../models/message.dart' as model;
import '../models/conversation.dart';
import 'package:appwrite/appwrite.dart';

Map<String, int> _decodeUnreadCounts(dynamic raw) {
  if (raw == null) return {};
  try {
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), int.tryParse(value.toString()) ?? 0));
    }
    final decoded = jsonDecode(raw.toString());
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), int.tryParse(value.toString()) ?? 0));
    }
  } catch (_) {
    // fall through
  }
  return {};
}

String _encodeUnreadCounts(Map<String, int> counts) => jsonEncode(counts);

final conversationProvider = StateNotifierProvider.family<ConversationNotifier, ConversationState, String>(
  (ref, conversationId) {
    final appwrite = AppwriteService();
    return ConversationNotifier(appwrite, RealtimeService(appwrite.client), conversationId);
  },
);

final conversationsListProvider = StateNotifierProvider<ConversationsListNotifier, ConversationsListState>((ref) {
  return ConversationsListNotifier(AppwriteService());
});

class ConversationState {
  final List<model.Message> messages;
  final bool isLoading;
  final bool isOtherUserTyping;
  final Set<String> retryingMessageIds;
  final Set<String> retrySuccessMessageIds;
  final String? error;

  ConversationState({
    this.messages = const [],
    this.isLoading = false,
    this.isOtherUserTyping = false,
    this.retryingMessageIds = const {},
    this.retrySuccessMessageIds = const {},
    this.error,
  });

  ConversationState copyWith({
    List<model.Message>? messages,
    bool? isLoading,
    bool? isOtherUserTyping,
    Set<String>? retryingMessageIds,
    Set<String>? retrySuccessMessageIds,
    String? error,
  }) {
    return ConversationState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isOtherUserTyping: isOtherUserTyping ?? this.isOtherUserTyping,
      retryingMessageIds: retryingMessageIds ?? this.retryingMessageIds,
      retrySuccessMessageIds: retrySuccessMessageIds ?? this.retrySuccessMessageIds,
      error: error ?? this.error,
    );
  }
}
class ConversationNotifier extends StateNotifier<ConversationState> {
  final AppwriteService _appwrite;
  final RealtimeService _realtime;
  final String _conversationId;
  String? _selfUserId;
  Timer? _otherTypingTimeout;

  ConversationNotifier(this._appwrite, this._realtime, this._conversationId) : super(ConversationState()) {
    _loadMessages();
  }

  Future<void> fetchMessages() async {
    await _loadMessages();
  }

  Future<void> subscribe() async {
    try {
      _selfUserId ??= (await _appwrite.account.get()).$id;

      _realtime.subscribe([
        'databases.default.collections.${AppwriteConstants.messagesCollection}.documents',
        'databases.${AppwriteConstants.databaseId}.collections.${AppwriteConstants.messagesCollection}.documents',
        'databases.default.collections.${AppwriteConstants.typingStatus}.documents',
        'databases.${AppwriteConstants.databaseId}.collections.${AppwriteConstants.typingStatus}.documents',
      ]);

      _realtime.stream.listen((event) {
        final data = event.payload;

        // Typing payloads carry `is_typing` while messages do not.
        if (data.containsKey('is_typing')) {
          final chatId = data['chat_id']?.toString();
          final userId = data['user_id']?.toString();
          if (chatId == _conversationId && userId != null && userId != _selfUserId) {
            final typing = data['is_typing'] == true;
            state = state.copyWith(isOtherUserTyping: typing);

            // Auto-clear stale typing state if no follow-up event arrives.
            _otherTypingTimeout?.cancel();
            if (typing) {
              _otherTypingTimeout = Timer(const Duration(seconds: 3), () {
                state = state.copyWith(isOtherUserTyping: false);
              });
            }
          }
          return;
        }

        if (data['conversation_id'] == _conversationId || data['chat_id'] == _conversationId) {
          final newMessage = model.Message.fromMap(data);
          state = state.copyWith(messages: [newMessage, ...state.messages]);
        }
      });
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateTyping({required bool isTyping}) async {
    try {
      final me = await _appwrite.account.get();
      final existing = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.typingStatus,
        queries: [
          Query.equal('chat_id', _conversationId),
          Query.equal('user_id', me.$id),
          Query.limit(1),
        ],
      );

      if (existing.documents.isEmpty) {
        await _appwrite.databases.createDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.typingStatus,
          documentId: ID.unique(),
          data: {
            'chat_id': _conversationId,
            'user_id': me.$id,
            'is_typing': isTyping,
            'updated_at': DateTime.now().toIso8601String(),
          },
        );
      } else {
        await _appwrite.databases.updateDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.typingStatus,
          documentId: existing.documents.first.$id,
          data: {
            'is_typing': isTyping,
            'updated_at': DateTime.now().toIso8601String(),
          },
        );
      }
    } catch (_) {
      // Non-critical UX signal.
    }
  }

  Future<void> _loadMessages() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.messagesCollection,
        queries: [
          Query.or([
            Query.equal('conversation_id', _conversationId),
            Query.equal('chat_id', _conversationId),
          ]),
          Query.orderAsc('\$createdAt'),
          Query.limit(100),
        ],
      );

      final messages = response.documents.map((doc) => model.Message.fromMap(doc.data)).toList();
      state = state.copyWith(messages: messages, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> sendMessage(String content) async {
    var tempId = '';
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
        senderName = (profile.data['display_name'] ?? profile.data['username'])?.toString();
        senderAvatar = profile.data['avatar_url']?.toString();
      } catch (_) {
        // Optional denormalized sender fields.
      }

      // Optimistic local bubble so send feels instant.
      tempId = 'temp-${DateTime.now().microsecondsSinceEpoch}';
      final optimistic = model.Message(
        id: tempId,
        chatId: _conversationId,
        conversationId: _conversationId,
        senderId: user.$id,
        content: content,
        type: 'text',
        messageType: 'text',
        status: 'sending',
        isRead: false,
        createdAt: DateTime.now(),
      );
      state = state.copyWith(messages: [...state.messages, optimistic]);

      await _appwrite.databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.messagesCollection,
        documentId: ID.unique(),
        data: {
          'chat_id': _conversationId,
          'conversation_id': _conversationId,
          'sender_id': user.$id,
          'sender_name': senderName,
          'sender_avatar': senderAvatar,
          'content': content,
          'type': 'text',
          'message_type': 'text',
          'status': 'sent',
          'is_read': false,
        },
      );

      await _updateConversationPreview(senderId: user.$id, content: content);

      final updated = state.messages.where((m) => m.id != tempId).toList();
      state = state.copyWith(messages: updated);

      await _loadMessages();
    } catch (e) {
      if (tempId.isNotEmpty) {
        final updated = state.messages.map((m) {
          if (m.id != tempId) return m;
          return model.Message(
            id: m.id,
            chatId: m.chatId,
            conversationId: m.conversationId,
            roomId: m.roomId,
            senderId: m.senderId,
            content: m.content,
            type: m.type,
            messageType: m.messageType,
            status: 'failed',
            isRead: m.isRead,
            createdAt: m.createdAt,
          );
        }).toList();
        state = state.copyWith(messages: updated);
      }
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> retryFailedMessage(
    String tempMessageId,
    String content, {
    int successHoldMillis = 260,
  }) async {
    if (state.retryingMessageIds.contains(tempMessageId)) {
      return;
    }

    final retrying = {...state.retryingMessageIds, tempMessageId};
    state = state.copyWith(
      retryingMessageIds: retrying,
      error: null,
      messages: state.messages.map((m) => m.id == tempMessageId ? _withStatus(m, 'sending') : m).toList(),
    );

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
        senderName = (profile.data['display_name'] ?? profile.data['username'])?.toString();
        senderAvatar = profile.data['avatar_url']?.toString();
      } catch (_) {
        // Optional denormalized sender fields.
      }

      await _appwrite.databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.messagesCollection,
        documentId: ID.unique(),
        data: {
          'chat_id': _conversationId,
          'conversation_id': _conversationId,
          'sender_id': user.$id,
          'sender_name': senderName,
          'sender_avatar': senderAvatar,
          'content': content,
          'type': 'text',
          'message_type': 'text',
          'status': 'sent',
          'is_read': false,
        },
      );

      await _updateConversationPreview(senderId: user.$id, content: content);

      final success = {...state.retrySuccessMessageIds, tempMessageId};
      state = state.copyWith(
        retrySuccessMessageIds: success,
        messages: state.messages.map((m) => m.id == tempMessageId ? _withStatus(m, 'sent') : m).toList(),
      );

      await Future.delayed(Duration(milliseconds: successHoldMillis));
      await _loadMessages();
      final successCleared = {...state.retrySuccessMessageIds}..remove(tempMessageId);
      state = state.copyWith(retrySuccessMessageIds: successCleared);
    } catch (e) {
      final successCleared = {...state.retrySuccessMessageIds}..remove(tempMessageId);
      state = state.copyWith(
        error: e.toString(),
        messages: state.messages.map((m) => m.id == tempMessageId ? _withStatus(m, 'failed') : m).toList(),
        retrySuccessMessageIds: successCleared,
      );
    } finally {
      final updatedRetrying = {...state.retryingMessageIds}..remove(tempMessageId);
      state = state.copyWith(retryingMessageIds: updatedRetrying);
    }
  }

  model.Message _withStatus(model.Message message, String status) {
    return model.Message(
      id: message.id,
      chatId: message.chatId,
      conversationId: message.conversationId,
      roomId: message.roomId,
      senderId: message.senderId,
      content: message.content,
      type: message.type,
      messageType: message.messageType,
      status: status,
      isRead: message.isRead,
      createdAt: message.createdAt,
    );
  }

  Future<void> _updateConversationPreview({
    required String senderId,
    required String content,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    final updateData = {
      'last_message': content,
      'last_message_type': 'text',
      'last_message_sender_id': senderId,
      'last_message_at': nowIso,
      'updated_at': nowIso,
    };

    try {
      final chatDoc = await _appwrite.databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.chats,
        documentId: _conversationId,
      );

      final p1 = chatDoc.data['participant_1']?.toString();
      final p2 = chatDoc.data['participant_2']?.toString();
      final otherId = p1 == senderId ? p2 : p1;
      final unread = _decodeUnreadCounts(chatDoc.data['unread_counts']);
      unread[senderId] = unread[senderId] ?? 0;
      if (otherId != null && otherId.isNotEmpty) {
        unread[otherId] = (unread[otherId] ?? 0) + 1;
      }

      await _appwrite.databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.chats,
        documentId: _conversationId,
        data: {
          ...updateData,
          'unread_counts': _encodeUnreadCounts(unread),
        },
      );
    } catch (_) {
      await _appwrite.databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.conversationsCollection,
        documentId: _conversationId,
        data: {
          'last_message': content,
          'last_message_at': nowIso,
        },
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

      await _loadMessages();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markIncomingAsRead(String currentUserId) async {
    try {
      final response = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.messagesCollection,
        queries: [
          Query.or([
            Query.equal('conversation_id', _conversationId),
            Query.equal('chat_id', _conversationId),
          ]),
          Query.notEqual('sender_id', currentUserId),
          Query.limit(100),
        ],
      );

      for (final doc in response.documents) {
        final isRead = doc.data['is_read'] == true;
        final status = (doc.data['status'] ?? '').toString().toLowerCase();
        if (isRead && status == 'read') continue;

        await _appwrite.databases.updateDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.messagesCollection,
          documentId: doc.$id,
          data: {
            'is_read': true,
            'status': 'read',
          },
        );
      }

      try {
        final chatDoc = await _appwrite.databases.getDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.chats,
          documentId: _conversationId,
        );
        final unread = _decodeUnreadCounts(chatDoc.data['unread_counts']);
        unread[currentUserId] = 0;

        await _appwrite.databases.updateDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.chats,
          documentId: _conversationId,
          data: {
            'unread_counts': _encodeUnreadCounts(unread),
            'updated_at': DateTime.now().toIso8601String(),
          },
        );
      } catch (_) {
        // Legacy conversation or unavailable chat doc.
      }

      await _loadMessages();
    } catch (_) {
      // Best-effort read receipts should not block chat UX.
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _appwrite.databases.deleteDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.messagesCollection,
        documentId: messageId,
      );

      await _loadMessages();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  @override
  void dispose() {
    _otherTypingTimeout?.cancel();
    _realtime.dispose();
    super.dispose();
  }
}

// Conversations List State
class ConversationsListState {
  final List<Conversation> conversations;
  final bool isLoading;
  final String? error;

  ConversationsListState({
    this.conversations = const [],
    this.isLoading = false,
    this.error,
  });

  ConversationsListState copyWith({
    List<Conversation>? conversations,
    bool? isLoading,
    String? error,
  }) {
    return ConversationsListState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ConversationsListNotifier extends StateNotifier<ConversationsListState> {
  final AppwriteService _appwrite;
  final RealtimeService _realtime;
  String? _currentUserId;
  Timer? _refreshDebounce;

  ConversationsListNotifier(this._appwrite)
      : _realtime = RealtimeService(_appwrite.client),
        super(ConversationsListState()) {
    _loadConversations();
    _subscribeToConversationUpdates();
  }

  String get currentUserId => _currentUserId ?? '';

  Future<void> fetchConversations() async {
    await _loadConversations();
  }

  void _subscribeToConversationUpdates() {
    _realtime.subscribe([
      'databases.default.collections.${AppwriteConstants.chats}.documents',
      'databases.${AppwriteConstants.databaseId}.collections.${AppwriteConstants.chats}.documents',
      'databases.default.collections.${AppwriteConstants.messagesCollection}.documents',
      'databases.${AppwriteConstants.databaseId}.collections.${AppwriteConstants.messagesCollection}.documents',
    ]);

    _realtime.stream.listen((_) {
      _scheduleRefresh();
    });
  }

  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 450), () {
      _loadConversations();
    });
  }

  Future<void> _loadConversations() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _appwrite.account.get();
      _currentUserId = user.$id;

      final response = await _listUserConversations(user.$id);

      final rawConversations = response.documents.map((doc) {
        final conv = Conversation.fromMap(doc.data);
        final unread = _decodeUnreadCounts(doc.data['unread_counts']);
        return conv.copyWith(
          unreadCount1: unread[conv.participant1] ?? conv.unreadCount1,
          unreadCount2: unread[conv.participant2] ?? conv.unreadCount2,
        );
      }).toList();
      final userIds = <String>{};
      for (final c in rawConversations) {
        userIds.add(c.participant1);
        userIds.add(c.participant2);
      }

      final userMap = await _getUsersMap(userIds);
      final conversations = rawConversations.map((c) {
        final p1 = userMap[c.participant1];
        final p2 = userMap[c.participant2];
        return c.copyWith(
          participant1Name: p1?['display_name']?.toString() ?? p1?['username']?.toString() ?? c.participant1,
          participant2Name: p2?['display_name']?.toString() ?? p2?['username']?.toString() ?? c.participant2,
          participant1Avatar: p1?['avatar_url']?.toString(),
          participant2Avatar: p2?['avatar_url']?.toString(),
        );
      }).toList();

      state = state.copyWith(conversations: conversations, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> startConversation(String otherUserId) async {
    try {
      final user = await _appwrite.account.get();

      // Gate DM creation: only connected users can start new chats.
      final connectionRes = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.connections,
        queries: [
          Query.equal('status', 'connected'),
          Query.or([
            Query.and([
              Query.equal('requester_id', user.$id),
              Query.equal('receiver_id', otherUserId),
            ]),
            Query.and([
              Query.equal('requester_id', otherUserId),
              Query.equal('receiver_id', user.$id),
            ]),
          ]),
          Query.limit(1),
        ],
      );

      if (connectionRes.documents.isEmpty) {
        state = state.copyWith(error: 'You can only message connected users.');
        return;
      }

      // Check if chat/conversation already exists.
      final existing = await _listUserConversations(user.$id, limit: 100);

      for (final doc in existing.documents) {
        final p1 = doc.data['participant_1'];
        final p2 = doc.data['participant_2'];
        if ((p1 == user.$id && p2 == otherUserId) || (p1 == otherUserId && p2 == user.$id)) {
          // Conversation already exists
          return;
        }
      }

      // Create new chat in v3 collection, fallback to legacy collection.
      try {
        await _appwrite.databases.createDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.chats,
          documentId: ID.unique(),
          data: {
            'participant_1': user.$id,
            'participant_2': otherUserId,
            'participants': '["${user.$id}","$otherUserId"]',
            'is_group': false,
            'last_message': '',
            'last_message_type': 'text',
            'last_message_at': DateTime.now().toIso8601String(),
            'unread_counts': _encodeUnreadCounts({user.$id: 0, otherUserId: 0}),
            'updated_at': DateTime.now().toIso8601String(),
          },
        );
      } catch (_) {
        await _appwrite.databases.createDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.conversationsCollection,
          documentId: ID.unique(),
          data: {
            'participant_1': user.$id,
            'participant_2': otherUserId,
            'last_message': '',
            'last_message_at': DateTime.now().toIso8601String(),
          },
        );
      }

      await _loadConversations();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<dynamic> _listUserConversations(String userId, {int limit = 50}) async {
    final commonQueries = [
      Query.or([
        Query.equal('participant_1', userId),
        Query.equal('participant_2', userId),
      ]),
      Query.orderDesc('last_message_at'),
      Query.limit(limit),
    ];

    try {
      return await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.chats,
        queries: commonQueries,
      );
    } catch (_) {
      return _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.conversationsCollection,
        queries: commonQueries,
      );
    }
  }

  Future<Map<String, Map<String, dynamic>>> _getUsersMap(Set<String> userIds) async {
    final result = <String, Map<String, dynamic>>{};
    for (final id in userIds) {
      try {
        final doc = await _appwrite.databases.getDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.usersCollection,
          documentId: id,
        );
        result[id] = doc.data;
      } catch (_) {
        // Ignore missing profiles and keep ID fallback in UI.
      }
    }
    return result;
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    _realtime.dispose();
    super.dispose();
  }
}