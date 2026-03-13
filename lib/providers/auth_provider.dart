import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import '../core/services/appwrite_service.dart';
import '../core/services/secure_storage_service.dart';
import '../core/utils/error_mapper.dart';
import '../models/user_account.dart';
import '../core/constants/appwrite_constants.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    AppwriteService(),
    SecureStorageService(),
  );
});

enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

class AuthState {
  final AuthStatus status;
  final UserAccount? user;
  final String? errorMessage;
  final bool needsOnboarding;

  AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.needsOnboarding = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserAccount? user,
    String? errorMessage,
    bool? needsOnboarding,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
      needsOnboarding: needsOnboarding ?? this.needsOnboarding,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AppwriteService _appwrite;
  final SecureStorageService _secureStorage;

  AuthNotifier(this._appwrite, this._secureStorage) : super(AuthState());

  Future<void> checkSession() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _appwrite.account.getSession(sessionId: 'current');
      await _fetchUserProfile();
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _appwrite.account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      await _fetchUserProfile();
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: ErrorMapper.map(e),
      );
    }
  }

  Future<void> signup(String email, String password, String name) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final userId = ID.unique();
      
      // Create Appwrite account
      await _appwrite.account.create(
        userId: userId,
        email: email,
        password: password,
        name: name,
      );
      
      // Create user profile document in database
      await _appwrite.databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: userId,
        data: {
          'username': name.toLowerCase().replaceAll(' ', '_'),
          'displayName': name,
          'email': email,
          'xp': 0,
          'followersCount': 0,
          'followingCount': 0,
          'connectionsCount': 0,
          'isPrivate': false,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
      
      // Auto-login after signup
      await login(email, password);
      await _secureStorage.setOnboardingComplete(false);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: ErrorMapper.map(e),
      );
    }
  }

  Future<void> logout() async {
    try {
      await _appwrite.account.deleteSession(sessionId: 'current');
      await _secureStorage.clearAuthData();
      state = AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: ErrorMapper.map(e),
      );
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final user = await _appwrite.account.get();
      try {
        final profileDoc = await _appwrite.databases.getDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.usersCollection,
          documentId: user.$id,
        );
        
        final onboardingComplete = await _secureStorage.isOnboardingComplete();
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: UserAccount.fromMap(profileDoc.data),
          needsOnboarding: !onboardingComplete,
        );
      } catch (e) {
        // Profile doesn't exist, create it with default values
        await _appwrite.databases.createDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.usersCollection,
          documentId: user.$id,
          data: {
            'username': (user.name.isEmpty ? user.email : user.name).toLowerCase().replaceAll(' ', '_'),
            'displayName': user.name.isEmpty ? user.email : user.name,
            'email': user.email,
            'xp': 0,
            'followersCount': 0,
            'followingCount': 0,
            'connectionsCount': 0,
            'isPrivate': false,
            'createdAt': DateTime.now().toIso8601String(),
          },
        );
        
        // Fetch the newly created profile
        final profileDoc = await _appwrite.databases.getDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.usersCollection,
          documentId: user.$id,
        );
        
        final onboardingComplete = await _secureStorage.isOnboardingComplete();
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: UserAccount.fromMap(profileDoc.data),
          needsOnboarding: !onboardingComplete,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: ErrorMapper.map(e),
      );
    }
  }

  Future<bool> isUsernameAvailable(String username) async {
    try {
      final normalized = username.trim().toLowerCase();
      if (normalized.isEmpty) return false;

      final currentUserId = state.user?.id;
      final response = await _appwrite.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        queries: [Query.equal('username', normalized), Query.limit(1)],
      );

      if (response.documents.isEmpty) return true;
      if (currentUserId == null) return false;

        return response.documents.first.$id == currentUserId;
    } catch (_) {
      return false;
    }
  }

  Future<void> completeOnboarding({
    required String username,
    required List<String> interests,
  }) async {
    try {
      final account = await _appwrite.account.get();
      await _appwrite.databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: account.$id,
        data: {
          'username': username.trim().toLowerCase(),
        },
      );

      await _secureStorage.saveSelectedInterests(interests);
      await _secureStorage.setOnboardingComplete(true);
      await _fetchUserProfile();
      state = state.copyWith(needsOnboarding: false);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: ErrorMapper.map(e),
      );
    }
  }
}
