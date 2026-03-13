import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';

import '../core/constants/appwrite_constants.dart';
import '../core/services/appwrite_service.dart';

final viewsProvider = Provider<ViewsNotifier>((ref) {
  return ViewsNotifier(AppwriteService());
});

class ViewsNotifier {
  final AppwriteService _appwrite;

  ViewsNotifier(this._appwrite);

  Future<void> trackDebateView(String debateId) async {
    try {
      final user = await _appwrite.account.get();

      // Ignore duplicate errors if unique index exists.
      try {
        await _appwrite.databases.createDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.debateViews,
          documentId: ID.unique(),
          data: {
            'debate_id': debateId,
            'viewer_id': user.$id,
          },
        );
      } catch (_) {
        // Already viewed or collection constraints differ; safe to ignore.
      }

      // Best effort counter update.
      try {
        final debate = await _appwrite.databases.getDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.debatesCollection,
          documentId: debateId,
        );
        final current = (debate.data['view_count'] ?? 0) as int;
        await _appwrite.databases.updateDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.debatesCollection,
          documentId: debateId,
          data: {'view_count': current + 1},
        );
      } catch (_) {
        // Some deployments may not include view_count yet.
      }
    } catch (_) {
      // Non-blocking analytics.
    }
  }
}
