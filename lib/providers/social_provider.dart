import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/appwrite_service.dart';
import '../core/constants/appwrite_constants.dart';
import 'package:appwrite/appwrite.dart';

final socialProvider = Provider((ref) => SocialNotifier(AppwriteService()));

class SocialNotifier {
  final AppwriteService _appwrite;

  SocialNotifier(this._appwrite);

  Future<void> followUser(String targetUserId) async {
    try {
      final user = await _appwrite.account.get();
      try {
        await _appwrite.databases.createDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.connections,
          documentId: ID.unique(),
          data: {
            'requesterId': user.$id,
            'receiverId': targetUserId,
            'status': 'follow',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
        );
      } catch (_) {
        rethrow;
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> unfollowUser(String targetUserId) async {
    try {
      final user = await _appwrite.account.get();
      try {
        final response = await _appwrite.databases.listDocuments(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.connections,
          queries: [
            Query.equal('requesterId', user.$id),
            Query.equal('receiverId', targetUserId),
            Query.limit(50),
          ],
        );

        for (final doc in response.documents) {
          await _appwrite.databases.deleteDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.connections,
            documentId: doc.$id,
          );
        }
      } catch (_) {
        rethrow;
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<bool> checkIsFollowing(String targetUserId) async {
    try {
      final user = await _appwrite.account.get();
      try {
        final response = await _appwrite.databases.listDocuments(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.connections,
          queries: [
            Query.equal('requesterId', user.$id),
            Query.equal('receiverId', targetUserId),
            Query.equal('status', ['follow', 'connected']),
            Query.limit(1),
          ],
        );
        return response.documents.isNotEmpty;
      } catch (_) {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
