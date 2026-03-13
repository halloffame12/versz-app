class AppwriteConstants {
  static const String endpoint = 'https://sgp.cloud.appwrite.io/v1';
  static const String projectId = '69b00336003a3772ee69';
  static const String databaseId = 'versz-db';

  // Collection IDs used by the current app (v3 schema).
  static const String users = 'users';
  static const String debates = 'debates';
  static const String comments = 'comments';
  static const String votes = 'votes';
  static const String likes = 'likes';
  static const String saves = 'saves';
  static const String connections = 'connections';
  static const String chats = 'chats';
  static const String messages = 'messages';
  static const String typingStatus = 'typing_status';
  static const String debateViews = 'debate_views';
  static const String notifications = 'notifications';
  static const String communities = 'communities';
  static const String communityMembers = 'community_members';
  static const String reports = 'reports';
  static const String badges = 'badges';
  static const String categories = 'categories';
  static const String trending = 'trending';
  static const String hashtags = 'hashtags';

  // Backward-compatible aliases still used in providers.
  static const String usersCollection = users;
  static const String debatesCollection = debates;
  static const String votesCollection = votes;
  static const String commentsCollection = comments;
  static const String notificationsCollection = notifications;
  static const String rooms = communities;
  static const String roomsCollection = communities;
  static const String roomMembersCollection = communityMembers;
  static const String messagesCollection = messages;
  static const String badgesCollection = badges;
  static const String reportsCollection = reports;
  static const String categoriesCollection = categories;
  static const String savedDebatesCollection = saves;
}
