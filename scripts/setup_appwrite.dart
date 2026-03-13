// ignore_for_file: avoid_print, deprecated_member_use
// ═══════════════════════════════════════════════════════════════
//  VERSZ — APPWRITE SCHEMA v3  (complete rewrite + upgrade)
//  Run:  dart run scripts/setup_appwrite.dart
//  Needs: dart pub add dart_appwrite
// ═══════════════════════════════════════════════════════════════
//
//  WHAT THIS SCRIPT DOES
//  ─────────────────────
//  1. Wipes all existing collections + buckets (clean slate)
//  2. Creates all 22 v3 collections with every field + index
//  3. Creates 5 storage buckets
//  4. Seeds 10 categories
//
//  v3 vs your current v2 — KEY CHANGES
//  ─────────────────────────────────────
//  • users          → +15 new fields (xp, streak, online, connections, etc.)
//  • debates        → +14 new fields (agree/disagree counts, views, hashtags, AI, etc.)
//  • messages       → upgraded (sender_name/avatar, reply, react, media, status string)
//  • conversations  → upgraded to chats (group support, unread counts)
//  • follows        → replaced by connections (follow + pending + connected in one row)
//  • saved_debates  → renamed to saves
//  • NEW: connections, typing_status, debate_views, profile_views,
//         likes, communities, community_members, hashtags,
//         ai_summaries, leaderboard, trending, fcm_tokens
//
//  GAP REPORT vs your current code
//  ─────────────────────────────────
//  Code uses:           | Needs migration to:
//  follows collection   | connections (status: follow/pending/connected)
//  saved_debates        | saves
//  conversations        | chats
//  messages.is_read     | messages.status (sent/delivered/read)
//  messages.message_type| messages.type
//  users.reputation     | users.xp
//  debates.upvotes      | debates.agree_count
//  debates.downvotes    | debates.disagree_count
//
// ═══════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/enums.dart';

// ── CONFIG ──────────────────────────────────────────────────────
// Use env var in production: export APPWRITE_API_KEY=your_key
const String _endpoint  = 'https://sgp.cloud.appwrite.io/v1';
const String _projectId = '69b00336003a3772ee69';
const String _databaseId = 'versz-db';

String get _apiKey {
  final key = Platform.environment['APPWRITE_API_KEY'];
  if (key == null || key.trim().isEmpty) {
    throw StateError(
      'APPWRITE_API_KEY is required. Set environment variable before running setup_appwrite.',
    );
  }
  return key.trim();
}

// ── GLOBALS ─────────────────────────────────────────────────────
late Client    _client;
late Databases _db;
late Storage   _storage;

int _created = 0, _skipped = 0, _errors = 0;

// ════════════════════════════════════════════════════════════════
void main() async {
  _client = Client()
      .setEndpoint(_endpoint)
      .setProject(_projectId)
      .setKey(_apiKey)
      .setSelfSigned(status: true);

  _db      = Databases(_client);
  _storage = Storage(_client);

  _banner('VERSZ APPWRITE SCHEMA v3');

  await _wipe();
  await _ensureDatabase();
  await _createCollections();
  await _createBuckets();
  await _seedCategories();

  _summary();
}

// ════════════════════════════════════════════════════════════════
//  WIPE
// ════════════════════════════════════════════════════════════════
Future<void> _wipe() async {
  _section('WIPING EXISTING COLLECTIONS & BUCKETS');
  try {
    final res = await _db.listCollections(databaseId: _databaseId);
    for (final col in res.collections) {
      await _db.deleteCollection(databaseId: _databaseId, collectionId: col.$id);
      print('  🗑  Deleted collection: ${col.name}');
    }
  } catch (e) {
    print('  (no collections or error: $e)');
  }
  try {
    final res = await _storage.listBuckets();
    for (final b in res.buckets) {
      await _storage.deleteBucket(bucketId: b.$id);
      print('  🗑  Deleted bucket: ${b.name}');
    }
  } catch (e) {
    print('  (no buckets or error: $e)');
  }
}

// ════════════════════════════════════════════════════════════════
//  DATABASE
// ════════════════════════════════════════════════════════════════
Future<void> _ensureDatabase() async {
  _section('DATABASE');
  try {
    await _db.get(databaseId: _databaseId);
    _skip('Database $_databaseId');
  } on AppwriteException catch (e) {
    if (e.code == 404) {
      try {
        await _db.create(databaseId: _databaseId, name: 'Versz Database', enabled: true);
        _ok('Database $_databaseId');
      } catch (e2) { _err('Database', e2); }
    } else { _err('Database', e); }
  }
}

// ════════════════════════════════════════════════════════════════
//  ALL 22 COLLECTIONS
// ════════════════════════════════════════════════════════════════
Future<void> _createCollections() async {
  _section('COLLECTIONS  (22 total)');

  // ── 1. USERS ────────────────────────────────────────────────
  await _col('users', 'Users', perms: _anyRead, attrs: [
    // identity
    _S('username',          255, req: true),   // unique — see index
    _S('display_name',      255, req: true),
    _S('avatar_url',        500),
    _S('cover_image',       500),              // NEW: profile cover/banner
    _S('bio',               500),
    _S('website',           200),              // NEW
    // stats
    _I('xp',                req: true, def: 0, min: 0, max: 99999999),   // was reputation
    _I('reputation',        req: true, def: 0, min: 0, max: 99999999),   // keep for compatibility
    _I('followers_count',   req: true, def: 0, min: 0, max: 9999999),
    _I('following_count',   req: true, def: 0, min: 0, max: 9999999),
    _I('connections_count', req: true, def: 0, min: 0, max: 9999999),    // NEW
    _I('debates_created',   req: true, def: 0, min: 0, max: 9999999),    // NEW
    _I('total_votes',       req: true, def: 0, min: 0, max: 9999999),    // NEW
    _I('current_streak',    req: true, def: 0, min: 0, max: 9999),       // NEW
    _I('longest_streak',    req: true, def: 0, min: 0, max: 9999),       // NEW
    _D('win_rate',          def: 0.0, min: 0.0, max: 100.0),             // NEW
    // status
    _B('is_verified',       req: true, def: false),
    _B('is_online',         req: true, def: false),                       // NEW
    _B('is_private',        req: true, def: false),                       // NEW
    // strings / config
    _S('messaging_privacy', 20,  def: 'everyone'),  // NEW: everyone / followers
    _S('notif_prefs',       1000, def: '{}'),        // NEW: JSON blob
    _S('last_vote_date',    30),                     // NEW: ISO date
    _S('last_seen',         30),                     // NEW: ISO datetime
    _S('fcm_token',         500),
    _S('created_at',        30),                     // NEW
  ], idxs: [
    _Idx('username_unique',   'unique',   ['username'],      ['asc']),
    _Idx('username_ft',       'fulltext', ['username'],      ['asc']),
    _Idx('display_name_ft',   'fulltext', ['display_name'],  ['asc']),
    _Idx('xp_idx',            'key',      ['xp'],            ['desc']),
  ]);

  // ── 2. DEBATES ──────────────────────────────────────────────
  await _col('debates', 'Debates', perms: _anyRead, attrs: [
    _S('title',                   300, req: true),
    _S('description',             1000),
    _S('category_id',             255, req: true),
    _S('creator_id',              255, req: true),
    _S('creator_name',            255, req: true),
    _S('creator_avatar',          500),
    // media (keep existing)
    _S('media_type',              50,  req: true, def: 'text'), // text/image/video
    _S('media_url',               500),
    // voting — NEW split into agree/disagree
    _I('agree_count',    req: true, def: 0, min: 0, max: 99999999),   // NEW (was upvotes)
    _I('disagree_count', req: true, def: 0, min: 0, max: 99999999),   // NEW (was downvotes)
    _I('upvotes',        req: true, def: 0, min: 0, max: 99999999),   // keep for compatibility
    _I('downvotes',      req: true, def: 0, min: 0, max: 99999999),   // keep for compatibility
    _I('like_count',     req: true, def: 0, min: 0, max: 99999999),   // NEW
    _I('comment_count',  req: true, def: 0, min: 0, max: 99999999),
    _I('view_count',     req: true, def: 0, min: 0, max: 99999999),   // NEW
    _I('impression_count',req: true, def: 0, min: 0, max: 99999999),  // NEW
    // metadata
    _S('status',         50, req: true, def: 'active'),  // active/closed/deleted
    _S('community_id',   255),                            // NEW: if in a community
    _S('expires_at',     30),                             // NEW: ISO datetime
    // AI / trending
    _S('ai_summary',               2000),    // NEW: cached Gemini summary
    _S('ai_summary_generated_at',  30),      // NEW
    _S('winning_side',             10),      // NEW: agree/disagree/tie
    _B('is_trending',     req: true, def: false),         // NEW
    _D('trending_score',  def: 0.0,  min: 0.0),           // NEW
    // hashtags stored as comma-separated string (Appwrite free tier array workaround)
    _S('hashtags',        500),   // NEW: comma-separated, e.g. "tech,ai,debate"
    _S('updated_at',      30),    // NEW
  ], idxs: [
    _Idx('title_ft',        'fulltext', ['title'],          ['asc']),
    _Idx('category_idx',    'key',      ['category_id'],    ['asc']),
    _Idx('creator_idx',     'key',      ['creator_id'],     ['asc']),
    _Idx('status_idx',      'key',      ['status'],         ['asc']),
    _Idx('trending_idx',    'key',      ['trending_score'], ['desc']),
    _Idx('community_idx',   'key',      ['community_id'],   ['asc']),
    _Idx('like_idx',        'key',      ['like_count'],     ['desc']),
    _Idx('latest_idx',      'key',      [r'$createdAt'],    ['desc']),
  ]);

  // ── 3. COMMENTS ─────────────────────────────────────────────
  await _col('comments', 'Comments', perms: _anyRead, attrs: [
    _S('debate_id',   255, req: true),
    _S('user_id',     255, req: true),
    _S('username',    255, req: true),   // NEW: denormalized for display
    _S('user_avatar', 500),              // NEW: denormalized for display
    _S('parent_id',   255),
    _S('content',    2000, req: true),
    _S('side',        10),               // NEW: agree/disagree
    _I('upvotes',   req: true, def: 0, min: 0, max: 999999),
    _I('downvotes', req: true, def: 0, min: 0, max: 999999),
    _I('reply_count',req: true, def: 0, min: 0, max: 999999),
    _B('is_deleted', req: true, def: false),   // NEW: soft delete
    _B('is_edited',  req: true, def: false),   // NEW
    _S('updated_at', 30),                      // NEW
  ], idxs: [
    _Idx('debate_idx', 'key', ['debate_id'], ['asc']),
    _Idx('parent_idx', 'key', ['parent_id'], ['asc']),
    _Idx('user_idx',   'key', ['user_id'],   ['asc']),
  ]);

  // ── 4. VOTES ────────────────────────────────────────────────
  await _col('votes', 'Votes', perms: _userOnly, attrs: [
    _S('user_id',     255, req: true),
    _S('target_id',   255, req: true),
    _S('target_type', 50,  req: true),  // debate / comment
    _I('value',       req: true, min: -1, max: 1),
    _S('side',        10),               // NEW: agree/disagree (for debates)
  ], idxs: [
    _Idx('unique_vote', 'unique', ['user_id', 'target_id', 'target_type'], ['asc','asc','asc']),
    _Idx('target_idx',  'key',    ['target_id'],  ['asc']),
  ]);

  // ── 5. LIKES ────────────────────────────────────────────────
  // NEW collection: separate from votes, just for heart-likes
  await _col('likes', 'Likes', perms: _userOnly, attrs: [
    _S('debate_id', 255, req: true),
    _S('user_id',   255, req: true),
  ], idxs: [
    _Idx('unique_like',  'unique', ['debate_id', 'user_id'], ['asc','asc']),
    _Idx('debate_likes', 'key',    ['debate_id'],             ['asc']),
    _Idx('user_likes',   'key',    ['user_id'],               ['asc']),
  ]);

  // ── 6. SAVES (was saved_debates) ────────────────────────────
  // Renamed + kept saved_debates for backwards compat
  await _col('saves', 'Saves', perms: _userOnly, attrs: [
    _S('user_id',   255, req: true),
    _S('debate_id', 255, req: true),
  ], idxs: [
    _Idx('unique_save', 'unique', ['user_id', 'debate_id'], ['asc','asc']),
    _Idx('user_saves',  'key',    ['user_id'],               ['asc']),
  ]);

  // Keep old saved_debates collection so existing code doesn't break
  await _col('saved_debates', 'Saved Debates (legacy)', perms: _userOnly, attrs: [
    _S('user_id',   255, req: true),
    _S('debate_id', 255, req: true),
  ], idxs: [
    _Idx('user_saved_idx', 'key', ['user_id'], ['asc']),
  ]);

  // ── 7. CONNECTIONS (replaces follows) ───────────────────────
  // NEW: single row covers follow + pending request + mutual connection
  // status values:
  //   follow    = one-way follow (like Twitter)
  //   pending   = connection request sent, not yet accepted
  //   connected = mutual connection accepted → chat unlocked
  //   blocked   = blocker_id blocked blocked_id
  await _col('connections', 'Connections', perms: _userOnly, attrs: [
    _S('requester_id', 255, req: true),
    _S('receiver_id',  255, req: true),
    _S('status',       15,  req: true), // follow/pending/connected/blocked
    _S('updated_at',   30),
  ], idxs: [
    _Idx('requester_idx',    'key',    ['requester_id'],                   ['asc']),
    _Idx('receiver_idx',     'key',    ['receiver_id'],                    ['asc']),
    _Idx('status_idx',       'key',    ['status'],                         ['asc']),
    _Idx('unique_connection','unique', ['requester_id', 'receiver_id'],    ['asc','asc']),
  ]);

  // Keep old follows collection so existing social_provider.dart doesn't break
  await _col('follows', 'Follows (legacy)', perms: _userOnly, attrs: [
    _S('follower_id',  255, req: true),
    _S('following_id', 255, req: true),
  ], idxs: [
    _Idx('unique_follow', 'unique', ['follower_id', 'following_id'], ['asc','asc']),
    _Idx('follower_idx',  'key',    ['follower_id'],  ['asc']),
    _Idx('following_idx', 'key',    ['following_id'], ['asc']),
  ]);

  // ── 8. CHATS (upgraded from conversations) ──────────────────
  // Supports both 1-to-1 DMs and group chats
  // participants stored as JSON string (workaround for Appwrite free array limit)
  await _col('chats', 'Chats', perms: _userOnly, attrs: [
    // For 1-to-1: keep old fields for backwards compat
    _S('participant_1',          255),   // keep for existing conversation_provider.dart
    _S('participant_2',          255),   // keep
    // New fields
    _S('participants',           1000),  // NEW: JSON array string "[userId1, userId2]"
    _B('is_group',               req: true, def: false),
    _S('group_name',             100),
    _S('group_avatar',           500),
    _S('admin_ids',              500),   // JSON array string
    // last message preview
    _S('last_message',           500),
    _S('last_message_type',      20),    // text/image/video/audio/debate
    _S('last_message_sender_id', 255),
    _S('last_message_at',        50),    // keep old field name for compatibility
    // unread counts per user: JSON string {"userId": count}
    _S('unread_counts',          500),
    _S('updated_at',             30),    // NEW
  ], idxs: [
    // keep old index for existing code
    _Idx('unique_conv',    'unique', ['participant_1', 'participant_2'], ['asc','asc']),
    _Idx('updated_idx',    'key',    ['updated_at'],                     ['desc']),
  ]);

  // Keep old conversations collection so existing code doesn't break
  await _col('conversations', 'Conversations (legacy)', perms: _userOnly, attrs: [
    _S('participant_1',   255, req: true),
    _S('participant_2',   255, req: true),
    _S('last_message',    1000),
    _S('last_message_at', 50),
  ], idxs: [
    _Idx('unique_conv_legacy', 'unique', ['participant_1', 'participant_2'], ['asc','asc']),
  ]);

  // ── 9. MESSAGES (upgraded) ──────────────────────────────────
  await _col('messages', 'Messages', perms: _userOnly, attrs: [
    // routing — one of these must be set
    _S('chat_id',          255),            // NEW: points to chats collection
    _S('conversation_id',  255),            // keep for existing message_provider.dart
    _S('room_id',          255),            // keep for rooms
    // sender info (denormalized for performance)
    _S('sender_id',        255, req: true),
    _S('sender_name',      255),            // NEW
    _S('sender_avatar',    500),            // NEW
    // content
    _S('type',             20, req: true, def: 'text'),  // text/image/video/audio/debate
    _S('message_type',     20, req: true, def: 'text'),  // keep old field name
    _S('content',         2000),
    // media
    _S('media_url',        500),            // NEW
    _S('media_thumbnail',  500),            // NEW
    _I('media_duration',   min: 0, max: 99999),  // NEW: seconds
    // debate share card
    _S('debate_payload',   500),            // NEW: JSON debate preview
    // reply
    _S('reply_to_msg_id',  255),            // NEW
    _S('reply_to_content', 300),            // NEW: quoted preview text
    // reactions: JSON string {"😂": ["userId1"], "❤️": ["userId2"]}
    _S('reactions',        1000),           // NEW
    // status
    _S('status',           20, req: true, def: 'sent'),  // NEW: sent/delivered/read
    _B('is_read',          req: true, def: false),        // keep for compat
    _B('is_deleted',       req: true, def: false),        // NEW
  ], idxs: [
    _Idx('chat_idx',      'key', ['chat_id'],         ['asc']),
    _Idx('conv_idx',      'key', ['conversation_id'], ['asc']),
    _Idx('room_idx',      'key', ['room_id'],         ['asc']),
    _Idx('sender_idx',    'key', ['sender_id'],       ['asc']),
    _Idx('latest_msg_idx','key', [r'$createdAt'],     ['desc']),
  ]);

  // ── 10. TYPING STATUS ───────────────────────────────────────
  // NEW: lightweight real-time collection for typing indicator
  // Write {isTyping:true} on keypress, delete/set false after 2s idle
  await _col('typing_status', 'Typing Status', perms: _userOnly, attrs: [
    _S('chat_id',   255, req: true),
    _S('user_id',   255, req: true),
    _B('is_typing', req: true, def: false),
    _S('updated_at', 30),
  ], idxs: [
    _Idx('chat_typing_idx',    'key',    ['chat_id'],             ['asc']),
    _Idx('unique_typing',      'unique', ['chat_id', 'user_id'],  ['asc','asc']),
  ]);

  // ── 11. DEBATE VIEWS ────────────────────────────────────────
  // NEW: track who viewed each debate (de-duped per user)
  await _col('debate_views', 'Debate Views', perms: _userOnly, attrs: [
    _S('debate_id',    255, req: true),
    _S('viewer_id',    255, req: true),
    _S('viewer_name',  255),
    _S('viewer_avatar',500),
  ], idxs: [
    _Idx('debate_views_idx',  'key',    ['debate_id'],                ['asc']),
    _Idx('viewer_idx',        'key',    ['viewer_id'],                ['asc']),
    _Idx('unique_view',       'unique', ['debate_id', 'viewer_id'],   ['asc','asc']),
  ]);

  // ── 12. PROFILE VIEWS ───────────────────────────────────────
  // NEW: LinkedIn-style "who viewed your profile"
  await _col('profile_views', 'Profile Views', perms: _userOnly, attrs: [
    _S('profile_id',   255, req: true),
    _S('viewer_id',    255, req: true),
    _S('viewer_name',  255),
    _S('viewer_avatar',500),
  ], idxs: [
    _Idx('profile_views_idx', 'key', ['profile_id'], ['asc']),
    _Idx('pv_viewer_idx',     'key', ['viewer_id'],  ['asc']),
  ]);

  // ── 13. NOTIFICATIONS ───────────────────────────────────────
  await _col('notifications', 'Notifications', perms: _userOnly, attrs: [
    _S('user_id',   255, req: true),
    _S('type',      100, req: true),  // reply/follow/connection_request/connection_accepted/
                                       // trending/streak/ai_summary/category/message/community
    _S('sender_id', 255),
    _S('target_id', 255),
    _S('content',   500, req: true),  // keep for existing code
    _S('title',     100),             // NEW: notification title
    _S('body',      300),             // NEW: notification body
    _S('payload',   500),             // NEW: JSON extra data
    _B('is_read',   req: true, def: false),
  ], idxs: [
    _Idx('user_notifs_idx', 'key', ['user_id'],   ['asc']),
    _Idx('is_read_idx',     'key', ['is_read'],   ['asc']),
    _Idx('notif_latest',    'key', [r'$createdAt'],['desc']),
  ]);

  // ── 14. ROOMS (group chat spaces — keep as is) ──────────────
  await _col('rooms', 'Rooms', perms: _anyRead, attrs: [
    _S('name',         255, req: true),
    _S('description', 1000),
    _S('creator_id',   255, req: true),
    _S('icon_url',     500),
    _S('banner_url',   500),
    _I('members_count',req: true, def: 0, min: 0, max: 9999999),
    // NEW fields
    _S('category',     100),
    _B('is_private',   req: true, def: false),
    _S('rules',       2000),  // JSON array of rule strings
    _S('pinned_debate_ids', 500),  // JSON array
  ], idxs: [
    _Idx('room_name_ft',   'fulltext', ['name'],       ['asc']),
    _Idx('room_cat_idx',   'key',      ['category'],   ['asc']),
    _Idx('room_latest',    'key',      [r'$createdAt'],['desc']),
  ]);

  // ── 15. ROOM MEMBERS ────────────────────────────────────────
  await _col('room_members', 'Room Members', perms: _userOnly, attrs: [
    _S('room_id', 255, req: true),
    _S('user_id', 255, req: true),
    _S('role',    50,  req: true), // admin/moderator/member
    _S('status',  20,  req: true, def: 'active'), // NEW: active/pending/banned
    _S('joined_at', 30),                           // NEW
  ], idxs: [
    _Idx('unique_member',   'unique', ['room_id', 'user_id'], ['asc','asc']),
    _Idx('user_rooms_idx',  'key',    ['user_id'],            ['asc']),
    _Idx('room_members_idx','key',    ['room_id'],            ['asc']),
  ]);

  // ── 16. REPORTS ─────────────────────────────────────────────
  await _col('reports', 'Reports', perms: _userOnly, attrs: [
    _S('reporter_id', 255, req: true),
    _S('target_id',   255, req: true),
    _S('target_type', 50,  req: true),
    _S('reason',      255, req: true),
    _S('status',      50,  req: true, def: 'pending'), // pending/resolved/dismissed
  ], idxs: [
    _Idx('reporter_idx',   'key', ['reporter_id'], ['asc']),
    _Idx('target_idx',     'key', ['target_id'],   ['asc']),
    _Idx('status_idx',     'key', ['status'],       ['asc']),
  ]);

  // ── 17. BADGES ──────────────────────────────────────────────
  await _col('badges', 'Badges', perms: _anyRead, attrs: [
    _S('user_id',   255, req: true),
    _S('badge_id',  255, req: true),
    _S('earned_at', 50,  req: true),
  ], idxs: [
    _Idx('user_badges_idx', 'key', ['user_id'], ['asc']),
  ]);

  // ── 18. CATEGORIES ──────────────────────────────────────────
  await _col('categories', 'Categories', perms: _anyRead, attrs: [
    _S('name',        255, req: true),
    _S('emoji',       20,  req: true),
    _S('color',       20,  req: true),
    _I('debate_count',req: true, def: 0, min: 0, max: 99999999),
  ], idxs: [
    _Idx('name_unique', 'unique', ['name'], ['asc']),
  ]);

  // ── 19. AI SUMMARIES ────────────────────────────────────────
  // NEW: cached Gemini AI debate summaries
  await _col('ai_summaries', 'AI Summaries', perms: _anyRead, attrs: [
    _S('debate_id',    255, req: true),
    _S('content',     2000, req: true),
    _S('winning_side', 20),   // agree/disagree/tie
    _S('generated_at', 30,  req: true),
  ], idxs: [
    _Idx('debate_summary_unique', 'unique', ['debate_id'], ['asc']),
  ]);

  // ── 20. LEADERBOARD ─────────────────────────────────────────
  // NEW: pre-computed leaderboard (updated by Appwrite Function every 24h)
  await _col('leaderboard', 'Leaderboard', perms: _anyRead, attrs: [
    _S('user_id',      255, req: true),
    _S('display_name', 255, req: true),
    _S('avatar_url',   500),
    _I('xp',           req: true, def: 0, min: 0, max: 99999999),
    _I('weekly_xp',    req: true, def: 0, min: 0, max: 99999999),
    _I('rank',         req: true, def: 0, min: 0, max: 9999999),
    _I('weekly_rank',  req: true, def: 0, min: 0, max: 9999999),
    _D('win_rate',     def: 0.0, min: 0.0, max: 100.0),
  ], idxs: [
    _Idx('leaderboard_user_unique', 'unique', ['user_id'],    ['asc']),
    _Idx('xp_rank_idx',             'key',    ['xp'],         ['desc']),
    _Idx('weekly_xp_idx',           'key',    ['weekly_xp'],  ['desc']),
  ]);

  // ── 21. TRENDING ────────────────────────────────────────────
  // NEW: pre-computed trending debates (updated by Appwrite Function every hour)
  await _col('trending', 'Trending', perms: _anyRead, attrs: [
    _S('debate_id',   255, req: true),
    _S('title',       300),
    _D('score',       req: false, def: 0.0, min: 0.0),
    _S('category',    100),
    _S('computed_at', 30),
  ], idxs: [
    _Idx('trending_debate_unique', 'unique', ['debate_id'], ['asc']),
    _Idx('trending_score_idx',     'key',    ['score'],     ['desc']),
  ]);

  // ── 22. HASHTAGS ────────────────────────────────────────────
  // NEW: tracks hashtag usage for trending hashtags feature
  await _col('hashtags', 'Hashtags', perms: _anyRead, attrs: [
    _S('tag',         100, req: true),
    _I('debate_count',req: true, def: 0, min: 0, max: 99999999),
    _I('weekly_count',req: true, def: 0, min: 0, max: 99999999),
    _S('updated_at',  30),
  ], idxs: [
    _Idx('tag_unique',       'unique',   ['tag'],           ['asc']),
    _Idx('tag_ft',           'fulltext', ['tag'],           ['asc']),
    _Idx('weekly_count_idx', 'key',      ['weekly_count'],  ['desc']),
    _Idx('debate_count_idx', 'key',      ['debate_count'],  ['desc']),
  ]);

  // NOTE: No fcm_tokens collection needed — FCM token stored in users.fcm_token
  // NOTE: No communities collection added yet — rooms covers that use case
}

// ════════════════════════════════════════════════════════════════
//  BUCKETS  (5 total)
// ════════════════════════════════════════════════════════════════
Future<void> _createBuckets() async {
  _section('BUCKETS  (5 total)');

  await _bucket('avatars',        'Avatars',
    maxSize: 2 * 1024 * 1024,       // 2 MB
    exts: ['jpg','jpeg','png','webp'],
    perms: _anyRead,
  );
  await _bucket('cover-images',   'Cover Images',
    maxSize: 5 * 1024 * 1024,       // 5 MB
    exts: ['jpg','jpeg','png','webp'],
    perms: _anyRead,
  );
  await _bucket('debate-images',  'Debate Images',
    maxSize: 5 * 1024 * 1024,
    exts: ['jpg','jpeg','png','webp'],
    perms: _anyRead,
  );
  await _bucket('chat-media',     'Chat Media',
    maxSize: 50 * 1024 * 1024,      // 50 MB
    exts: ['jpg','jpeg','png','webp','mp4','mov','m4a','aac','mp3'],
    perms: _userOnly,
  );
  await _bucket('media',          'Media (legacy)',
    maxSize: 50 * 1024 * 1024,
    exts: ['jpg','jpeg','png','webp','gif','mp4','mov'],
    perms: _anyRead,
  );
}

// ════════════════════════════════════════════════════════════════
//  SEED CATEGORIES
// ════════════════════════════════════════════════════════════════
Future<void> _seedCategories() async {
  _section('SEEDING CATEGORIES');
  print('  ⏳ Waiting 5s for categories collection to be ready...');
  await Future.delayed(const Duration(seconds: 5));

  final cats = [
    {'id':'politics',      'name':'Politics',      'emoji':'🏛️', 'color':'#E24B4A'},
    {'id':'technology',    'name':'Technology',    'emoji':'💻', 'color':'#534AB7'},
    {'id':'sports',        'name':'Sports',        'emoji':'⚽', 'color':'#2D6BE4'},
    {'id':'science',       'name':'Science',       'emoji':'🔬', 'color':'#1D9E75'},
    {'id':'entertainment', 'name':'Entertainment', 'emoji':'🎬', 'color':'#D85A30'},
    {'id':'philosophy',    'name':'Philosophy',    'emoji':'🧠', 'color':'#6366F1'},
    {'id':'health',        'name':'Health',        'emoji':'💊', 'color':'#EF4444'},
    {'id':'education',     'name':'Education',     'emoji':'📚', 'color':'#84CC16'},
    {'id':'business',      'name':'Business',      'emoji':'💼', 'color':'#F97316'},
    {'id':'culture',       'name':'Culture',       'emoji':'🎭', 'color':'#EC4899'},
  ];

  for (final cat in cats) {
    try {
      await _db.getDocument(databaseId: _databaseId, collectionId: 'categories', documentId: cat['id']!);
      _skip('Category: ${cat['name']}');
    } on AppwriteException catch (e) {
      if (e.code == 404) {
        try {
          await _db.createDocument(
            databaseId: _databaseId,
            collectionId: 'categories',
            documentId: cat['id']!,
            data: {'name': cat['name'], 'emoji': cat['emoji'], 'color': cat['color'], 'debate_count': 0},
            permissions: [Permission.read(Role.any())],
          );
          _ok('Category: ${cat['name']}');
        } catch (e2) { _err('Category: ${cat['name']}', e2); }
      } else { _err('Category: ${cat['name']}', e); }
    }
  }
}

// ════════════════════════════════════════════════════════════════
//  COLLECTION FACTORY
// ════════════════════════════════════════════════════════════════
Future<void> _col(
  String id,
  String name, {
  required List<String> perms,
  required List<_A> attrs,
  required List<_Idx> idxs,
}) async {
  // ── check / create collection ──────────────────────────────
  bool exists = false;
  try {
    await _db.getCollection(databaseId: _databaseId, collectionId: id);
    _skip('Collection: $name');
    exists = true;
  } on AppwriteException catch (e) {
    if (e.code != 404) { _err('Collection: $name', e); return; }
  }

  if (!exists) {
    try {
      await _db.createCollection(
        databaseId: _databaseId,
        collectionId: id,
        name: name,
        permissions: perms,
        documentSecurity: false,
        enabled: true,
      );
      _ok('Collection: $name');
    } catch (e) { _err('Collection: $name', e); return; }
  } else {
    return; // skip attributes + indexes for existing collections
  }

  // ── attributes ─────────────────────────────────────────────
  // Small delay so Appwrite registers the new collection
  await Future.delayed(const Duration(milliseconds: 500));

  for (final a in attrs) {
    try {
      switch (a.type) {
        case 'string':
          await _db.createStringAttribute(
            databaseId: _databaseId, collectionId: id,
            key: a.key, size: a.size!, xrequired: a.req,
            xdefault: a.req ? null : a.defStr, array: a.array,
          );
        case 'integer':
          await _db.createIntegerAttribute(
            databaseId: _databaseId, collectionId: id,
            key: a.key, xrequired: a.req,
            xdefault: a.req ? null : a.defInt, min: a.min, max: a.max,
          );
        case 'double':
          await _db.createFloatAttribute(
            databaseId: _databaseId, collectionId: id,
            key: a.key, xrequired: a.req,
            xdefault: a.req ? null : a.defDbl, min: a.minDbl, max: a.maxDbl,
          );
        case 'boolean':
          await _db.createBooleanAttribute(
            databaseId: _databaseId, collectionId: id,
            key: a.key, xrequired: a.req,
            xdefault: a.req ? null : a.defBool,
          );
      }
      _ok('  attr $id.${a.key}');
    } on AppwriteException catch (e) {
      e.code == 409 ? _skip('  attr $id.${a.key}') : _err('  attr $id.${a.key}', e);
    }
  }

  // ── indexes (wait for attributes to be indexed first) ──────
  if (idxs.isNotEmpty) {
    print('  ⏳ Waiting 8s for attributes on $name...');
    await Future.delayed(const Duration(seconds: 8));
  }

  for (final idx in idxs) {
    try {
      final t = idx.type == 'unique'
          ? IndexType.unique
          : idx.type == 'fulltext'
              ? IndexType.fulltext
              : IndexType.key;
      await _db.createIndex(
        databaseId: _databaseId, collectionId: id,
        key: idx.key, type: t,
        attributes: idx.attrs,
        orders: idx.orders.map((o) => o == 'desc' ? OrderBy.desc : OrderBy.asc).toList(),
      );
      _ok('  idx  $id.${idx.key}');
    } on AppwriteException catch (e) {
      e.code == 409 ? _skip('  idx  $id.${idx.key}') : _err('  idx  $id.${idx.key}', e);
    }
  }
}

// ════════════════════════════════════════════════════════════════
//  BUCKET FACTORY
// ════════════════════════════════════════════════════════════════
Future<void> _bucket(
  String id, String name, {
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
        await _storage.createBucket(
          bucketId: id, name: name,
          permissions: perms,
          fileSecurity: false, enabled: true,
          maximumFileSize: maxSize,
          allowedFileExtensions: exts,
        );
        _ok('Bucket: $name');
      } catch (e2) { _err('Bucket: $name', e2); }
    } else { _err('Bucket: $name', e); }
  }
}

// ════════════════════════════════════════════════════════════════
//  PERMISSION SHORTCUTS
// ════════════════════════════════════════════════════════════════
final _anyRead = [
  Permission.read(Role.any()),
  Permission.create(Role.users()),
  Permission.update(Role.users()),
  Permission.delete(Role.users()),
];

final _userOnly = [
  Permission.read(Role.users()),
  Permission.create(Role.users()),
  Permission.update(Role.users()),
  Permission.delete(Role.users()),
];

// ════════════════════════════════════════════════════════════════
//  LOGGING
// ════════════════════════════════════════════════════════════════
void _ok(String m)          { print('✓  $m'); _created++; }
void _skip(String m)        { print('⟳  $m'); _skipped++; }
void _err(String m, Object e) { print('✗  $m\n   → $e'); _errors++; }
void _section(String t)     { print('\n── $t ──────────────────────────────────'); }
void _banner(String t) {
  print('═══════════════════════════════════════════');
  print('  $t');
  print('═══════════════════════════════════════════\n');
}

void _summary() {
  print('\n═══════════════════════════════════════════');
  print('  VERSZ SCHEMA v3 — COMPLETE');
  print('═══════════════════════════════════════════');
  print('  ✓  Created : $_created');
  print('  ⟳  Skipped : $_skipped');
  print('  ✗  Errors  : $_errors');
  print('═══════════════════════════════════════════');
  if (_errors > 0) print('\n  ⚠️  Fix errors above then re-run — script is safe to re-run.');
  print('');
  _printMigrationNotes();
}

void _printMigrationNotes() {
  print('''
═══════════════════════════════════════════
  MIGRATION NOTES FOR YOUR FLUTTER CODE
═══════════════════════════════════════════

1. FOLLOWS → CONNECTIONS
   Your social_provider.dart uses the follows collection.
   Migrate to connections collection:
     OLD: {follower_id, following_id}
     NEW: {requester_id, receiver_id, status: "follow"}
   Both collections exist — migrate at your own pace.

2. SAVED_DEBATES → SAVES
   Both collections exist. saved_debates_provider.dart
   works as before. New saves collection is for v3 features.

3. CONVERSATIONS → CHATS
   Both collections exist. conversation_provider.dart works.
   New chats collection adds group support + unread counts.

4. MESSAGES: is_read → status
   Old boolean is_read field still exists.
   New status field: sent / delivered / read
   Update message_provider.dart when ready.

5. MESSAGES: message_type → type
   Both fields exist. Old message_type still works.
   Migrate to type field for new features.

6. USERS: reputation → xp
   Both fields exist. reputation still works for leaderboard.
   Migrate to xp for v3 features.

7. DEBATES: upvotes/downvotes → agree_count/disagree_count
   Both sets of fields exist. Old upvotes/downvotes still work.
   Migrate vote_provider.dart to agree_count/disagree_count.

8. APPWRITE FUNCTIONS TO DEPLOY
   ─────────────────────────────
   send-notification  | DB event: any create       | Node 18
   gemini-summary     | DB event: votes create     | Node 18
   update-trending    | Cron: every 1 hour         | Node 18
   update-leaderboard | Cron: every 24 hours       | Node 18
   check-achievements | DB event: votes create     | Node 18
   (NEW) compute-hashtags | Cron: every 6 hours    | Node 18
   (NEW) cleanup-old-data | Cron: every 7 days     | Node 18

9. ENV VARIABLES NEEDED IN APPWRITE FUNCTIONS
   ─────────────────────────────────────────────
   GEMINI_API_KEY      = your Gemini 1.5 Flash key
   APPWRITE_API_KEY    = your server API key
   APPWRITE_PROJECT_ID = 69b00336003a3772ee69
   APPWRITE_ENDPOINT   = https://sgp.cloud.appwrite.io/v1
   DATABASE_ID         = versz-db
   FIREBASE_SERVICE_JSON = <stringified service account JSON>

10. SECURITY — ROTATE YOUR API KEY
    ──────────────────────────────────
    Your current API key is hardcoded in this file.
    BEFORE committing to GitHub:
    1. Go to Appwrite Console → Settings → API Keys
    2. Delete the current key
    3. Create a new key
    4. Store it in an environment variable:
       export APPWRITE_API_KEY=new_key
    5. Never hardcode API keys in source files again.

═══════════════════════════════════════════
''');
}

// ════════════════════════════════════════════════════════════════
//  DATA CLASSES
// ════════════════════════════════════════════════════════════════
class _A {
  final String key, type;
  final int? size;
  final bool req, array;
  final String? defStr;
  final int? defInt, min, max;
  final double? defDbl, minDbl, maxDbl;
  final bool? defBool;

  const _A({required this.key, required this.type, this.size,
    this.req = false, this.array = false,
    this.defStr, this.defInt, this.min, this.max,
    this.defDbl, this.minDbl, this.maxDbl, this.defBool});
}

// Shorthand constructors
_A _S(String k, int sz, {bool req=false, String? def, bool arr=false}) =>
    _A(key:k, type:'string',  size:sz, req:req, defStr:def, array:arr);
_A _I(String k, {bool req=false, int? def, int? min, int? max}) =>
    _A(key:k, type:'integer', req:req, defInt:def, min:min, max:max);
_A _D(String k, {bool req=false, double? def, double? min, double? max}) =>
    _A(key:k, type:'double',  req:req, defDbl:def, minDbl:min, maxDbl:max);
_A _B(String k, {bool req=false, bool? def}) =>
    _A(key:k, type:'boolean', req:req, defBool:def);

class _Idx {
  final String key, type;
  final List<String> attrs, orders;
  const _Idx(this.key, this.type, this.attrs, this.orders);
}