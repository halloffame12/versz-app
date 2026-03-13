import 'package:go_router/go_router.dart';
import '../../screens/auth/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/auth/otp_screen.dart';
import '../../screens/auth/onboarding_username_screen.dart';
import '../../screens/auth/onboarding_interests_screen.dart';
import '../../screens/main/home_shell.dart';
import '../../screens/main/home_screen.dart';
import '../../screens/main/search_screen.dart';
import '../../screens/main/rooms_screen.dart';
import '../../screens/main/chat_detail_screen.dart';
import '../../screens/main/notifications_screen.dart';
import '../../screens/main/leaderboard_screen.dart';
import '../../screens/messages/conversations_screen.dart';
import '../../screens/messages/direct_message_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/debate/debate_detail_screen.dart';
import '../../screens/debate/create_debate_screen.dart';
import '../../screens/rooms/room_members_screen.dart';
import '../../screens/connections/connections_list_screen.dart';
import '../../screens/connections/pending_connections_screen.dart';
import '../../models/debate.dart';
import '../../models/room.dart';
import '../../models/conversation.dart';

final appRouter = GoRouter(
  initialLocation: '/',
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
        return DebateDetailScreen(debate: debate);
      },
    ),
    GoRoute(
      path: '/create-debate',
      builder: (context, state) => const CreateDebateScreen(),
    ),
    GoRoute(
      path: '/chat/:roomId',
      builder: (context, state) {
        final room = state.extra as Room;
        return ChatDetailScreen(room: room);
      },
    ),
    GoRoute(
      path: '/messages',
      builder: (context, state) => const ConversationsScreen(),
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
        return RoomMembersScreen(room: room);
      },
    ),
    GoRoute(
      path: '/leaderboard',
      builder: (context, state) => const LeaderboardScreen(),
    ),
    GoRoute(
      path: '/connections',
      builder: (context, state) => const ConnectionsListScreen(),
    ),
    GoRoute(
      path: '/connections/pending',
      builder: (context, state) => const PendingConnectionsScreen(),
    ),
    GoRoute(
      path: '/profile/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId'];
        return ProfileScreen(userId: userId);
      },
    ),
    ShellRoute(
      builder: (context, state, child) => HomeShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/rooms',
          builder: (context, state) => const RoomsScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);
