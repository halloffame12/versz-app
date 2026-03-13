import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../core/services/appwrite_service.dart';
import '../models/comment.dart';
import '../core/constants/appwrite_constants.dart';
import 'package:appwrite/appwrite.dart';

final commentProvider = StateNotifierProvider.family<CommentNotifier, CommentState, String>((ref, debateId) {
  return CommentNotifier(AppwriteService(), debateId);
});

class CommentState {
  final List<Comment> comments;
  final bool isLoading;
  final String? error;

  CommentState({
    this.comments = const [],
    this.isLoading = false,
    this.error,
  });

  CommentState copyWith({
    List<Comment>? comments,
    bool? isLoading,
    String? error,
  }) {
    return CommentState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class CommentNotifier extends StateNotifier<CommentState> {
  final AppwriteService _appwrite;
  final String _debateId;

  CommentNotifier(this._appwrite, this._debateId) : super(CommentState());

  Future<void> fetchComments() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.commentsCollection,
        queries: [
          Query.equal('debateId', _debateId),
          Query.orderAsc('\$createdAt'),
          Query.limit(100),
        ],
      );

      final comments = response.documents.map((doc) => Comment.fromMap(doc.data)).toList();
      state = state.copyWith(comments: _organizeComments(comments), isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  List<Comment> _organizeComments(List<Comment> flatComments) {
    // For now, return flat list. Nested logic can be added later if needed.
    return flatComments;
  }

  Future<void> postComment(String text, {String? parentId, String? side}) async {
    try {
      final user = await _appwrite.account.get();
      String username = user.name.isNotEmpty ? user.name : user.$id;
      String? userAvatar;
      try {
        final profile = await _appwrite.databases.getDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.usersCollection,
          documentId: user.$id,
        );
        username = (profile.data['username'] ?? profile.data['displayName'] ?? username).toString();
        userAvatar = profile.data['avatar']?.toString();
      } catch (_) {
        // Keep fallback identity from account object.
      }
      
      // Get parent comment's reply count if replying to a comment
      if (parentId != null) {
        try {
          final parentComment = await _appwrite.databases.getDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.commentsCollection,
            documentId: parentId,
          );
          int replyCount = parentComment.data['replyCount'] ?? 0;
          await _appwrite.databases.updateDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.commentsCollection,
            documentId: parentId,
            data: {'replyCount': replyCount + 1},
          );
        } catch (e) {
          // Parent not found
        }
      }
      
      await _appwrite.databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.commentsCollection,
        documentId: ID.unique(),
        data: {
          'debateId': _debateId,
          'userId': user.$id,
          'username': username,
          'userAvatar': userAvatar,
          'content': text,
          'side': side,
          'parentId': parentId,
          'upvotes': 0,
          'downvotes': 0,
          'replyCount': 0,
          'isDeleted': false,
          'isEdited': false,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
      await fetchComments();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> editComment(String commentId, String newText) async {
    try {
      await _appwrite.databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.commentsCollection,
        documentId: commentId,
        data: {
          'content': newText,
          'isEdited': true,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
      await fetchComments();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      // Get the comment first to check if it has a parent
      final comment = await _appwrite.databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.commentsCollection,
        documentId: commentId,
      );

      // If this is a reply, decrement parent's reply count
      final parentId = comment.data['parentId'];
      if (parentId != null) {
        try {
          final parentComment = await _appwrite.databases.getDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.commentsCollection,
            documentId: parentId,
          );
          int replyCount = parentComment.data['replyCount'] ?? 0;
          await _appwrite.databases.updateDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.commentsCollection,
            documentId: parentId,
            data: {'replyCount': max(0, replyCount - 1)},
          );
        } catch (e) {
          // Parent not found, continue with deletion
        }
      }

      // Delete the comment
      await _appwrite.databases.deleteDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.commentsCollection,
        documentId: commentId,
      );
      
      await fetchComments();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
