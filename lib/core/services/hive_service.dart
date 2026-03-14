// Local storage service - Removed Hive dependency
// Using Riverpod state management for app state persistence
// For persistent user data, use Appwrite database instead

class HiveService {
  // Deprecated: Use Riverpod providers and Appwrite database instead
  static const String categoryBoxName = 'categories';
  static const String userBoxName = 'user_data';
  static const String settingsBoxName = 'settings';

  Future<void> init() async {
    // No-op: persistence handled by Riverpod state management
  }

  Future<void> clearAll() async {
    // No-op: state managed by Riverpod
  }
}
