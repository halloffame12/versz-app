# Versz App - Complete AI Handoff

## 1) Product Summary
Versz is a Flutter + Appwrite social debate platform with:
- public debates
- comments and voting
- rooms (group chat)
- direct messages (1:1 conversations)
- notifications
- profile/follow system
- leaderboard and badges
- report and moderation flows

The backend is Appwrite (Database, Storage, Realtime, Functions), and state management is Riverpod.

## 2) Tech Stack
- Frontend: Flutter (Material 3)
- State management: flutter_riverpod
- Backend: Appwrite
- Navigation: go_router
- Media: image/video support via storage + media service
- Time formatting: timeago

Main app entry:
- lib/main.dart

Router:
- lib/core/utils/app_router.dart

Backend constants:
- lib/core/constants/appwrite_constants.dart

## 3) Appwrite Backend (Source of Truth)
Primary schema source:
- scripts/setup_appwrite.dart

Database:
- databaseId: versz-db

Collections (14):

1. users
- username (string, required, unique)
- display_name (string, required)
- avatar_url (string)
- bio (string)
- reputation (int, default 0)
- followers_count (int, default 0)
- following_count (int, default 0)
- is_verified (bool, default false)
- fcm_token (string)

2. debates
- title (string, required)
- description (string)
- category_id (string, required)
- creator_id (string, required)
- media_type (string, required; text/image/video)
- media_url (string)
- upvotes (int, default 0)
- downvotes (int, default 0)
- comment_count (int, default 0)
- status (string, required; active/closed)

3. comments
- debate_id (string, required)
- user_id (string, required)
- parent_id (string)
- content (string, required)
- upvotes (int, default 0)
- downvotes (int, default 0)
- reply_count (int, default 0)

4. votes
- user_id (string, required)
- target_id (string, required)
- target_type (string, required; debate/comment)
- value (int, required; -1 or 1)

5. rooms
- name (string, required)
- description (string)
- creator_id (string, required)
- icon_url (string)
- banner_url (string)
- members_count (int, default 0)

6. room_members
- room_id (string, required)
- user_id (string, required)
- role (string, required; admin/moderator/member)

7. conversations
- participant_1 (string, required)
- participant_2 (string, required)
- last_message (string)
- last_message_at (string ISO)

8. messages
- conversation_id (string, optional)
- room_id (string, optional)
- sender_id (string, required)
- content (string, required)
- message_type (string, required; text/image/video)
- is_read (bool, default false)

9. notifications
- user_id (string, required)
- type (string, required)
- sender_id (string)
- target_id (string)
- content (string, required)
- is_read (bool, default false)

10. follows
- follower_id (string, required)
- following_id (string, required)

11. reports
- reporter_id (string, required)
- target_id (string, required)
- target_type (string, required)
- reason (string, required)
- status (string, required; pending/resolved)

12. badges
- user_id (string, required)
- badge_id (string, required)
- earned_at (string, required)

13. categories
- name (string, required, unique)
- emoji (string, required)
- color (string, required)
- debate_count (int, default 0)

14. saved_debates
- user_id (string, required)
- debate_id (string, required)

Buckets:
- avatars
- media

Cloud Functions (configured IDs):
- send-notification
- gemini-summary
- update-trending
- update-leaderboard
- check-achievements

Functions folder:
- functions/check-achievements
- functions/gemini-summary
- functions/send-notification
- functions/update-leaderboard
- functions/update-trending

## 4) Core Models
Located in:
- lib/models

Main models:
- debate.dart
- comment.dart
- message.dart
- conversation.dart
- room.dart
- notification.dart (VerszNotification)
- user_account.dart
- vote.dart
- category.dart
- badge.dart
- leaderboard_entry.dart
- report.dart

Important naming note:
- Appwrite uses snake_case fields.
- Flutter model properties are often camelCase mapped from snake_case.

Example mapping:
- description <-> description
- upvotes <-> upvotes
- downvotes <-> downvotes
- members_count <-> membersCount
- sender_id <-> senderId

## 5) Provider Layer (Feature Ownership)
Located in:
- lib/providers

Key providers:
- auth_provider.dart: login/signup/session
- profile_provider.dart: profile load/update
- debate_provider.dart: debate list/create
- comment_provider.dart: comment list/create/edit/delete
- vote_provider.dart: upvote/downvote logic
- room_provider.dart: room list/create
- room_members_provider.dart: room membership ops
- message_provider.dart: room chat messages + realtime
- conversation_provider.dart: DM messages + conversation list + realtime
- notification_provider.dart: list/read/delete notifications
- social_provider.dart: follow/unfollow and social graph
- leaderboard_provider.dart: leaderboard fetching
- badge_provider.dart: earned badges loading
- report_provider.dart: reporting users/content
- category_provider.dart: categories fetch
- saved_debates_provider.dart: save/unsave debates
- search_provider.dart: cross-entity search

## 6) Navigation Map
Defined in:
- lib/core/utils/app_router.dart

Top-level routes:
- /
- /login
- /signup
- /debate-detail
- /create-debate
- /chat/:roomId
- /messages
- /messages/:conversationId
- /rooms/:roomId/members
- /leaderboard
- /profile/:userId

Shell routes (bottom nav):
- /home
- /search
- /rooms
- /notifications
- /profile

## 7) Features Implemented
- Authentication (login/signup)
- Debate creation and listing
- Debate detail with voting
- Comment create/edit/delete
- Realtime room messaging
- Realtime direct messaging
- Follow/unfollow users
- Notifications center
- Saved debates
- Leaderboard
- Badges
- Reports/moderation submissions
- Room member management (including remove member)

## 8) Recent Stability and UI Status
- Flutter analyze currently passes (no issues).
- Bottom navigation overflow issue was fixed in home shell.
- Text/background contrast was improved in theme and shared input field.

## 9) Schema Update Playbook (Safe)
Use this process for any schema change to avoid runtime breakage.

1. Update backend schema definition
- Edit scripts/setup_appwrite.dart collection attributes/indexes.

2. Update constants and IDs if needed
- Edit lib/core/constants/appwrite_constants.dart.

3. Update model mapping
- Edit matching file(s) in lib/models.
- Ensure fromMap/toMap match exact Appwrite field names.

4. Update provider queries and writes
- Edit affected files in lib/providers.
- Ensure Query.equal/order fields still exist in schema.

5. Update UI usage
- Search and replace old model fields in lib/screens and lib/widgets.

6. Validate
- Run flutter analyze.
- Run flutter run and test affected screens/flows.

7. Rebuild backend if required
- If destructive rebuild is acceptable, run setup scripts.
- scripts/delete_database.dart can fully drop the database.
- scripts/setup_appwrite.dart recreates collections/buckets/seeds.

## 10) Critical Gotcha List
- Do not change field names in code without matching Appwrite schema.
- conversations currently store user IDs, not rich participant profile fields.
- notifications model uses content (not title/body).
- messages are shared across room and DM; room_id vs conversation_id must be handled correctly.

## 11) Prompt You Can Give Another AI
Copy-paste this:

"You are assisting on the Versz Flutter app. Use AI_HANDOFF_VERSZ.md as source of truth for architecture, schema, providers, routes, and naming conventions. Before changing anything, verify Appwrite field names in scripts/setup_appwrite.dart and mappings in lib/models. Keep snake_case backend fields and camelCase model properties aligned. After edits, run flutter analyze and ensure no regressions in debates, comments, rooms, direct messages, notifications, and bottom navigation layout." 

## 12) Security Note
The setup scripts currently contain a real Appwrite API key directly in source.
Before sharing repository externally, rotate the key and move secrets to environment variables or secure CI/CD secret storage.
