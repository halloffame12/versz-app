import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/auth/otp_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/auth_callback_screen.dart';
import '../../screens/auth/onboarding_username_screen.dart';
import '../../screens/auth/onboarding_interests_screen.dart';
import '../../screens/main/home_shell.dart';
import '../../screens/main/home_screen_v2.dart';
import '../../screens/main/search_screen.dart';
import '../../screens/main/rooms_screen.dart';
import '../../screens/main/notifications_screen_v2.dart';
import '../../screens/main/leaderboard_screen_v2.dart';
import '../../screens/main/chat_detail_screen.dart';
import '../../screens/messages/conversations_screen.dart';
import '../../screens/messages/direct_message_screen.dart';
import '../../screens/profile/profile_screen_v2.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../screens/settings/settings_screen_v2.dart';
import '../../screens/settings/about_screen.dart';
import '../../screens/settings/privacy_policy_screen.dart';
import '../../screens/settings/terms_screen.dart';
import '../../screens/debate/debate_detail_screen_v2.dart';
import '../../screens/debate/create_debate_screen_v2.dart';
import '../../screens/rooms/room_members_screen_v2.dart';
import '../../screens/connections/connections_list_screen_v2.dart';
import '../../screens/connections/pending_connections_screen.dart';
import '../../models/debate.dart';
import '../../models/room.dart';
import '../../models/conversation.dart';

/// ChangeNotifier that triggers whenever the auth state stream emits.
/// Used as GoRouter's refreshListenable so the router re-evaluates redirects
/// every time auth state changes (login, logout, etc.).
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Riverpod-connected GoRouter. Reacts to [authProvider] state changes via
/// [refreshListenable], so logout/login always triggers route re-evaluation.
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.read(authProvider.notifier);

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: _GoRouterRefreshStream(authNotifier.stream),
    redirect: (context, state) async {
      final authState = ref.read(authProvider);
      final path = state.matchedLocation;

      const authRoutes = {'/login', '/signup', '/otp', '/forgot', '/auth/success', '/auth/failure'};
      const onboardingRoutes = {'/onboarding/username', '/onboarding/interests'};

      final isAuthRoute = authRoutes.contains(path);
      final isOnboardingRoute = onboardingRoutes.contains(path);

      // While auth is initialising, stay on splash so we don't flash login screen.
      if (authState.isLoading) {
        return path == '/' ? null : '/';
      }

      // ===== USER NOT LOGGED IN =====
      if (!authState.isLoggedIn) {
        if (isOnboardingRoute) return '/signup';
        if (path == '/' || isAuthRoute) return null;
        return '/login';
      }

      // ===== USER IS LOGGED IN =====
      final userId = authState.user?.id ?? '';
      final prefs = await SharedPreferences.getInstance();
      final onboardingDone = prefs.getBool('onboardingComplete_$userId') ?? false;
      final onboardingRequired = prefs.getBool('onboardingRequired_$userId') ?? false;

      // Returning user: skip auth/onboarding screens.
      if (!onboardingRequired || onboardingDone) {
        if (isAuthRoute || isOnboardingRoute || path == '/') return '/home';
        return null;
      }

      // Fresh signup: drive through onboarding until complete.
      if (!onboardingDone) {
        if (isOnboardingRoute) return null;
        return '/onboarding/username';
      }

      return null;
    },
    routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) => const OtpScreen(),
    ),
    GoRoute(
      path: '/forgot',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/auth/success',
      builder: (context, state) => const AuthCallbackScreen(isSuccess: true),
    ),
    GoRoute(
      path: '/auth/failure',
      builder: (context, state) => const AuthCallbackScreen(isSuccess: false),
    ),
    GoRoute(
      path: '/onboarding/username',
      builder: (context, state) => const OnboardingUsernameScreen(),
    ),
    GoRoute(
      path: '/onboarding/interests',
      builder: (context, state) {
        final username = state.extra as String?;
        return OnboardingInterestsScreen(username: username ?? 'user');
      },
    ),
    GoRoute(
      path: '/debate-detail',
      builder: (context, state) {
        final debate = state.extra as Debate;
        return DebateDetailScreenV2(debate: debate);
      },
    ),
    GoRoute(
      path: '/create-debate',
      builder: (context, state) => const CreateDebateScreenV2(),
    ),
    GoRoute(
      path: '/profile/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId'] ?? 'unknown';
        return ProfileScreenV2(userId: userId);
      },
    ),
    GoRoute(
      path: '/chat/:roomId',
      builder: (context, state) {
        final room = state.extra as Room;
        return ChatDetailScreen(room: room);
      },
    ),
    GoRoute(
      path: '/messages/:conversationId',
      builder: (context, state) {
        final conversation = state.extra as Conversation;
        return DirectMessageScreen(conversation: conversation);
      },
    ),
    GoRoute(
      path: '/rooms/:roomId/members',
      builder: (context, state) {
        final room = state.extra as Room;
        return RoomMembersScreenV2(room: room);
      },
    ),
    GoRoute(
      path: '/leaderboard',
      builder: (context, state) => const LeaderboardScreenV2(),
    ),
    GoRoute(
      path: '/connections',
      builder: (context, state) => const ConnectionsListScreenV2(),
    ),
    GoRoute(
      path: '/connections/pending',
      builder: (context, state) => const PendingConnectionsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreenV2(),
    ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsScreen(),
      ),
    ShellRoute(
      builder: (context, state, child) => HomeShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreenV2(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/create',
          builder: (context, state) => const CreateDebateScreenV2(),
        ),
        GoRoute(
          path: '/messages',
          builder: (context, state) => const ConversationsScreen(),
        ),
        GoRoute(
          path: '/rooms',
          builder: (context, state) => const RoomsScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreenV2(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreenV2(userId: 'current'),
        ),
      ],
    ),
  ],
  );

  return router;
});
