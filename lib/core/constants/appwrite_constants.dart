class AppwriteConstants {
  // Appwrite configuration
  static const String endpoint = 'https://sgp.cloud.appwrite.io/v1';
  static const String projectId = '69b00336003a3772ee69';
  static const String databaseId = 'versz-db';
  static const String firebaseProjectId = 'versz-b4776';

    // Collections (V5 schema)
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

    // Legacy aliases currently used in some modules
    static const String communities = rooms;
    static const String communityMembers = roomMembers;

  // Storage buckets
  static const String avatarsBucket = 'avatars';
  static const String coverImagesBucket = 'cover-images';
  static const String debateImagesBucket = 'debate-images';
  static const String chatMediaBucket = 'chat-media';
  static const String mediaBucket = 'media';

  // Aliases for backward compatibility
    static const String roomsCollection = rooms;
    static const String roomMembersCollection = roomMembers;
  static const String usersCollection = users;
  static const String debatesCollection = debates;
  static const String votesCollection = votes;
  static const String commentsCollection = comments;
  static const String notificationsCollection = notifications;
  static const String messagesCollection = messages;
  static const String badgesCollection = badges;
  static const String reportsCollection = reports;
  static const String categoriesCollection = categories;
  static const String savedDebatesCollection = saves;

  // Realtime channels
  static String debateChannel(String debateId) =>
      'databases.$databaseId.collections.$debates.documents.$debateId';

  static String messagesChannel() =>
      'databases.$databaseId.collections.$messages.documents';

  static String typingStatusChannel() =>
      'databases.$databaseId.collections.$typingStatus.documents';

  static String notificationsChannel() =>
      'databases.$databaseId.collections.$notifications.documents';
}
