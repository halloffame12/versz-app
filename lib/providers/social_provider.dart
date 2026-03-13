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
            'requester_id': user.$id,
            'receiver_id': targetUserId,
            'status': 'follow',
          },
        );
      } catch (_) {
        await _appwrite.databases.createDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.followsCollection,
          documentId: ID.unique(),
          data: {
            'follower_id': user.$id,
            'following_id': targetUserId,
          },
        );
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
            Query.equal('requester_id', user.$id),
            Query.equal('receiver_id', targetUserId),
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
        final response = await _appwrite.databases.listDocuments(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.followsCollection,
          queries: [
            Query.equal('follower_id', user.$id),
            Query.equal('following_id', targetUserId),
          ],
        );

        for (final doc in response.documents) {
          await _appwrite.databases.deleteDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.followsCollection,
            documentId: doc.$id,
          );
        }
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
            Query.equal('requester_id', user.$id),
            Query.equal('receiver_id', targetUserId),
            Query.equal('status', ['follow', 'connected']),
            Query.limit(1),
          ],
        );
        return response.documents.isNotEmpty;
      } catch (_) {
        final response = await _appwrite.databases.listDocuments(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.followsCollection,
          queries: [
            Query.equal('follower_id', user.$id),
            Query.equal('following_id', targetUserId),
            Query.limit(1),
          ],
        );
        return response.documents.isNotEmpty;
      }
    } catch (e) {
      return false;
    }
  }
}
