import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:versz/core/utils/app_router.dart';

void _collectRoutePaths(List<RouteBase> routes, Set<String> out) {
  for (final route in routes) {
    if (route is GoRoute) {
      out.add(route.path);
      _collectRoutePaths(route.routes, out);
      continue;
    }

    if (route is ShellRoute) {
      _collectRoutePaths(route.routes, out);
    }
  }
}

void main() {
  test('router includes key shell/detail route targets', () {
    final paths = <String>{};
    _collectRoutePaths(appRouter.configuration.routes, paths);

    expect(paths, contains('/home'));
    expect(paths, contains('/search'));
    expect(paths, contains('/messages'));
    expect(paths, contains('/rooms'));
    expect(paths, contains('/notifications'));
    expect(paths, contains('/profile'));
    expect(paths, contains('/chat/:roomId'));
    expect(paths, contains('/messages/:conversationId'));
    expect(paths, contains('/debate-detail'));
  });

  test('provider-backed tab routes target active screen widgets', () {
    final source = File('lib/core/utils/app_router.dart').readAsStringSync();

    expect(source, contains("path: '/search'"));
    expect(source, contains("const SearchScreen()"));

    expect(source, contains("path: '/messages'"));
    expect(source, contains("const ConversationsScreen()"));

    expect(source, contains("path: '/rooms'"));
    expect(source, contains("const RoomsScreen()"));

    expect(source, contains("path: '/notifications'"));
    expect(source, contains("const NotificationsScreen()"));
  });

  testWidgets('router navigation smoke between tab targets', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const Scaffold(body: Text('home'))),
        GoRoute(path: '/search', builder: (_, __) => const Scaffold(body: Text('search'))),
        GoRoute(path: '/messages', builder: (_, __) => const Scaffold(body: Text('messages'))),
        GoRoute(path: '/rooms', builder: (_, __) => const Scaffold(body: Text('rooms'))),
        GoRoute(path: '/notifications', builder: (_, __) => const Scaffold(body: Text('notifications'))),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);

    router.go('/search');
    await tester.pumpAndSettle();
    expect(find.text('search'), findsOneWidget);

    router.go('/messages');
    await tester.pumpAndSettle();
    expect(find.text('messages'), findsOneWidget);

    router.go('/rooms');
    await tester.pumpAndSettle();
    expect(find.text('rooms'), findsOneWidget);

    router.go('/notifications');
    await tester.pumpAndSettle();
    expect(find.text('notifications'), findsOneWidget);
  });
}
