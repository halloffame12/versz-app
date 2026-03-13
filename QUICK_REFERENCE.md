# Versz App - Quick Reference Checklist

## 🔴 CRITICAL FIXES (Do These First)

### Messaging System - BROKEN ARCHITECTURE
- [ ] Understand the difference: rooms vs conversations  
  - **Rooms** = Group chats for debates/topics
  - **Conversations** = DMs between two users
- [ ] Review schema: messages have `conversation_id`, not `room_id`
- [ ] Refactor `message_provider.dart` to use `conversation_id`
- [ ] Create new `conversation_provider.dart`
- [ ] Update `chat_detail_screen.dart` to work with Conversations
- [ ] Remove room-based messaging code
- **Estimated Time**: 8-12 hours

### Voting System - MISSING ENTIRELY
- [ ] Create `vote_provider.dart` using template in ACTION_ITEMS.md
- [ ] Implement unique constraint checking (user can only vote once per debate)
- [ ] Add vote UI integration in `debate_detail_screen.dart`
- [ ] Handle vote changes (switch from agree to disagree)
- [ ] Update debate vote counts after voting
- **Estimated Time**: 4-6 hours

### Comment Avatar Missing
- [ ] Fix `comment_provider.dart` postComment method
- [ ] Fetch user profile to get avatar_url
- [ ] Pass avatar_url when creating comment document
- [ ] Test comment creation shows avatar
- **Estimated Time**: 1 hour

### User Search Wrong Field
- [ ] Change search field from `display_name` to `username` in `search_provider.dart`
- [ ] Test user search returns correct results
- **Estimated Time**: 15 minutes

### Profile Route Issue
- [ ] Update `/profile` route to support both:
  - With userId parameter for viewing specific user
  - Without for viewing current user
- [ ] Ensure ProfileScreen handles both null and string userId
- [ ] Test navigation works both ways
- **Estimated Time**: 30 minutes

---

## 🟠 HIGH PRIORITY FIXES (Do These Next)

### Create Vote Provider
- [ ] `lib/providers/vote_provider.dart`
- [ ] Handle vote creation/update/delete
- [ ] Handle vote conflicts (can only vote once)

### Create Notification Provider  
- [ ] `lib/providers/notification_provider.dart`
- [ ] Fetch notifications for user
- [ ] Mark as read functionality
- [ ] Delete notifications
- [ ] Link to create nav route

### Create Conversation Provider
- [ ] `lib/providers/conversation_provider.dart`
- [ ] List conversations for user
- [ ] Create conversation between two users
- [ ] Get or create conversation (for starting DM)
- [ ] Update last message info

### Create Room Members Provider
- [ ] `lib/providers/room_members_provider.dart`
- [ ] Add user to room
- [ ] Remove user from room
- [ ] Update user role in room
- [ ] List room members

### Fix Wallet System
- [ ] Option A: Remove wallet feature completely
- [ ] Option B: Implement wallet collection in Appwrite first
- [ ] Create `wallet_provider.dart` with real data
- **Recommended**: Option A (not core feature)

### Add Missing Fields to UserAccount
- [ ] Add `fcmTokenUpdated` string field
- [ ] Add `platform` string field ('ios', 'android', 'web')
- [ ] Add `notificationPrefs` string field (JSON)
- [ ] Update auth_provider to set these during signup
- [ ] Update profile_provider to include these in updates

---

## 🟡 MEDIUM PRIORITY (Nice to Have)

### Create Comment Voting
- [ ] `lib/providers/comment_vote_provider.dart`
- [ ] Ability to upvote/downvote comments
- [ ] Vote persistence
- [ ] Vote conflict handling

### Implement Saved Debates
- [ ] `lib/providers/saved_debates_provider.dart`
- [ ] Add save/unsave functionality
- [ ] List saved debates for user
- [ ] Show saved status in UI

### Implement Reporting  
- [ ] `lib/providers/report_provider.dart`
- [ ] Report debates/comments/users
- [ ] Track report status
- [ ] Report moderation interface

### Create Room Management
- [ ] Create room functionality
- [ ] Edit room details
- [ ] Upload room assets
- [ ] Delete room (if owner)

### Implement Badges System
- [ ] `lib/providers/badges_provider.dart`
- [ ] Award badges to users
- [ ] Display earned badges
- [ ] Badge achievement tracking

---

## 🟢 OPTIONAL/POLISH

### Improve Error Handling
- [ ] Create ErrorMapper utility for user-friendly messages
- [ ] Map Appwrite exceptions to UI messages
- [ ] Add retry logic for failed operations
- [ ] Add error recovery UI

### Add Media Features
- [ ] Implement video player for video debates
- [ ] Improve image upload/compression
- [ ] Add video upload support
- [ ] Implement media preview

### Enhance Leaderboard
- [ ] Better UI for leaderboard display
- [ ] Multiple leaderboard types (reputation, debates, streaks)
- [ ] Period selection (weekly, all-time)
- [ ] Category-specific leaderboards

### Edit/Delete Features
- [ ] Allow comment editing
- [ ] Allow comment soft-delete
- [ ] Allow debate edits (owner only)
- [ ] Show edit history

### Follow System
- [ ] List followers/following
- [ ] See follower's debates first
- [ ] Block/unblock users
- [ ] Report users

---

## 📋 TESTING CHECKLIST

### Authentication
- [ ] Signup creates profile with all required fields
- [ ] Login fetches user profile correctly
- [ ] Logout clears auth state
- [ ] Session persistence works
- [ ] Error handling for invalid credentials

### Debates
- [ ] Create debate with all fields
- [ ] Debate appears in feed immediately
- [ ] Vote on debate saves correctly
- [ ] Vote counts update in real-time
- [ ] Search finds newly created debates

### Comments
- [ ] Comments appear with avatar
- [ ] Reply functionality works
- [ ] Nested comments display correctly
- [ ] Delete/edit works if implemented

### Messaging
- [ ] Conversations load correctly
- [ ] Messages send and appear
- [ ] Message persistence verified
- [ ] Real-time updates work
- [ ] Unread counts accurate

### Search
- [ ] Debate search works
- [ ] User search returns correct results
- [ ] Room search works
- [ ] Empty query handled gracefully

### Navigation
- [ ] All routes accessible
- [ ] Back navigation works
- [ ] Deep links work
- [ ] Params passed correctly

### Profile
- [ ] Current user profile loads
- [ ] Other user profiles load
- [ ] Follow button works
- [ ] Stats display correctly

---

## 🔧 DEVELOPMENT SETUP

### Before Starting
- [ ] Read COMPREHENSIVE_ANALYSIS_REPORT.md
- [ ] Read ACTION_ITEMS.md for code templates
- [ ] Clone latest code
- [ ] Run `flutter pub get`
- [ ] Run build: `flutter build apk`

### Testing Each Fix
```bash
# After each fix, run:
flutter pub get
flutter analyze  # Check for lint issues
# Run on emulator/device to test

# Test specific feature:
# 1. Clear app data
# 2. Create new account
# 3. Test the feature end-to-end
# 4. Check Appwrite console for correct data
```

### Debugging Tips
- Use Appwrite console to verify data structure
- Check Flutter debugger for state changes
- Use Network tab to see API requests
- Review error logs in Appwrite dashboard
- Test with multiple users for concurrency issues

---

## 📊 PROGRESS TRACKING

### Phase 1: Critical Fixes (Target: 1 week)
- [ ] Messaging refactoring
- [ ] Vote provider
- [ ] Comment avatar
- [ ] Search field fix
- [ ] Profile route fix

### Phase 2: High Priority (Target: 1 week)
- [ ] Notification provider
- [ ] Conversation provider  
- [ ] Room members provider
- [ ] Missing field additions
- [ ] Wallet decision

### Phase 3: Medium Priority (Target: 2 weeks)
- [ ] Comment voting
- [ ] Saved debates
- [ ] Reporting system
- [ ] Room creation
- [ ] Badges

### Phase 4: Polish (Target: Ongoing)
- [ ] Error handling
- [ ] UI improvements
- [ ] Performance optimization
- [ ] Edge case handling

---

## 📞 QUICK HELP

### Q: How do I know which field to use?
**A**: Check `scripts/setup_appwrite.dart` for the source of truth. All collection schemas are defined there.

### Q: My changes don't show up
**A**: 
1. Check Appwrite console to verify data was saved
2. Rebuild Flutter app (clean build if needed)
3. Check provider is being watched (use `ref.watch()` not `ref.read()`)

### Q: How do I test a provider?
**A**:
1. Create a simple test screen
2. Use `ref.watch()` to display state
3. Add buttons to trigger provider methods
4. Check console output and UI

### Q: What's the difference between StateNotifier and Provider?
**A**:
- **StateNotifier**: For mutable state (lists, counters) - use when state changes
- **Provider**: For immutable data/functions - use for read-only or simple functions

### Q: How do conversations differ from rooms?
**A**:
- **Conversations**: Private DMs between 2 specific users
- **Rooms**: Group chats with many members on a topic

---

## 🎯 SUCCESS CRITERIA

Once all fixes complete, the app should:
1. ✅ Auth flow: Signup → Profile → Login works end-to-end
2. ✅ Debates: Create, view, vote, comment, search
3. ✅ Voting: Can vote on debates, votes persist
4. ✅ Comments: Show with avatars, support replies
5. ✅ Messaging: DM with other users, real-time updates
6. ✅ Navigation: All screens accessible, no broken routes
7. ✅ Data: All changes persist in Appwrite
8. ✅ Search: Find debates, users, and rooms

---

## 📚 RESOURCES

- Appwrite Docs: https://appwrite.io/docs
- Flutter Riverpod: https://riverpod.dev
- Go Router: https://pub.dev/packages/go_router
- Appwrite Exception Codes: Check Appwrite console

---

**Last Updated**: March 10, 2026  
**Status**: Analysis Complete - Implementation Ready  
**Next Step**: Start with Critical Fixes Phase 1
