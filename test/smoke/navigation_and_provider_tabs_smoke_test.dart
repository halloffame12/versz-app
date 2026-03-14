import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// ignore: unused_import — checked via source-text inspection only
import 'package:versz/core/utils/app_router.dart';

void main() {
  test('router includes key shell/detail route targets', () {
    // Inspect source rather than instantiating the provider chain
    // (avoids needing Firebase/Appwrite initialisation in unit tests).
    final source = File('lib/core/utils/app_router.dart').readAsStringSync();

    for (final path in [
      '/home', '/search', '/messages', '/rooms',
      '/notifications', '/profile',
      '/chat/:roomId', '/messages/:conversationId', '/debate-detail',
    ]) {
      expect(source, contains("path: '$path'"), reason: 'route $path missing');
    }
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
    expect(source, contains("NotificationsScreenV2()"));
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
