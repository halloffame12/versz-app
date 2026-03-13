class AppwriteConstants {
  static const String endpoint = 'https://sgp.cloud.appwrite.io/v1';
  static const String projectId = '69b00336003a3772ee69';
  static const String databaseId = 'versz-db';

  // Collection IDs (master prompt)
  static const String users = 'users';
  static const String debates = 'debates';
  static const String comments = 'comments';
  static const String votes = 'votes';
  static const String likes = 'likes';
  static const String saves = 'saves';
  static const String connections = 'connections';
  static const String follows = 'follows';
  static const String chats = 'chats';
  static const String conversations = 'conversations';
  static const String messages = 'messages';
  static const String typingStatus = 'typing_status';
  static const String debateViews = 'debate_views';
  static const String profileViews = 'profile_views';
  static const String notifications = 'notifications';
  static const String rooms = 'rooms';
  static const String roomMembers = 'room_members';
  static const String reports = 'reports';
  static const String badges = 'badges';
  static const String categories = 'categories';
  static const String aiSummaries = 'ai_summaries';
  static const String leaderboard = 'leaderboard';
  static const String trending = 'trending';
  static const String hashtags = 'hashtags';
  static const String savedDebates = 'saved_debates';

  // Backward-compatible aliases used in existing code
  static const String usersCollection = users;
  static const String debatesCollection = debates;
  static const String votesCollection = votes;
  static const String commentsCollection = comments;
  static const String followsCollection = follows;
  static const String notificationsCollection = notifications;
  static const String roomsCollection = rooms;
  static const String roomMembersCollection = roomMembers;
  static const String messagesCollection = messages;
  static const String conversationsCollection = conversations;
  static const String badgesCollection = badges;
  static const String reportsCollection = reports;
  static const String categoriesCollection = categories;
  static const String savedDebatesCollection = savedDebates;

  // Bucket IDs (master prompt)
  static const String avatarsBucket = 'avatars';
  static const String coverImagesBucket = 'cover-images';
  static const String debateImagesBucket = 'debate-images';
  static const String chatMediaBucket = 'chat-media';
  static const String mediaBucket = 'media';

  // Cloud Function IDs
  static const String sendNotificationFn = 'send-notification';
  static const String geminiSummaryFn = 'gemini-summary';
  static const String updateTrendingFn = 'update-trending';
  static const String updateLeaderboardFn = 'update-leaderboard';
  static const String checkAchievementsFn = 'check-achievements';
}
