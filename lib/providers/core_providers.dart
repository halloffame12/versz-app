import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import '../core/constants/appwrite_constants.dart';

/// Appwrite Client - singleton
final appwriteClientProvider = Provider<Client>((ref) {
  final client = Client()
    .setEndpoint(AppwriteConstants.endpoint)
    .setProject(AppwriteConstants.projectId)
    .setSelfSigned(status: true); // ⚠️ ONLY for dev. Remove for production!
  return client;
});

/// Appwrite Account — for auth operations
final accountProvider = Provider<Account>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return Account(client);
});

/// Appwrite Databases — for CRUD operations
final databasesProvider = Provider<Databases>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return Databases(client);
});

/// Appwrite Realtime — for real-time subscriptions
final realtimeProvider = Provider<Realtime>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return Realtime(client);
});

/// Appwrite Storage — for file upload/download
final storageProvider = Provider<Storage>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return Storage(client);
});

/// Health check provider — verify Appwrite connectivity
final appwriteHealthProvider = FutureProvider<bool>((ref) async {
  try {
    // Try to access account info as a connectivity test
    final account = ref.watch(accountProvider);
    await account.get();
    return true;
  } catch (e) {
    // Health check failed
    return false;
  }
});
