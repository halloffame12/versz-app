# Versz App - ACTION ITEMS & FIXES

## 1. CRITICAL: Fix Messaging System

### Issue
Messages use `room_id` but schema expects `conversation_id` for direct messages.

### Current Problem Code
```dart
// WRONG: lib/providers/message_provider.dart line 55-65
Future<void> fetchMessages() async {
  final response = await _appwrite.databases.listDocuments(
    databaseId: AppwriteConstants.databaseId,
    collectionId: AppwriteConstants.messagesCollection,
    queries: [
      Query.equal('room_id', _roomId), // WRONG FIELD!
      Query.orderDesc('\$createdAt'),
    ],
  );
}
```

### Fix Required
**Step 1**: Create new ConversationProvider
- Manage conversations collection with participant filtering
- Handle creating/retrieving conversations between two users
- Track unread counts

**Step 2**: Refactor MessageProvider  
- Change parameter from `roomId` to `conversationId`
- Update queries to use `conversation_id` instead of `room_id`
- Update sendMessage to include `message_type` field (required)

**Step 3**: Update chat_detail_screen.dart
- Change to accept Conversation instead of Room
- Update messageProvider key from room.id to conversation.id

### Affected Files
- `lib/providers/message_provider.dart` - REFACTOR
- `lib/screens/main/chat_detail_screen.dart` - UPDATE
- Create: `lib/providers/conversation_provider.dart` - NEW

---

## 2. CRITICAL: Create Vote Provider

### Issue
No VoteProvider exists. Debate voting UI exists but doesn't save votes.

### Implementation Skeleton
```dart
// NEW FILE: lib/providers/vote_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/appwrite_service.dart';
import '../models/vote.dart';
import '../core/constants/appwrite_constants.dart';
import 'package:appwrite/appwrite.dart';

final voteProvider = StateNotifierProvider.family<VoteNotifier, VoteState, String>((ref, debateId) {
  return VoteNotifier(AppwriteService(), debateId);
});

class VoteState {
  final Vote? currentUserVote; // Current user's vote for this debate
  final bool isLoading;
  final String? error;

  VoteState({
    this.currentUserVote,
    this.isLoading = false,
    this.error,
  });

  VoteState copyWith({
    Vote? currentUserVote,
    bool? isLoading,
    String? error,
  }) {
    return VoteState(
      currentUserVote: currentUserVote ?? this.currentUserVote,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class VoteNotifier extends StateNotifier<VoteState> {
  final AppwriteService _appwrite;
  final String _debateId;

  VoteNotifier(this._appwrite, this._debateId) : super(VoteState());

  // Fetch current user's vote for this debate (if exists)
  Future<void> fetchUserVote(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.votesCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.equal('debate_id', _debateId),
        ],
      );

      if (response.documents.isNotEmpty) {
        state = state.copyWith(
          currentUserVote: Vote.fromMap(response.documents.first.data),
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Cast or update vote
  Future<void> vote(String userId, String voteType) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Check if user already voted
      if (state.currentUserVote != null) {
        // Update existing vote
        await _appwrite.databases.updateDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.votesCollection,
          documentId: state.currentUserVote!.id,
          data: {'vote_type': voteType},
        );
      } else {
        // Create new vote
        await _appwrite.databases.createDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.votesCollection,
          documentId: ID.unique(),
          data: {
            'user_id': userId,
            'debate_id': _debateId,
            'vote_type': voteType,
          },
        );
      }
      
      // Refresh user's vote
      await fetchUserVote(userId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Remove vote
  Future<void> removeVote() async {
    if (state.currentUserVote == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _appwrite.databases.deleteDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.votesCollection,
        documentId: state.currentUserVote!.id,
      );
      state = state.copyWith(currentUserVote: null, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
```

### Integration Points
- Update `debate_detail_screen.dart` to use voteProvider
- Call `fetchUserVote()` on screen init
- Use `vote()` method on button press
- Update debate counts in real-time after voting

---

## 3. CRITICAL: Fix Comment Avatar

### Issue
Comments don't fetch user avatar when posting.

### Current Code (WRONG)
```dart
// line 50-75 in lib/providers/comment_provider.dart
Future<void> postComment(String text, {String? parentId, String? voteType}) async {
  try {
    final user = await _appwrite.account.get();
    
    await _appwrite.databases.createDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.commentsCollection,
      documentId: ID.unique(),
      data: {
        'debate_id': _debateId,
        'user_id': user.$id,
        'username': user.name,
        'text': text,
        'parent_id': parentId,
        'vote_type': voteType,
        'upvotes': 0,
        'downvotes': 0,
        'reply_count': 0,
        'is_flagged': false,
        'is_deleted': false,
        'is_edited': false,
        'is_pinned': false,
        // MISSING avatar_url!
      },
    );
    await fetchComments();
  } catch (e) {
    state = state.copyWith(error: e.toString());
  }
}
```

### Fixed Code
```dart
Future<void> postComment(String text, {String? parentId, String? voteType}) async {
  try {
    final user = await _appwrite.account.get();
    
    // FETCH user profile for avatar
    final profileDoc = await _appwrite.databases.getDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.profilesCollection,
      documentId: user.$id,
    );
    
    await _appwrite.databases.createDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.commentsCollection,
      documentId: ID.unique(),
      data: {
        'debate_id': _debateId,
        'user_id': user.$id,
        'username': user.name,
        'avatar_url': profileDoc.data['avatar_url'], // ADD THIS!
        'text': text,
        'parent_id': parentId,
        'vote_type': voteType,
        'upvotes': 0,
        'downvotes': 0,
        'reply_count': 0,
        'is_flagged': false,
        'is_deleted': false,
        'is_edited': false,
        'is_pinned': false,
      },
    );
    await fetchComments();
  } catch (e) {
    state = state.copyWith(error: e.toString());
  }
}
```

---

## 4. FIX: User Search Field

### Issue
Search uses `display_name` but fulltext index is on `username`.

### Current Code (WRONG)
```dart
// lib/providers/search_provider.dart line 95-104
Future<List<UserAccount>> _searchUsers(String query) async {
  try {
    final response = await _appwrite.databases.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.profilesCollection,
      queries: [
        Query.search('display_name', query), // WRONG FIELD!
        Query.limit(10),
      ],
    );
    return response.documents.map((doc) => UserAccount.fromMap(doc.data)).toList();
  } catch (e) {
    return [];
  }
}
```

### Fixed Code
```dart
Future<List<UserAccount>> _searchUsers(String query) async {
  try {
    final response = await _appwrite.databases.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.profilesCollection,
      queries: [
        Query.search('username', query), // USE CORRECT FIELD!
        Query.limit(10),
      ],
    );
    return response.documents.map((doc) => UserAccount.fromMap(doc.data)).toList();
  } catch (e) {
    return [];
  }
}
```

---

## 5. FIX: Profile Route Navigation

### Issue
Profile route doesn't support userId parameter properly.

### Current Code (WRONG)
```dart
// lib/core/utils/app_router.dart line 63-68
GoRoute(
  path: '/profile/:userId',
  builder: (context, state) {
    final userId = state.pathParameters['userId'];
    return ProfileScreen(userId: userId);
  },
),

// But also has:
GoRoute(
  path: '/profile',
  builder: (context, state) => const ProfileScreen(), // NO userId!
),
```

### Fixed Code
```dart
// Navigate to current user's profile
GoRoute(
  path: '/profile',
  builder: (context, state) => const ProfileScreen(userId: null), // Explicitly null for current user
),

// Navigate to other user's profile
GoRoute(
  path: '/profile/:userId',
  builder: (context, state) {
    final userId = state.pathParameters['userId'];
    return ProfileScreen(userId: userId);
  },
),
```

### Usage in Code
```dart
// View current user profile
context.push('/profile');

// View specific user profile
context.push('/profile/${userId}');
```

---

## 6. MISSING: Add Comment Voting (comment_votes)

### Implementation Template
```dart
// NEW FILE: lib/providers/comment_vote_provider.dart
final commentVoteProvider = StateNotifierProvider.family<CommentVoteNotifier, CommentVoteState, String>((ref, commentId) {
  return CommentVoteNotifier(AppwriteService(), commentId);
});

class CommentVoteState {
  final int? currentUserVote; // -1 for downvote, 0 for none, 1 for upvote
  final int upvotes;
  final int downvotes;
  final bool isLoading;
  final String? error;

  CommentVoteState({
    this.currentUserVote,
    this.upvotes = 0,
    this.downvotes = 0,
    this.isLoading = false,
    this.error,
  });

  CommentVoteState copyWith({
    int? currentUserVote,
    int? upvotes,
    int? downvotes,
    bool? isLoading,
    String? error,
  }) {
    return CommentVoteState(
      currentUserVote: currentUserVote ?? this.currentUserVote,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class CommentVoteNotifier extends StateNotifier<CommentVoteState> {
  final AppwriteService _appwrite;
  final String _commentId;

  CommentVoteNotifier(this._appwrite, this._commentId) : super(CommentVoteState());

  Future<void> vote(String userId, int voteValue) async {
    // voteValue: 1 for upvote, -1 for downvote, 0 to remove
    state = state.copyWith(isLoading: true);
    
    try {
      final response = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.commentVotesCollection,
        queries: [
          Query.equal('comment_id', _commentId),
          Query.equal('user_id', userId),
        ],
      );

      if (response.documents.isNotEmpty) {
        // Update existing vote
        if (voteValue == 0) {
          // Remove vote
          await _appwrite.databases.deleteDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.commentVotesCollection,
            documentId: response.documents.first.$id,
          );
        } else {
          // Update vote
          await _appwrite.databases.updateDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.commentVotesCollection,
            documentId: response.documents.first.$id,
            data: {'vote': voteValue},
          );
        }
      } else if (voteValue != 0) {
        // Create new vote
        await _appwrite.databases.createDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.commentVotesCollection,
          documentId: ID.unique(),
          data: {
            'comment_id': _commentId,
            'user_id': userId,
            'vote': voteValue,
          },
        );
      }

      state = state.copyWith(currentUserVote: voteValue, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
```

---

## 7. ADD: UserAccount Model Missing Fields

### Current Code
```dart
// lib/models/user_account.dart - INCOMPLETE
```

### Missing Fields from Schema
```dart
// Add these fields to UserAccount model:
final String? fcmTokenUpdated; // When FCM token was last updated
final String? platform; // 'ios', 'android', 'web'  
final String? notificationPrefs; // JSON string of notification preferences
```

### Updated Model
```dart
class UserAccount extends Equatable {
  // ... existing fields ...
  final String? fcmToken;
  final String? fcmTokenUpdated;    // ADD THIS
  final String? platform;            // ADD THIS
  final String? notificationPrefs;   // ADD THIS

  const UserAccount({
    // ... existing parameters ...
    this.fcmToken,
    this.fcmTokenUpdated,   // ADD THIS
    this.platform,          // ADD THIS
    this.notificationPrefs, // ADD THIS
  });

  factory UserAccount.fromMap(Map<String, dynamic> map) {
    return UserAccount(
      // ... existing mappings ...
      fcmToken: map['fcm_token'],
      fcmTokenUpdated: map['fcm_token_updated'],      // ADD THIS
      platform: map['platform'],                      // ADD THIS
      notificationPrefs: map['notification_prefs'],   // ADD THIS
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // ... existing mappings ...
      'fcm_token': fcmToken,
      'fcm_token_updated': fcmTokenUpdated,      // ADD THIS
      'platform': platform,                      // ADD THIS
      'notification_prefs': notificationPrefs,   // ADD THIS
    };
  }
}
```

---

## 8. FIX: Wallet System

### Option A: Remove Wallet Feature
If not implementing:
```dart
// Remove from app_router.dart
GoRoute(
  path: '/wallet',
  builder: (context, state) => const WalletScreen(),
),
```

### Option B: Implement Properly
Create `wallets` collection in Appwrite or map to transactions collection.

**NOT RECOMMENDED** - Current wallet system is incomplete. Recommend Option A unless wallet is critical feature.

---

## Summary of Files to Modify

### Files to CREATE (New Providers)
- [ ] `lib/providers/vote_provider.dart`
- [ ] `lib/providers/conversation_provider.dart`
- [ ] `lib/providers/comment_vote_provider.dart`
- [ ] `lib/providers/notification_provider.dart`
- [ ] `lib/providers/room_members_provider.dart`
- [ ] `lib/providers/saved_debates_provider.dart`
- [ ] `lib/providers/report_provider.dart`

### Files to MODIFY (Existing)
- [ ] `lib/providers/message_provider.dart` - Refactor to use conversation_id
- [ ] `lib/providers/comment_provider.dart` - Add avatar fetching
- [ ] `lib/providers/search_provider.dart` - Fix user search field
- [ ] `lib/models/user_account.dart` - Add missing fields
- [ ] `lib/core/utils/app_router.dart` - Fix profile route
- [ ] `lib/screens/main/chat_detail_screen.dart` - Update for conversations
- [ ] `lib/screens/debate/debate_detail_screen.dart` - Integrate vote provider

### Priority Order
1. Fix comment avatar (quick win)
2. Fix search field (quick win)
3. Create vote provider (high impact)
4. Refactor messaging (complex, high impact)
5. Fix profile route (quick win)
6. Add missing providers (medium effort, enables features)
