// ignore_for_file: avoid_print, deprecated_member_use

import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/enums.dart';

const String _endpoint = 'https://sgp.cloud.appwrite.io/v1';
const String _projectId = '69b00336003a3772ee69';
const String _databaseId = 'versz-db';

String get _apiKey {
  final key = Platform.environment['APPWRITE_API_KEY'];
  if (key == null || key.trim().isEmpty) {
    throw StateError(
      'APPWRITE_API_KEY is required. Set the environment variable before running setup_appwrite.',
    );
  }
  return key.trim();
}

late Client _client;
late Databases _db;
late Storage _storage;

int _created = 0;
int _skipped = 0;
int _errors = 0;

Future<void> main(List<String> args) async {
  // Safety guard: wipe is destructive. Require explicit --wipe flag.
  final doWipe = args.contains('--wipe');

  _client = Client()
      .setEndpoint(_endpoint)
      .setProject(_projectId)
      .setKey(_apiKey);
  // Do NOT call setSelfSigned() in production. Only enable for local dev:
  // .setSelfSigned(status: true)

  _db = Databases(_client);
  _storage = Storage(_client);

  _banner('VERSZ APPWRITE SCHEMA v3');

  if (doWipe) {
    print('WARNING: --wipe flag detected. All existing collections and buckets will be deleted.');
    print('Press Ctrl+C within 5 seconds to abort...');
    await Future.delayed(const Duration(seconds: 5));
    await _wipe();
  } else {
    _section('SKIPPING WIPE (pass --wipe to destroy and rebuild)');
  }
  await _ensureDatabase();
  await _createCollections();
  await _createBuckets();
  await _seedCategories();

  _summary();
}

Future<void> _wipe() async {
  _section('WIPING EXISTING COLLECTIONS AND BUCKETS');

  try {
    final collections = await _db.listCollections(databaseId: _databaseId);
    for (final collection in collections.collections) {
      await _db.deleteCollection(
        databaseId: _databaseId,
        collectionId: collection.$id,
      );
      print('  deleted collection: ${collection.name}');
    }
  } catch (e) {
    print('  collections skipped: $e');
  }

  try {
    final buckets = await _storage.listBuckets();
    for (final bucket in buckets.buckets) {
      await _storage.deleteBucket(bucketId: bucket.$id);
      print('  deleted bucket: ${bucket.name}');
    }
  } catch (e) {
    print('  buckets skipped: $e');
  }
}

Future<void> _ensureDatabase() async {
  _section('DATABASE');
  try {
    await _db.get(databaseId: _databaseId);
    _skip('Database $_databaseId');
  } on AppwriteException catch (e) {
    if (e.code == 404) {
      try {
        await _db.create(
          databaseId: _databaseId,
          name: 'Versz Database',
          enabled: true,
        );
        _ok('Database $_databaseId');
      } catch (e2) {
        _err('Database', e2);
      }
      return;
    }
    _err('Database', e);
  }
}

Future<void> _createCollections() async {
  _section('COLLECTIONS (22 total)');

  await _col('users', 'Users', perms: _anyRead, attrs: [
    _S('userId', 255, req: true),
    _S('username', 255, req: true),
    _S('displayName', 255, req: true),
    _S('email', 255, req: true),
    _S('avatar', 500),
    _S('coverImage', 500),
    _S('bio', 1000),
    _S('website', 255),
    _I('xp', req: true, def: 0, min: 0, max: 99999999),
    _I('weeklyXp', req: true, def: 0, min: 0, max: 99999999),
    _I('followersCount', req: true, def: 0, min: 0, max: 9999999),
    _I('followingCount', req: true, def: 0, min: 0, max: 9999999),
    _I('connectionsCount', req: true, def: 0, min: 0, max: 9999999),
    _I('debatesCreated', req: true, def: 0, min: 0, max: 9999999),
    _I('totalVotes', req: true, def: 0, min: 0, max: 9999999),
    _I('currentStreak', req: true, def: 0, min: 0, max: 9999),
    _I('longestStreak', req: true, def: 0, min: 0, max: 9999),
    _D('winRate', def: 0.0, min: 0.0, max: 100.0),
    _B('isVerified', req: true, def: false),
    _B('isOnline', req: true, def: true),
    _B('isPrivate', req: true, def: false),
    _S('messagingPrivacy', 32, def: 'everyone'),
    _S('notifPrefs', 2000, def: '{}'),
    _S('lastVoteDate', 40),
    _S('lastSeen', 40),
    _S('fcmToken', 1000),
    _S('createdAt', 40),
    _S('updatedAt', 40),
  ], idxs: [
    _Idx('user_id_idx', 'key', ['userId'], ['asc']),
    _Idx('username_unique', 'unique', ['username'], ['asc']),
    _Idx('username_ft', 'fulltext', ['username'], ['asc']),
    _Idx('display_name_ft', 'fulltext', ['displayName'], ['asc']),
    _Idx('xp_idx', 'key', ['xp'], ['desc']),
    _Idx('weekly_xp_idx', 'key', ['weeklyXp'], ['desc']),
  ]);

  await _col('debates', 'Debates', perms: _anyRead, attrs: [
    _S('topic', 300, req: true),
    _S('description', 4000),
    _S('context', 2000),
    _S('category', 255, req: true),
    _S('creatorId', 255, req: true),
    _S('creatorName', 255, req: true),
    _S('creatorAvatar', 500),
    _S('imageUrl', 1000),
    _I('agreeCount', req: true, def: 0, min: 0, max: 99999999),
    _I('disagreeCount', req: true, def: 0, min: 0, max: 99999999),
    _I('upvotes', req: true, def: 0, min: 0, max: 99999999),
    _I('downvotes', req: true, def: 0, min: 0, max: 99999999),
    _I('likeCount', req: true, def: 0, min: 0, max: 99999999),
    _I('commentCount', req: true, def: 0, min: 0, max: 99999999),
    _I('viewCount', req: true, def: 0, min: 0, max: 99999999),
    _S('status', 32, req: true, def: 'active'),
    _S('communityId', 255),
    _S('aiSummary', 4000),
    _S('winningSide', 16),
    _B('isTrending', req: true, def: false),
    _D('trendingScore', def: 0.0, min: 0.0),
    _S('hashtags', 2000),
    _S('createdAt', 40),
    _S('updatedAt', 40),
  ], idxs: [
    _Idx('topic_ft', 'fulltext', ['topic'], ['asc']),
    _Idx('category_idx', 'key', ['category'], ['asc']),
    _Idx('creator_idx', 'key', ['creatorId'], ['asc']),
    _Idx('status_idx', 'key', ['status'], ['asc']),
    _Idx('status_created_idx', 'key', ['status', 'createdAt'], ['asc', 'desc']),
    _Idx('category_created_idx', 'key', ['category', 'createdAt'], ['asc', 'desc']),
    _Idx('creator_created_idx', 'key', ['creatorId', 'createdAt'], ['asc', 'desc']),
    _Idx('agree_idx', 'key', ['agreeCount'], ['desc']),
    _Idx('trending_idx', 'key', ['trendingScore'], ['desc']),
    _Idx('community_idx', 'key', ['communityId'], ['asc']),
  ]);

  await _col('comments', 'Comments', perms: _anyRead, attrs: [
    _S('debateId', 255, req: true),
    _S('userId', 255, req: true),
    _S('username', 255, req: true),
    _S('userAvatar', 500),
    _S('parentId', 255),
    _S('content', 4000, req: true),
    _S('side', 16),
    _I('upvotes', req: true, def: 0, min: 0, max: 999999),
    _I('downvotes', req: true, def: 0, min: 0, max: 999999),
    _I('replyCount', req: true, def: 0, min: 0, max: 999999),
    _B('isDeleted', req: true, def: false),
    _B('isEdited', req: true, def: false),
    _S('createdAt', 40),
    _S('updatedAt', 40),
  ], idxs: [
    _Idx('debate_idx', 'key', ['debateId'], ['asc']),
    _Idx('debate_created_idx', 'key', ['debateId', 'createdAt'], ['asc', 'desc']),
    _Idx('parent_idx', 'key', ['parentId'], ['asc']),
    _Idx('user_idx', 'key', ['userId'], ['asc']),
    _Idx('user_created_idx', 'key', ['userId', 'createdAt'], ['asc', 'desc']),
    _Idx('is_deleted_idx', 'key', ['isDeleted'], ['asc']),
  ]);

  await _col('votes', 'Votes', perms: _ownerWrite, attrs: [
    _S('debateId', 255, req: true),
    _S('userId', 255, req: true),
    _S('side', 16, req: true),
    _S('createdAt', 40),
  ], idxs: [
    _Idx('unique_vote', 'unique', ['debateId', 'userId'], ['asc', 'asc']),
    _Idx('debate_idx', 'key', ['debateId'], ['asc']),
    _Idx('user_idx', 'key', ['userId'], ['asc']),
    _Idx('user_created_idx', 'key', ['userId', 'createdAt'], ['asc', 'desc']),
    _Idx('debate_created_idx', 'key', ['debateId', 'createdAt'], ['asc', 'desc']),
  ]);

  await _col('likes', 'Likes', perms: _ownerWrite, attrs: [
    _S('debateId', 255, req: true),
    _S('userId', 255, req: true),
    _S('createdAt', 40),
  ], idxs: [
    _Idx('unique_like', 'unique', ['debateId', 'userId'], ['asc', 'asc']),
    _Idx('debate_idx', 'key', ['debateId'], ['asc']),
    _Idx('user_idx', 'key', ['userId'], ['asc']),
  ]);

  await _col('saves', 'Saves', perms: _ownerWrite, attrs: [
    _S('userId', 255, req: true),
    _S('debateId', 255, req: true),
    _S('createdAt', 40),
  ], idxs: [
    _Idx('unique_save', 'unique', ['userId', 'debateId'], ['asc', 'asc']),
    _Idx('user_idx', 'key', ['userId'], ['asc']),
    _Idx('debate_idx', 'key', ['debateId'], ['asc']),
  ]);

  await _col('connections', 'Connections', perms: _ownerWrite, attrs: [
    _S('requesterId', 255, req: true),
    _S('receiverId', 255, req: true),
    _S('status', 24, req: true),
    _S('createdAt', 40),
    _S('updatedAt', 40),
  ], idxs: [
    _Idx('unique_connection', 'unique', ['requesterId', 'receiverId'], ['asc', 'asc']),
    _Idx('requester_idx', 'key', ['requesterId'], ['asc']),
    _Idx('receiver_idx', 'key', ['receiverId'], ['asc']),
    _Idx('status_idx', 'key', ['status'], ['asc']),
  ]);

  // docSecurity:true — each chat document gets per-participant read permissions
  // so users only receive their own conversations from realtime and list queries.
  await _col('chats', 'Chats', perms: _userOnly, docSecurity: true, attrs: [
    _S('participants', 255, req: true, arr: true),
    _B('isGroup', req: true, def: false),
    _S('groupName', 255),
    _S('groupAvatar', 500),
    _S('adminIds', 255, arr: true),
    _S('lastMessage', 1000),
    _S('lastMessageType', 24),
    _S('lastMessageSenderId', 255),
    _S('lastMessageTime', 40),
    _S('unreadCounts', 2000),
    _S('createdAt', 40),
    _S('updatedAt', 40),
  ], idxs: [
    _Idx('last_message_time_idx', 'key', ['lastMessageTime'], ['desc']),
    _Idx('updated_idx', 'key', ['updatedAt'], ['desc']),
  ]);

  // docSecurity:true — message documents should only be readable by participants.
  await _col('messages', 'Messages', perms: _userOnly, docSecurity: true, attrs: [
    _S('chatId', 255, req: true),
    _S('senderId', 255, req: true),
    _S('senderName', 255),
    _S('senderAvatar', 500),
    _S('clientNonce', 128),
    _S('content', 4000),
    _S('type', 24, req: true, def: 'text'),
    _S('status', 24, req: true, def: 'sent'),
    _B('isRead', req: true, def: false),
    _S('createdAt', 40),
  ], idxs: [
    _Idx('chat_idx', 'key', ['chatId'], ['asc']),
    _Idx('chat_created_idx', 'key', ['chatId', 'createdAt'], ['asc', 'desc']),
    _Idx('sender_idx', 'key', ['senderId'], ['asc']),
    _Idx('sender_created_idx', 'key', ['senderId', 'createdAt'], ['asc', 'desc']),
    _Idx('nonce_lookup_idx', 'key', ['chatId', 'senderId', 'clientNonce'], ['asc', 'asc', 'asc']),
    _Idx('status_idx', 'key', ['status'], ['asc']),
  ]);

  await _col('typing_status', 'Typing Status', perms: _userOnly, attrs: [
    _S('chatId', 255, req: true),
    _S('userId', 255, req: true),
    _B('isTyping', req: true, def: false),
    _S('updatedAt', 40),
  ], idxs: [
    _Idx('unique_typing', 'unique', ['chatId', 'userId'], ['asc', 'asc']),
    _Idx('chat_idx', 'key', ['chatId'], ['asc']),
  ]);

  await _col('debate_views', 'Debate Views', perms: _userOnly, attrs: [
    _S('debateId', 255, req: true),
    _S('viewerId', 255, req: true),
    _S('viewerName', 255),
    _S('viewerAvatar', 500),
    _S('createdAt', 40),
  ], idxs: [
    _Idx('unique_view', 'unique', ['debateId', 'viewerId'], ['asc', 'asc']),
    _Idx('debate_idx', 'key', ['debateId'], ['asc']),
    _Idx('viewer_idx', 'key', ['viewerId'], ['asc']),
  ]);

  await _col('profile_views', 'Profile Views', perms: _userOnly, attrs: [
    _S('profileId', 255, req: true),
    _S('viewerId', 255, req: true),
    _S('viewerName', 255),
    _S('viewerAvatar', 500),
    _S('createdAt', 40),
  ], idxs: [
    _Idx('profile_idx', 'key', ['profileId'], ['asc']),
    _Idx('viewer_idx', 'key', ['viewerId'], ['asc']),
  ]);

  // docSecurity:true — notification documents are scoped per recipient.
  await _col('notifications', 'Notifications', perms: _userOnly, docSecurity: true, attrs: [
    _S('userId', 255, req: true),
    _S('senderId', 255),
    _S('type', 100, req: true),
    _S('title', 150),
    _S('body', 500),
    _S('payload', 4000),
    _B('read', req: true, def: false),
    _S('createdAt', 40),
  ], idxs: [
    _Idx('user_idx', 'key', ['userId'], ['asc']),
    _Idx('read_idx', 'key', ['read'], ['asc']),
    _Idx('created_idx', 'key', ['createdAt'], ['desc']),
  ]);

  // NOTE: collection ID is 'rooms' to match AppwriteConstants.rooms used at runtime.
  await _col('rooms', 'Rooms', perms: _anyRead, attrs: [
    _S('name', 255, req: true),
    _S('description', 4000),
    _S('creatorId', 255, req: true),
    _S('avatar', 500),
    _S('banner', 500),
    _I('memberCount', req: true, def: 0, min: 0, max: 9999999),
    _I('debateCount', req: true, def: 0, min: 0, max: 9999999),
    _S('category', 100),
    _B('isPrivate', req: true, def: false),
    _S('rules', 4000),
    _S('pinnedDebateIds', 4000),
    _S('createdAt', 40),
    _S('updatedAt', 40),
  ], idxs: [
    _Idx('name_ft', 'fulltext', ['name'], ['asc']),
    _Idx('member_count_idx', 'key', ['memberCount'], ['desc']),
    _Idx('creator_idx', 'key', ['creatorId'], ['asc']),
    _Idx('category_idx', 'key', ['category'], ['asc']),
  ]);

  // NOTE: collection ID is 'room_members' to match AppwriteConstants.roomMembers used at runtime.
  await _col('room_members', 'Room Members', perms: _ownerWrite, attrs: [
    _S('communityId', 255, req: true),
    _S('userId', 255, req: true),
    _S('role', 50, req: true, def: 'member'),
    _S('status', 20, req: true, def: 'active'),
    _S('joinedAt', 40),
  ], idxs: [
    _Idx('unique_member', 'unique', ['communityId', 'userId'], ['asc', 'asc']),
    _Idx('community_idx', 'key', ['communityId'], ['asc']),
    _Idx('user_idx', 'key', ['userId'], ['asc']),
  ]);

  await _col('reports', 'Reports', perms: _userOnly, attrs: [
    _S('reporterId', 255, req: true),
    _S('targetId', 255, req: true),
    _S('targetType', 50, req: true),
    _S('reason', 255, req: true),
    _S('description', 2000),
    _S('status', 50, req: true, def: 'pending'),
    _S('createdAt', 40),
  ], idxs: [
    _Idx('reporter_idx', 'key', ['reporterId'], ['asc']),
    _Idx('target_idx', 'key', ['targetId'], ['asc']),
    _Idx('status_idx', 'key', ['status'], ['asc']),
  ]);

  await _col('badges', 'Badges', perms: _anyRead, attrs: [
    _S('userId', 255, req: true),
    _S('badgeType', 255, req: true),
    _S('awardedAt', 40, req: true),
    _S('createdAt', 40),
  ], idxs: [
    _Idx('unique_user_badge', 'unique', ['userId', 'badgeType'], ['asc', 'asc']),
    _Idx('user_idx', 'key', ['userId'], ['asc']),
    _Idx('badge_type_idx', 'key', ['badgeType'], ['asc']),
  ]);

  await _col('categories', 'Categories', perms: _anyRead, attrs: [
    _S('name', 255, req: true),
    _S('emoji', 20, req: true),
    _S('color', 20, req: true),
    _I('debateCount', req: true, def: 0, min: 0, max: 99999999),
  ], idxs: [
    _Idx('name_unique', 'unique', ['name'], ['asc']),
  ]);

  await _col('ai_summaries', 'AI Summaries', perms: _anyRead, attrs: [
    _S('debateId', 255, req: true),
    _S('content', 4000, req: true),
    _S('winningSide', 20),
    _S('generatedAt', 40, req: true),
    _S('createdAt', 40),
  ], idxs: [
    _Idx('debate_summary_unique', 'unique', ['debateId'], ['asc']),
  ]);

  await _col('leaderboard', 'Leaderboard', perms: _anyRead, attrs: [
    _S('userId', 255, req: true),
    _S('displayName', 255, req: true),
    _S('avatar', 500),
    _I('xp', req: true, def: 0, min: 0, max: 99999999),
    _I('weeklyXp', req: true, def: 0, min: 0, max: 99999999),
    _I('rank', req: true, def: 0, min: 0, max: 9999999),
    _I('weeklyRank', req: true, def: 0, min: 0, max: 9999999),
    _D('winRate', def: 0.0, min: 0.0, max: 100.0),
    _S('week', 16),
    _S('createdAt', 40),
    _S('updatedAt', 40),
  ], idxs: [
    _Idx('leaderboard_user_unique', 'unique', ['userId'], ['asc']),
    _Idx('xp_idx', 'key', ['xp'], ['desc']),
    _Idx('weekly_xp_idx', 'key', ['weeklyXp'], ['desc']),
  ]);

  await _col('trending', 'Trending', perms: _anyRead, attrs: [
    _S('debateId', 255, req: true),
    _S('title', 300),
    _S('category', 100),
    _D('score', def: 0.0, min: 0.0),
    _S('createdAt', 40),
  ], idxs: [
    _Idx('trending_debate_unique', 'unique', ['debateId'], ['asc']),
    _Idx('trending_score_idx', 'key', ['score'], ['desc']),
  ]);

  await _col('hashtags', 'Hashtags', perms: _anyRead, attrs: [
    _S('tag', 100, req: true),
    _I('debateCount', req: true, def: 0, min: 0, max: 99999999),
    _I('weeklyCount', req: true, def: 0, min: 0, max: 99999999),
    _S('updatedAt', 40),
  ], idxs: [
    _Idx('tag_unique', 'unique', ['tag'], ['asc']),
    _Idx('tag_ft', 'fulltext', ['tag'], ['asc']),
    _Idx('weekly_count_idx', 'key', ['weeklyCount'], ['desc']),
    _Idx('debate_count_idx', 'key', ['debateCount'], ['desc']),
  ]);
}

Future<void> _createBuckets() async {
  _section('BUCKETS (5 total)');

  await _bucket(
    'avatars',
    'Avatars',
    maxSize: 2 * 1024 * 1024,
    exts: ['jpg', 'jpeg', 'png', 'webp'],
    perms: _anyRead,
  );
  await _bucket(
    'cover-images',
    'Cover Images',
    maxSize: 5 * 1024 * 1024,
    exts: ['jpg', 'jpeg', 'png', 'webp'],
    perms: _anyRead,
  );
  await _bucket(
    'debate-images',
    'Debate Images',
    maxSize: 5 * 1024 * 1024,
    exts: ['jpg', 'jpeg', 'png', 'webp'],
    perms: _anyRead,
  );
  await _bucket(
    'chat-media',
    'Chat Media',
    maxSize: 50 * 1024 * 1024,
    exts: ['jpg', 'jpeg', 'png', 'webp', 'mp4', 'mov', 'm4a', 'aac', 'mp3'],
    perms: _userOnly,
  );
  await _bucket(
    'media',
    'Media',
    maxSize: 50 * 1024 * 1024,
    exts: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'mp4', 'mov'],
    perms: _anyRead,
  );
}

Future<void> _seedCategories() async {
  _section('SEEDING CATEGORIES');
  await Future.delayed(const Duration(seconds: 5));

  final categories = [
    {'id': 'politics', 'name': 'Politics', 'emoji': '🏛️', 'color': '#E24B4A'},
    {'id': 'technology', 'name': 'Technology', 'emoji': '💻', 'color': '#534AB7'},
    {'id': 'sports', 'name': 'Sports', 'emoji': '⚽', 'color': '#2D6BE4'},
    {'id': 'science', 'name': 'Science', 'emoji': '🔬', 'color': '#1D9E75'},
    {'id': 'entertainment', 'name': 'Entertainment', 'emoji': '🎬', 'color': '#D85A30'},
    {'id': 'philosophy', 'name': 'Philosophy', 'emoji': '🧠', 'color': '#6366F1'},
    {'id': 'health', 'name': 'Health', 'emoji': '💊', 'color': '#EF4444'},
    {'id': 'education', 'name': 'Education', 'emoji': '📚', 'color': '#84CC16'},
    {'id': 'business', 'name': 'Business', 'emoji': '💼', 'color': '#F97316'},
    {'id': 'culture', 'name': 'Culture', 'emoji': '🎭', 'color': '#EC4899'},
  ];

  for (final category in categories) {
    try {
      await _db.getDocument(
        databaseId: _databaseId,
        collectionId: 'categories',
        documentId: category['id']!,
      );
      _skip('Category: ${category['name']}');
    } on AppwriteException catch (e) {
      if (e.code == 404) {
        try {
          await _db.createDocument(
            databaseId: _databaseId,
            collectionId: 'categories',
            documentId: category['id']!,
            data: {
              'name': category['name'],
              'emoji': category['emoji'],
              'color': category['color'],
              'debateCount': 0,
            },
            permissions: [Permission.read(Role.any())],
          );
          _ok('Category: ${category['name']}');
        } catch (e2) {
          _err('Category: ${category['name']}', e2);
        }
      } else {
        _err('Category: ${category['name']}', e);
      }
    }
  }
}

Future<void> _col(
  String id,
  String name, {
  required List<String> perms,
  required List<_A> attrs,
  required List<_Idx> idxs,
  // Enable per-document security so individual users can only access
  // their own documents. Required for chats, messages, notifications.
  bool docSecurity = false,
}) async {
  var collectionExists = false;
  try {
    await _db.getCollection(databaseId: _databaseId, collectionId: id);
    _skip('Collection: $name');
    collectionExists = true;
  } on AppwriteException catch (e) {
    if (e.code != 404) {
      _err('Collection: $name', e);
      return;
    }
  }

  if (!collectionExists) {
    try {
      await _db.createCollection(
        databaseId: _databaseId,
        collectionId: id,
        name: name,
        permissions: perms,
        documentSecurity: docSecurity,
        enabled: true,
      );
      _ok('Collection: $name');
    } catch (e) {
      _err('Collection: $name', e);
      return;
    }

    await Future.delayed(const Duration(milliseconds: 500));
  }

  for (final attribute in attrs) {
    try {
      if (attribute.type == 'string') {
        await _db.createStringAttribute(
          databaseId: _databaseId,
          collectionId: id,
          key: attribute.key,
          size: attribute.size!,
          xrequired: attribute.req,
          xdefault: attribute.req ? null : attribute.defStr,
          array: attribute.array,
        );
      } else if (attribute.type == 'integer') {
        await _db.createIntegerAttribute(
          databaseId: _databaseId,
          collectionId: id,
          key: attribute.key,
          xrequired: attribute.req,
          xdefault: attribute.req ? null : attribute.defInt,
          min: attribute.min,
          max: attribute.max,
        );
      } else if (attribute.type == 'double') {
        await _db.createFloatAttribute(
          databaseId: _databaseId,
          collectionId: id,
          key: attribute.key,
          xrequired: attribute.req,
          xdefault: attribute.req ? null : attribute.defDbl,
          min: attribute.minDbl,
          max: attribute.maxDbl,
        );
      } else if (attribute.type == 'boolean') {
        await _db.createBooleanAttribute(
          databaseId: _databaseId,
          collectionId: id,
          key: attribute.key,
          xrequired: attribute.req,
          xdefault: attribute.req ? null : attribute.defBool,
        );
      }
      _ok('  attr $id.${attribute.key}');
    } on AppwriteException catch (e) {
      final msg = e.message?.toLowerCase() ?? '';
      if (e.code == 409) {
        _skip('  attr $id.${attribute.key}');
      } else if (msg.contains('attribute_limit_exceeded')) {
        _skip('  attr $id.${attribute.key} (collection attribute limit reached)');
      } else {
        _err('  attr $id.${attribute.key}', e);
      }
    }
  }

  if (idxs.isNotEmpty) {
    await Future.delayed(const Duration(seconds: 8));
  }

  for (final index in idxs) {
    try {
      final type = index.type == 'unique'
          ? IndexType.unique
          : index.type == 'fulltext'
              ? IndexType.fulltext
              : IndexType.key;
      await _createIndexWithRetry(
        collectionId: id,
        index: index,
        type: type,
      );
      _ok('  idx  $id.${index.key}');
    } on AppwriteException catch (e) {
      final msg = e.message?.toLowerCase() ?? '';
      if (e.code == 409) {
        _skip('  idx  $id.${index.key}');
      } else if (msg.contains('array attributes is not currently supported')) {
        _skip('  idx  $id.${index.key} (array attributes cannot be indexed)');
      } else {
        _err('  idx  $id.${index.key}', e);
      }
    }
  }
}

Future<void> _createIndexWithRetry({
  required String collectionId,
  required _Idx index,
  required IndexType type,
}) async {
  const maxAttempts = 3;

  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      await _db.createIndex(
        databaseId: _databaseId,
        collectionId: collectionId,
        key: index.key,
        type: type,
        attributes: index.attrs,
        orders: index.orders
            .map((order) => order == 'desc' ? OrderBy.desc : OrderBy.asc)
            .toList(),
      );
      return;
    } on AppwriteException catch (e) {
      final msg = e.message?.toLowerCase() ?? '';
      final isTransient = msg.contains('semaphore timeout period has expired') ||
          msg.contains('timed out') ||
          msg.contains('timeout');

      if (!isTransient || attempt == maxAttempts) {
        rethrow;
      }

      await Future.delayed(Duration(seconds: attempt * 2));
    }
  }
}

Future<void> _bucket(
  String id,
  String name, {
  required int maxSize,
  required List<String> exts,
  required List<String> perms,
}) async {
  try {
    await _storage.getBucket(bucketId: id);
    _skip('Bucket: $name');
  } on AppwriteException catch (e) {
    if (e.code == 404) {
      try {
        // fileSecurity:true so each uploaded file is owned by its uploader
        // and cannot be modified or deleted by other authenticated users.
        await _storage.createBucket(
          bucketId: id,
          name: name,
          permissions: perms,
          fileSecurity: true,
          enabled: true,
          maximumFileSize: maxSize,
          allowedFileExtensions: exts,
        );
        _ok('Bucket: $name');
      } catch (e2) {
        _err('Bucket: $name', e2);
      }
    } else {
      _err('Bucket: $name', e);
    }
  }
}

// Public-readable collections (e.g. debates, communities).
// Any user can read. Creating requires auth. Updates/deletes
// are intentionally NOT granted at collection level — enforce
// via document-level permissions or server functions only.
final _anyRead = [
  Permission.read(Role.any()),
  Permission.create(Role.users()),
];

// Authenticated-read-only collections (e.g. notifications, messages).
// Any authenticated user can read/create. No collection-level
// update/delete — must be enforced per-document or server-side.
final _userOnly = [
  Permission.read(Role.users()),
  Permission.create(Role.users()),
];

// Per-owner collections (votes, likes, saves, connections).
// Collection-level create only; all mutations go through functions
// or document-level security.
final _ownerWrite = [
  Permission.read(Role.users()),
  Permission.create(Role.users()),
];

void _ok(String message) {
  print('OK  $message');
  _created++;
}

void _skip(String message) {
  print('SKIP  $message');
  _skipped++;
}

void _err(String message, Object error) {
  print('ERR  $message\n  -> $error');
  _errors++;
}

void _section(String title) {
  print('\n-- $title ------------------------------');
}

void _banner(String title) {
  print('========================================');
  print('  $title');
  print('========================================\n');
}

void _summary() {
  print('\n========================================');
  print('  VERSZ SCHEMA v3 COMPLETE');
  print('========================================');
  print('  created: $_created');
  print('  skipped: $_skipped');
  print('  errors : $_errors');
  print('========================================\n');
  _printDeploymentNotes();
}

void _printDeploymentNotes() {
  print('''
Deployment notes:

1. This script now provisions the live camelCase v3 schema used by Flutter and the Appwrite functions.
2. Run without --wipe to do a safe additive-only provisioning on an existing database.
   Use --wipe ONLY on a fresh/staging environment — it deletes ALL collections and buckets first.
3. Schema is authoritative: collection IDs 'rooms' and 'room_members' are used (previously
   'communities'/'community_members') — matching AppwriteConstants in the Flutter app.
4. Authorization model: collection-level update/delete permissions are REMOVED.
   All mutations that cross document ownership boundaries must use Appwrite Functions
   with a server-side API key (APPWRITE_API_KEY) — never a client session.
   Enable documentSecurity:true on chats, messages, and notifications after launch.
5. Required functions to deploy:
   - send-notification
   - gemini-summary
   - update-trending
   - update-leaderboard
   - check-achievements
  - update-xp
  - calculate-winner
  - anti-spam-check
  - cast-vote
6. Recommended function schedules/triggers:
  - update-trending: cron every 5 minutes (*/5 * * * *)
  - update-leaderboard: cron every 1 minute (* * * * *)
  - calculate-winner: call on debate close; optional daily cron for stale active debates
  - anti-spam-check, update-xp, cast-vote, check-achievements: event-driven via createExecution from app/function flows
6. Required function environment variables:
   - GEMINI_API_KEY
   - APPWRITE_API_KEY
   - APPWRITE_PROJECT_ID
   - APPWRITE_ENDPOINT
   - DATABASE_ID
   - FIREBASE_SERVICE_JSON
7. Function source entrypoint for all listed functions is src/index.js.
8. Rotate any leaked or previously committed Appwrite API keys before production deployment.
''');
}

class _A {
  final String key;
  final String type;
  final int? size;
  final bool req;
  final bool array;
  final String? defStr;
  final int? defInt;
  final int? min;
  final int? max;
  final double? defDbl;
  final double? minDbl;
  final double? maxDbl;
  final bool? defBool;

  const _A({
    required this.key,
    required this.type,
    this.size,
    this.req = false,
    this.array = false,
    this.defStr,
    this.defInt,
    this.min,
    this.max,
    this.defDbl,
    this.minDbl,
    this.maxDbl,
    this.defBool,
  });
}

_A _S(String key, int size, {bool req = false, String? def, bool arr = false}) =>
    _A(key: key, type: 'string', size: size, req: req, defStr: def, array: arr);

_A _I(String key, {bool req = false, int? def, int? min, int? max}) =>
    _A(key: key, type: 'integer', req: req, defInt: def, min: min, max: max);

_A _D(String key, {bool req = false, double? def, double? min, double? max}) =>
    _A(key: key, type: 'double', req: req, defDbl: def, minDbl: min, maxDbl: max);

_A _B(String key, {bool req = false, bool? def}) =>
    _A(key: key, type: 'boolean', req: req, defBool: def);

class _Idx {
  final String key;
  final String type;
  final List<String> attrs;
  final List<String> orders;

  const _Idx(this.key, this.type, this.attrs, this.orders);
}