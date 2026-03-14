import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/notification_service.dart';
import '../core/constants/appwrite_constants.dart';
import '../models/user_account.dart';
import 'core_providers.dart';

/// Auth state model
class AuthState {
  static const Object _unset = Object();

  final bool isLoading;
  final bool isLoggedIn;
  final UserAccount? user;
  final String? error;
  final String? email;
  final String? pendingOtpEmail;
  final String? pendingOtpUserId;

  const AuthState({
    this.isLoading = false,
    this.isLoggedIn = false,
    this.user,
    this.error,
    this.email,
    this.pendingOtpEmail,
    this.pendingOtpUserId,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    UserAccount? user,
    Object? error = _unset,
    String? email,
    Object? pendingOtpEmail = _unset,
    Object? pendingOtpUserId = _unset,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      user: user ?? this.user,
      error: identical(error, _unset) ? this.error : error as String?,
      email: email ?? this.email,
      pendingOtpEmail: identical(pendingOtpEmail, _unset)
          ? this.pendingOtpEmail
          : pendingOtpEmail as String?,
      pendingOtpUserId: identical(pendingOtpUserId, _unset)
          ? this.pendingOtpUserId
          : pendingOtpUserId as String?,
    );
  }
}

/// Auth State Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final Account _account;
  final Databases _databases;
  final NotificationService _notificationService = NotificationService();

  AuthNotifier(this._account, this._databases)
      : super(const AuthState());

  Future<void> _setOnboardingRequired(String userId, bool required) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingRequired_$userId', required);
  }

  /// Check if user is already logged in (on app start)
  Future<void> checkAuthStatus() async {
    try {
      state = state.copyWith(isLoading: true);
      final session = await _account.getSession(sessionId: 'current');
      if (session.$id.isNotEmpty) {
        final userId = session.userId;
        await _fetchUserProfile(userId);
        await _syncFcmToken(userId);
        state = state.copyWith(
          isLoggedIn: true,
          isLoading: false,
          error: null,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, isLoggedIn: false);
    }
  }

  /// Fetch user profile from database
  Future<void> _fetchUserProfile(String userId) async {
    try {
      final response = await _databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.users,
        documentId: userId,
      );
      final user = UserAccount.fromMap(response.data);
      state = state.copyWith(user: user);
    } catch (e) {
      // If user document doesn't exist yet, create a minimal profile so ID is available
      final minimalUser = UserAccount(
        id: userId,
        displayName: 'User',
        username: 'user_$userId',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      state = state.copyWith(user: minimalUser);
    }
  }

  /// Login with email & password
  Future<void> login(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );

      final session = await _account.getSession(sessionId: 'current');
      await _fetchUserProfile(session.userId);
      await _syncFcmToken(session.userId);
      await _setOnboardingRequired(session.userId, false);

      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,
        error: null,
        email: email,
        pendingOtpEmail: null,
        pendingOtpUserId: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Create OTP (magic link)
  Future<void> createOTP(String email) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final token = await _account.createEmailToken(
        userId: ID.unique(),
        email: email,
      );

      state = state.copyWith(
        isLoading: false,
        pendingOtpEmail: email,
        pendingOtpUserId: token.userId,
        email: email,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send OTP: ${e.toString()}',
      );
    }
  }

  /// Verify OTP and create session
  Future<void> verifyOTP(String otp) async {
    if (state.pendingOtpEmail == null || state.pendingOtpUserId == null) {
      state = state.copyWith(error: 'No email pending OTP verification');
      return;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      // Check if a session already exists to prevent "user_session_already_exists" error
      try {
        final activeSession = await _account.getSession(sessionId: 'current');
        // Session exists, just fetch user profile without creating new session
        await _fetchUserProfile(activeSession.userId);
        await _syncFcmToken(activeSession.userId);
        await _setOnboardingRequired(activeSession.userId, false);
        
        state = state.copyWith(
          isLoading: false,
          isLoggedIn: true,
          pendingOtpEmail: null,
          pendingOtpUserId: null,
          error: null,
        );
        return;
      } catch (_) {
        // No existing session, proceed with OTP verification
      }

      await _account.createSession(
        userId: state.pendingOtpUserId!,
        secret: otp,
      );

      final session = await _account.getSession(sessionId: 'current');
      await _fetchUserProfile(session.userId);
      await _syncFcmToken(session.userId);
      await _setOnboardingRequired(session.userId, false);

      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,
        pendingOtpEmail: null,
        pendingOtpUserId: null,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Invalid OTP: ${e.toString()}',
      );
    }
  }

  /// Signup new user
  Future<void> signup(
    String email,
    String password,
    String displayName, {
    String? username,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final normalizedEmail = email.trim().toLowerCase();
      final normalizedName = displayName.trim();
      if (normalizedName.length < 2) {
        state = state.copyWith(
          isLoading: false,
          error: 'Display name must be at least 2 characters.',
        );
        return;
      }
      if (!normalizedEmail.contains('@')) {
        state = state.copyWith(
          isLoading: false,
          error: 'Enter a valid email address.',
        );
        return;
      }
      if (password.length < 8) {
        state = state.copyWith(
          isLoading: false,
          error: 'Password must be at least 8 characters.',
        );
        return;
      }

      final userId = ID.unique();
      
      // Create Appwrite account
      await _account.create(
        userId: userId,
        email: normalizedEmail,
        password: password,
        name: normalizedName,
      );

      // Create user document in database
      await _databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.users,
        documentId: userId,
        data: {
          'displayName': normalizedName,
          'username': username ?? normalizedEmail.split('@')[0],
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'isOnline': true,
          'isPrivate': false,
          'messagingPrivacy': 'everyone',
          'notifPrefs': {
            'debates': true,
            'connections': true,
            'messages': true,
          },
        },
      );

      // Create session
      await _account.createEmailPasswordSession(
        email: normalizedEmail,
        password: password,
      );

      // Fetch user profile
      await _fetchUserProfile(userId);
      await _syncFcmToken(userId);
      await _setOnboardingRequired(userId, true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboardingComplete_$userId', false);

      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,
        email: normalizedEmail,
        error: null,
        pendingOtpEmail: null,
        pendingOtpUserId: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Signup failed: ${e.toString()}',
      );
    }
  }

  /// Check username availability
  Future<bool> checkUsernameAvailable(String username) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.users,
        queries: [
          Query.equal('username', username),
        ],
      );
      return result.total == 0;
    } catch (e) {
      return false;
    }
  }

  /// Set username for new user
  Future<void> setUsername(String username) async {
    if (state.user == null) return;
    
    try {
      state = state.copyWith(isLoading: true);
      
      await _databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.users,
        documentId: state.user!.id,
        data: {
          'username': username,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      final updated = state.user!.copyWith(username: username);
      state = state.copyWith(user: updated, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to set username: ${e.toString()}',
      );
    }
  }

  /// Update user profile (display name, bio, website, etc.)
  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (state.user == null) return;
    try {
      state = state.copyWith(isLoading: true);
      final updated = await _databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.users,
        documentId: state.user!.id,
        data: {
          ...data,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
      final updatedUser = UserAccount.fromMap(updated.data);
      state = state.copyWith(user: updatedUser, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Profile update failed: $e');
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _account.deleteSession(sessionId: 'current');
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(error: 'Logout failed: ${e.toString()}');
    }
  }

  /// Launch Google OAuth flow.
  Future<void> googleOAuth() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _account.createOAuth2Session(
        provider: OAuthProvider.google,
        success: 'https://versz.app/auth/success',
        failure: 'https://versz.app/auth/failure',
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Google sign-in failed: ${e.toString()}',
      );
    }
  }

  /// Send password recovery email.
  Future<void> sendPasswordRecovery(String email) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _account.createRecovery(
        email: email,
        url: 'https://versz.app/reset-password',
      );
      state = state.copyWith(isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Recovery email failed: ${e.toString()}',
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> _syncFcmToken(String userId) async {
    try {
      final token = await _notificationService.getToken();
      if (token == null || token.isEmpty) return;

      await _databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.users,
        documentId: userId,
        data: {
          'fcmToken': token,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (_) {
      // Ignore token sync failures during auth flow.
    }
  }
}

/// Providers
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final account = ref.watch(accountProvider);
  final databases = ref.watch(databasesProvider);
  return AuthNotifier(account, databases);
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoggedIn;
});

final currentUserProvider = Provider<UserAccount?>((ref) {
  return ref.watch(authProvider).user;
});

final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).error;
});
