# Versz App - Architecture Issues Visualization

## Current vs Correct Messaging Architecture

### ❌ CURRENT (BROKEN)
```
┌──────────────────────────────────────────────────────────┐
│  ChatDetailScreen (Room Based)                           │
│  - Takes: Room object                                    │
│  - Passes: room.id to messageProvider                    │
└──────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────┐
│  MessageProvider(room.id)                                │
│  - Uses: Query.equal('room_id', roomId) ❌               │
│  - Problem: WRONG FIELD - schema uses conversation_id    │
└──────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────┐
│  Appwrite Messages Collection                            │
│  - Expects: conversation_id field                        │
│  - Receives: Query for room_id field                     │
│  - Result: No messages found ❌                          │
└──────────────────────────────────────────────────────────┘

IMPACT: Users can't see or send direct messages
```

### ✅ CORRECT (PROPOSED)
```
┌──────────────────────────────────────────────────────────┐
│  ConversationDetailScreen (DM Based)                     │
│  - Takes: Conversation (user1 ↔ user2)                   │
│  - Passes: conversation.id to messageProvider           │
└──────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────┐
│  MessageProvider(conversation.id)                        │
│  - Uses: Query.equal('conversation_id', convId) ✅       │
│  - Correct field matches schema definition              │
└──────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────┐
│  Appwrite Messages Collection                            │
│  - Expects: conversation_id field                        │
│  - Receives: Correct query for conversation_id          │
│  - Result: Messages retrieved successfully ✅            │
└──────────────────────────────────────────────────────────┘

IMPACT: DMs work correctly, data persists
```

### Separate Room Chat Feature (If Needed)
```
┌──────────────────────────────────────────────────────────┐
│  RoomChatScreen                                          │
│  - Takes: Room object                                    │
│  - Separate from DM flow                                │
└──────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────┐
│  RoomMessageProvider(room.id)                            │
│  - Custom implementation for room chat                   │
│  - Uses different data structure                         │
└──────────────────────────────────────────────────────────┘
```

---

## Provider Implementation Status

### ✅ IMPLEMENTED (Working)
```
auth_provider.dart           (working well)
    ├── Signup/Login flow
    ├── Profile creation/fetch
    └── Session management

debate_provider.dart         (working well)
    ├── Fetch debates
    └── Create debates

category_provider.dart       (working well)
    └── Fetch categories

room_provider.dart           (partially working)
    └── Fetch rooms only

comment_provider.dart        (partially working - missing avatar)
    ├── Create comments
    └── Fetch comments

profile_provider.dart        (working)
    ├── Fetch profile
    └── Update profile

search_provider.dart         (1 wrong field)
    ├── Search debates ✅
    ├── Search rooms ✅
    └── Search users ❌ (wrong field)

social_provider.dart         (working)
    ├── Follow/unfollow
    └── Check following

leaderboard_provider.dart    (partially working)
    └── Fetch rankings (no UI)

message_provider.dart        (broken - wrong field)
    └── Uses room_id instead of conversation_id

wallet_provider.dart         (not implemented)
    └── Uses mock data only
```

### ❌ MISSING (Critical)
```
vote_provider.dart           (MISSING) 🔴 CRITICAL
    ├── Cast vote on debate
    ├── Update vote
    └── Remove vote

conversation_provider.dart   (MISSING) 🔴 CRITICAL
    ├── List conversations
    ├── Get/create conversation
    └── Update last message

notification_provider.dart   (MISSING) 🔴 CRITICAL
    ├── Fetch notifications
    ├── Mark as read
    └── Delete notification

comment_vote_provider.dart   (MISSING) 🟠 HIGH
    ├── Vote on comment
    └── Remove vote

room_members_provider.dart   (MISSING) 🟠 HIGH
    ├── Add member to room
    ├── Remove member
    └── Update member role

saved_debates_provider.dart  (MISSING) 🟡 MEDIUM
    ├── Save debate
    ├── Unsave debate
    └── List saved debates

report_provider.dart         (MISSING) 🟡 MEDIUM
    ├── Report content
    └── Track reports

badges_provider.dart         (MISSING) 🟡 MEDIUM
    ├── Award badge
    └── List badges
```

---

## Data Flow Issues

### Feature: User Comments on Debate

#### Current Flow (With Issues)
```
User types comment in DetailScreen
        ↓
commentProvider.postComment()
        ↓
Fetch current user (Account)
        ↓
Create document in comments collection
        │
        ├─ debate_id: ✅ Correct
        ├─ user_id: ✅ Correct
        ├─ username: ✅ Correct
        ├─ avatar_url: ❌ MISSING! (null)
        ├─ text: ✅ Correct
        └─ vote_type: ✅ Correct
        ↓
fetchComments() - displays without avatars ❌
```

#### Fixed Flow
```
User types comment in DetailScreen
        ↓
commentProvider.postComment()
        ↓
Fetch current user (Account)
        ↓
→ Fetch user profile for avatar_url ← NEW!
        ↓
Create document in comments collection
        │
        ├─ debate_id: ✅ Correct
        ├─ user_id: ✅ Correct
        ├─ username: ✅ Correct
        ├─ avatar_url: ✅ CORRECT NOW!
        ├─ text: ✅ Correct
        └─ vote_type: ✅ Correct
        ↓
fetchComments() - displays with avatars ✅
```

---

## Feature: Vote on Debate

### Current State (BROKEN)
```
User clicks "AGREE" or "DISAGREE" button
        ↓
Button changes color locally
        ↓
... nothing else happens ...
        ↓
NO provider exists to save vote ❌
Vote not persisted to database ❌
Refreshing page resets vote state ❌
Vote counts don't update ❌
```

### After Fix (WORKING)
```
User clicks "AGREE" button
        ↓
voteProvider.vote(userId, 'agree')
        ↓
Check if user already voted
        │
        ├─ If yes: update existing vote
        └─ If no: create new vote
        ↓
Save to votes collection with:
├─ user_id ✅
├─ debate_id ✅
├─ vote_type ✅
└─ Unique constraint on (user_id, debate_id) ✅
        ↓
Vote persists to database ✅
Refreshing shows correct vote ✅
Vote counts can be calculated ✅
```

---

## Search Field Issue

### Current (WRONG)
```
User searches for "john"
        ↓
searchProvider._searchUsers("john")
        ↓
Query.search('display_name', "john")
        │
        └─ Problem: No fulltext index on display_name!
        ↓
Appwrite: Index not found ❌
Results: None or error
User sees: No results found ❌
```

### Fixed (CORRECT)
```
User searches for "john"
        ↓
searchProvider._searchUsers("john")
        ↓
Query.search('username', "john")
        │
        └─ Correct: Fulltext index exists on username!
        ↓
Appwrite: Uses index, searches fast ✅
Results: All users with "john" in username ✅
User sees: Correct results ✅
```

---

## Voting Architecture

### ✅ Debates voting (to implement)
```
Debate Document:
{
  $id: "debate123",
  title: "...",
  agree_count: 45,    ← Updated by function when vote created
  disagree_count: 32, ← Updated by function when vote created
}

Votes Collection:
{
  $id: "vote456",
  user_id: "user123",
  debate_id: "debate123",
  vote_type: "agree"  ← Can be: "agree" or "disagree"
}

Unique Index: (user_id, debate_id) 
↓
Prevents duplicate votes from same user ✅
```

### ✅ Comments voting (to implement)
```
Comment Document:
{
  $id: "comment789",
  debate_id: "debate123",
  upvotes: 12,    ← Updated by function when vote created
  downvotes: 3,   ← Updated by function when vote created
}

Comment Votes Collection:
{
  $id: "cmtvote101",
  comment_id: "comment789",
  user_id: "user123",
  vote: 1  ← Can be: 1 (upvote), -1 (downvote), 0 (none)
}

Unique Index: (comment_id, user_id)
↓
Prevents duplicate votes from same user ✅
```

---

## Model-Schema Alignment Matrix

| Entity | Model | Schema | Status | Issues |
|--------|-------|--------|--------|--------|
| UserAccount | user_account.dart | profiles | ⚠️ 95% | Missing: notification_prefs, platform, fcm_token_updated |
| Debate | debate.dart | debates | ✅ 100% | None |
| Comment | comment.dart | comments | ✅ 100% | None |
| Vote | vote.dart | votes | ✅ 100% | But no provider! |
| Message | message.dart | messages | ⚠️ 95% | Implementation uses wrong field (room_id) |
| Conversation | conversation.dart | conversations | ✅ 100% | But no provider! |
| Room | room.dart | rooms | ✅ 100% | But no creation/management |
| RoomMember | (missing) | room_members | ❌ 0% | Model and provider missing |
| Notification | notification.dart | notifications | ✅ Model OK | But no provider! |
| Category | category.dart | categories | ✅ 100% | None |
| LeaderboardEntry | leaderboard_entry.dart | leaderboard_cache | ✅ 100% | But no UI |
| Badge | (missing) | badges | ❌ 0% | Model and provider missing |
| SavedDebate | (missing) | saved_debates | ❌ 0% | Model and provider missing |
| Report | (missing) | reports | ❌ 0% | Model and provider missing |

---

## Collection Utilization

```
✅ FULLY USED
├─ profiles (auth_provider, profile_provider, search_provider)
├─ debates (debate_provider, search_provider)
├─ categories (category_provider)
└─ follows (social_provider)

⚠️ PARTIALLY USED
├─ comments (comment_provider - missing avatar)
├─ rooms (room_provider - can't create)
├─ votes (no provider - can't vote)
├─ messages (wrong implementation - uses room_id)
└─ conversations (no provider - not used)

❌ UNUSED
├─ room_members (no provider)
├─ comment_votes (no provider)
├─ notifications (no provider)
├─ badges (no provider)
├─ saved_debates (no provider)
├─ reports (no provider)
└─ leaderboard_cache (has provider but no UI)
```

---

## Expected vs Actual Implementation

### Authentication
```
Expected: signup → create profile → auto login → fetch profile
Actual:   ✅ WORKS (all steps implemented correctly)
```

### Debate Creation & Discussion
```
Expected: create debate → vote → comment → see avatars → reply
Actual:   
  - create debate ✅
  - vote ❌ (no provider)
  - comment ✅ (but no avatar)
  - see avatars ❌ (avatar_url is null)
  - reply ✅ (parent_id field exists)
```

### Direct Messaging
```
Expected: findUser → startConversation → sendMessage → realtime
Actual:
  - findUser ❌ (search wrong field)
  - startConversation ❌ (no provider)
  - sendMessage ❌ (implementation uses room_id)
  - realtime ❌ (not properly connected)
```

### Search
```
Expected: search debates ✅, search users ✅, search rooms ✅
Actual: 
  - search debates ✅ (works)
  - search users ❌ (wrong field)
  - search rooms ✅ (works)
```

---

## Summary: How Many Hours to Fix?

| Task | Complexity | Time |
|------|-----------|------|
| Fix comment avatar | ⭐ Very Easy | 1 hour |
| Fix search field | ⭐ Very Easy | 15 min |
| Fix profile route | ⭐ Easy | 30 min |
| Create vote provider | ⭐⭐ Easy | 4-6 hours |
| Refactor messaging | ⭐⭐⭐ Medium | 8-12 hours |
| Create notification provider | ⭐⭐ Easy | 3-4 hours |
| Create conversation provider | ⭐⭐⭐ Medium | 5-7 hours |
| Create room members provider | ⭐⭐ Easy | 3-4 hours |
| Fix error handling | ⭐⭐ Easy | 4-5 hours |
| Create remaining 3 providers | ⭐⭐ Easy | 6-8 hours |
| Testing & QA | ⭐⭐⭐ Medium | 10-15 hours |

**TOTAL CRITICAL (Phase 1)**: ~25-35 hours  
**TOTAL ALL (Phases 1-3)**: ~50-70 hours

---

This visualization should help the team understand:
1. **What's broken** and why
2. **What's missing** and why it matters
3. **How to fix it** architecturally
4. **Effort estimates** for planning
5. **Priority order** for implementation
