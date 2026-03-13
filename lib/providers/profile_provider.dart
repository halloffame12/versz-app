import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/appwrite_service.dart';
import '../models/user_account.dart';
import '../core/constants/appwrite_constants.dart';

final profileProvider = StateNotifierProvider.family<ProfileNotifier, ProfileState, String>((ref, userId) {
  return ProfileNotifier(AppwriteService(), userId);
});

class ProfileState {
  final UserAccount? profile;
  final bool isLoading;
  final String? error;

  ProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    UserAccount? profile,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final AppwriteService _appwrite;
  final String _targetUserId;

  ProfileNotifier(this._appwrite, this._targetUserId) : super(ProfileState());

  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final doc = await _appwrite.databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: _targetUserId,
      );
      state = state.copyWith(profile: UserAccount.fromMap(doc.data), isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true);
    try {
      final doc = await _appwrite.databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: _targetUserId,
        data: data,
      );
      state = state.copyWith(profile: UserAccount.fromMap(doc.data), isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
