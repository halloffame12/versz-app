import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../core/utils/url_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeShell extends ConsumerStatefulWidget {
final Widget child;
const HomeShell({super.key, required this.child});

@override
ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> with TickerProviderStateMixin {
late AnimationController _createPulseController;
late Animation<double> _createPulse;
late AnimationController _badgeWobbleController;
late Animation<double> _badgeWobble;
int _prevUnread = 0;

bool get _isDark => Theme.of(context).brightness == Brightness.dark;
Color get _bg => AppColors.backgroundColor(_isDark);
Color get _card => AppColors.cardBackground(_isDark);
Color get _border => AppColors.borderColor(_isDark);
Color get _text => AppColors.textColor(_isDark);
Color get _muted => AppColors.mutedTextColor(_isDark);

@override
void initState() {
  super.initState();
  _createPulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);
  _createPulse = Tween<double>(begin: 1.0, end: 1.07).animate(
    CurvedAnimation(parent: _createPulseController, curve: Curves.easeInOut),
  );
  _badgeWobbleController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  _badgeWobble = Tween<double>(begin: 0, end: 1).animate(
    CurvedAnimation(parent: _badgeWobbleController, curve: Curves.elasticIn),
  );
}

@override
void dispose() {
  _createPulseController.dispose();
  _badgeWobbleController.dispose();
  super.dispose();
}

int _getCurrentTabIndex() {
  final location = GoRouterState.of(context).uri.path;
  if (location.startsWith('/home')) return 0;
  if (location.startsWith('/search')) return 1;
  if (location.startsWith('/create') || location.startsWith('/create-debate')) return 2;
  if (location.startsWith('/messages')) return 3;
  if (location.startsWith('/profile')) return 4;
  return 0;
}

void _onTabTapped(int index) {
  HapticFeedback.selectionClick();
  switch (index) {
    case 0: context.go('/home'); break;
    case 1: context.go('/search'); break;
    case 2: context.go('/create'); break;
    case 3: context.go('/messages'); break;
    case 4: context.go('/profile'); break;
  }
}

Color _tabColor(int index) {
  switch (index) {
    case 0: return AppColors.accentPurple;      // Home - Purple
    case 1: return AppColors.accentIndigo;      // Search - Indigo
    case 2: return AppColors.accentCyan;        // Create - Cyan
    case 3: return AppColors.accentCyan;        // Messages - Cyan
    case 4: return AppColors.accentPurple;      // Profile - Purple
    default: return AppColors.accentPurple;
  }
}

@override
Widget build(BuildContext context) {
  final currentIndex = _getCurrentTabIndex();
  final unread = ref.watch(notificationProvider).unreadCount;

  // wobble badge on new notification
  if (unread != _prevUnread && unread > _prevUnread) {
    _badgeWobbleController.forward(from: 0);
  }
  _prevUnread = unread;

  return Scaffold(
    extendBody: true,
    drawer: _buildUtilityDrawer(),
    body: widget.child,
    bottomNavigationBar: _buildCustomNavBar(currentIndex, unread),
  );
}

Widget _buildCustomNavBar(int currentIndex, int unread) {
  final bottomPad = MediaQuery.of(context).padding.bottom;
  final navBg = _isDark ? const Color(0xE8101523) : AppColors.white.withValues(alpha: 0.94);
  return ClipRRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
height: 72 + bottomPad,
decoration: BoxDecoration(
  color: navBg,
  border: Border(top: BorderSide(color: _border, width: 1)),
),
child: Padding(
  padding: EdgeInsets.only(bottom: bottomPad),
  child: Row(
    children: [
      _navItem(0, currentIndex, Icons.home_outlined, Icons.home_filled, 'FEED'),
      _navItem(1, currentIndex, Icons.search_rounded, Icons.search_rounded, 'SEARCH'),
      _navCreateButton(),
      _navItemWithBadge(3, currentIndex, Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'CHAT', unread),
      _navItem(4, currentIndex, Icons.person_outline_rounded, Icons.person_rounded, 'ME'),
    ],
  ),
),
      ),
    ),
  );
}

Widget _navItem(int index, int currentIndex, IconData icon, IconData activeIcon, String label) {
  final isActive = currentIndex == index;
  final color = _tabColor(index);
  return Expanded(
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTabTapped(index),
      child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
  AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    width: isActive ? 24 : 0,
    height: isActive ? 3 : 0,
    margin: EdgeInsets.only(bottom: isActive ? 5 : 0),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(999),
      boxShadow: isActive
          ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6)]
          : null,
    ),
  ),
  Icon(
    isActive ? activeIcon : icon,
    size: 24,
    color: isActive ? color : _muted,
  ),
  AnimatedOpacity(
    duration: const Duration(milliseconds: 200),
    opacity: isActive ? 1.0 : 0.0,
    child: Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: color,
        ),
      ),
    ),
  ),
],
      ),
    ),
  );
}

Widget _navItemWithBadge(int index, int currentIndex, IconData icon, IconData activeIcon, String label, int badge) {
  final isActive = currentIndex == index;
  final color = _tabColor(index);
  return Expanded(
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTabTapped(index),
      child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
  AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    width: isActive ? 24 : 0,
    height: isActive ? 3 : 0,
    margin: EdgeInsets.only(bottom: isActive ? 5 : 0),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(999),
      boxShadow: isActive
          ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6)]
          : null,
    ),
  ),
  Stack(
    clipBehavior: Clip.none,
    children: [
      Icon(
        isActive ? activeIcon : icon,
        size: 24,
        color: isActive ? color : _muted,
      ),
      if (badge > 0)
        Positioned(
          right: -8,
          top: -6,
          child: AnimatedBuilder(
            animation: _badgeWobble,
            builder: (context, child) {
              final wobble = _badgeWobble.value;
              return Transform.rotate(
                angle: wobble * 0.3 * (wobble < 0.5 ? 1 : -1),
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.errorRed,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.primaryBlack, width: 1.5),
                boxShadow: [BoxShadow(color: AppColors.errorRed.withValues(alpha: 0.5), blurRadius: 6)],
              ),
              child: Text(
                badge > 99 ? '99+' : '$badge',
                style: const TextStyle(color: AppColors.white, fontSize: 8, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
    ],
  ),
  AnimatedOpacity(
    duration: const Duration(milliseconds: 200),
    opacity: isActive ? 1.0 : 0.0,
    child: Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: color,
        ),
      ),
    ),
  ),
],
      ),
    ),
  );
}

Widget _navCreateButton() {
  return Expanded(
    child: GestureDetector(
      onTap: () => _onTabTapped(2),
      child: Center(
child: AnimatedBuilder(
  animation: _createPulse,
  builder: (context, child) => Transform.scale(
    scale: _createPulse.value,
    child: child,
  ),
  child: Container(
    width: 52,
    height: 52,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primaryYellow, AppColors.accentOrange],
      ),
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: AppColors.primaryYellow.withValues(alpha: 0.45),
          blurRadius: 18,
          spreadRadius: 0,
        ),
      ],
    ),
    child: const Icon(Icons.add_rounded, color: AppColors.primaryBlack, size: 28),
  ),
),
      ),
    ),
  );
}

Drawer _buildUtilityDrawer() {
  final authState = ref.watch(authProvider);
  final user = authState.user;
  final location = GoRouterState.of(context).uri.path;
  return Drawer(
    width: MediaQuery.of(context).size.width * 0.82,
    backgroundColor: _bg,
    child: Stack(
      children: [
// Left neon strip
Positioned(
  left: 0,
  top: 0,
  bottom: 0,
  child: Container(
    width: 3,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.accentTeal, AppColors.primaryYellow, AppColors.accentBlue],
      ),
    ),
  ),
),
SafeArea(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // User header
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryYellow, width: 1.5),
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: _card,
                backgroundImage: isValidNetworkUrl(user?.avatarUrl)
                    ? CachedNetworkImageProvider(user!.avatarUrl!)
                    : null,
                child: user?.avatarUrl == null
                    ? Icon(Icons.person, color: _muted, size: 22)
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? 'Versz User',
                    style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '@${user?.username ?? 'user'}',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryYellow),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'PICK A SIDE. BUILD YOUR STREAK.',
          style: AppTextStyles.bodySmall.copyWith(
            color: _muted,
            letterSpacing: 1.2,
            fontSize: 10,
          ),
        ),
      ),
      const SizedBox(height: 20),
      Divider(color: _border),
      const SizedBox(height: 8),

      // Nav items
      Expanded(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            _drawerItem(Icons.home_filled, 'Feed', '/home', AppColors.primaryYellow, location),
            _drawerItem(Icons.search_rounded, 'Search', '/search', AppColors.accentBlue, location),
            _drawerItem(Icons.groups_2_rounded, 'Communities', '/rooms', AppColors.accentTeal, location),
            _drawerItem(Icons.emoji_events_rounded, 'Leaderboard', '/leaderboard', AppColors.accentOrange, location),
            _drawerItem(Icons.people_alt_rounded, 'Connections', '/connections', AppColors.accentBlue, location),
            _drawerItem(Icons.notifications_rounded, 'Notifications', '/notifications', AppColors.primaryYellow, location),
            _drawerItem(Icons.settings_rounded, 'Settings', '/settings', AppColors.textMuted, location),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Text(
          'VERSZ v1.0',
          style: AppTextStyles.bodySmall.copyWith(color: _muted, fontSize: 10, letterSpacing: 1.5),
        ),
      ),
    ],
  ),
),
      ],
    ),
  );
}

Widget _drawerItem(IconData icon, String label, String route, Color color, String currentLocation) {
  final isActive = currentLocation.startsWith(route);
  final isShellRoute = ['/home', '/search', '/create', '/messages', '/rooms', '/notifications', '/profile'].contains(route);
  
  return Container(
    margin: const EdgeInsets.only(bottom: 4),
    decoration: BoxDecoration(
      color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      border: isActive ? Border.all(color: color.withValues(alpha: 0.25), width: 1) : null,
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: Icon(icon, color: isActive ? color : _muted, size: 22),
      title: Text(
label,
style: AppTextStyles.bodyMedium.copyWith(
  color: isActive ? _text : AppColors.textSecondary,
  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
),
      ),
      onTap: () {
        Navigator.of(context).pop();
        // Use go() for shell routes, push() for detail routes
        if (isShellRoute) {
          context.go(route);
        } else {
          context.push(route);
        }
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      dense: true,
    ),
  );
}
}
