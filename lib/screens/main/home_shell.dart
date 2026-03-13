import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/connection_provider.dart';
import '../../providers/notification_provider.dart';

class HomeShell extends ConsumerStatefulWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(connectionProvider.notifier).fetchPendingRequests();
      ref.read(notificationProvider.notifier).fetchUserNotifications();
    });
  }

  int _getCurrentTabIndex() {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/rooms')) return 2;
    if (location.startsWith('/notifications')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTabTapped(int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        context.go('/rooms');
        break;
      case 3:
        context.go('/notifications');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentTabIndex();
    final pendingCount = ref.watch(pendingConnectionCountProvider);
    final unreadCount = ref.watch(notificationProvider).unreadCount;
    final showNotifBadge = pendingCount > 0 || unreadCount > 0;

    return Scaffold(
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 18),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primary, width: 1.6),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.12),
                blurRadius: 0,
                offset: const Offset(4, 4),
              ),
            ],
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: _onTabTapped,
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconSize: 22,
              selectedFontSize: 0,
              unselectedFontSize: 0,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textMuted,
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              items: [
                _buildNavItem(Icons.home_filled, Icons.home_outlined, 0 == currentIndex),
                _buildNavItem(Icons.search, Icons.search, 1 == currentIndex),
                _buildNavItem(Icons.groups_rounded, Icons.groups_outlined, 2 == currentIndex),
                _buildNavItem(
                  Icons.notifications_rounded,
                  Icons.notifications_outlined,
                  3 == currentIndex,
                  showBadge: showNotifBadge,
                ),
                _buildNavItem(Icons.person_rounded, Icons.person_outline, 4 == currentIndex),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData activeIcon,
    IconData icon,
    bool isSelected, {
    bool showBadge = false,
  }) {
    return BottomNavigationBarItem(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(isSelected ? activeIcon : icon),
          if (showBadge)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      label: '',
    );
  }
}
