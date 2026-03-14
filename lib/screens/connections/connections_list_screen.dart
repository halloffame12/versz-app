import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/url_utils.dart';
import '../../providers/connection_provider.dart';

class ConnectionsListScreen extends ConsumerStatefulWidget {
  const ConnectionsListScreen({super.key});

  @override
  ConsumerState<ConnectionsListScreen> createState() => _ConnectionsListScreenState();
}

class _ConnectionsListScreenState extends ConsumerState<ConnectionsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(connectionProvider.notifier).fetchNetworkOverview());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(connectionProvider);
    final q = _searchController.text.trim().toLowerCase();

    List<dynamic> filter(List<dynamic> list) {
      if (q.isEmpty) return list;
      return list.where((u) =>
        u.displayName.toLowerCase().contains(q) || u.username.toLowerCase().contains(q)
      ).toList();
    }

    final connected = filter(state.connectedUsers);
    final following = filter(state.following);
    final followers = filter(state.followers);
    final suggestions = filter(state.suggestions);

    final users = switch (_tabIndex) {
      0 => connected,
      1 => following,
      2 => followers,
      _ => suggestions,
    };

    final tabs = [
      ('NETWORK', connected.length, AppColors.accentTeal),
      ('FOLLOWING', following.length, AppColors.primaryYellow),
      ('FOLLOWERS', followers.length, AppColors.accentBlue),
      ('SUGGESTED', suggestions.length, AppColors.accentOrange),
    ];

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'NETWORK',
          style: AppTextStyles.labelLarge.copyWith(letterSpacing: 2, fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: const Icon(Icons.mark_email_unread_outlined, color: AppColors.accentBlue, size: 18),
                ),
                onPressed: () => context.push('/connections/pending'),
              ),
              if (state.receivedPendingUsers.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.primaryBlack, width: 1.5),
                    ),
                    child: Text(
                      '${state.receivedPendingUsers.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Stats row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                _statBadge('${state.connectedUsers.length}', 'connected', AppColors.accentTeal),
                const SizedBox(width: 8),
                _statBadge('${state.following.length}', 'following', AppColors.primaryYellow),
                const SizedBox(width: 8),
                _statBadge('${state.followers.length}', 'followers', AppColors.accentBlue),
              ],
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.darkCardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.darkText),
                      decoration: InputDecoration(
                        hintText: 'Search people...',
                        hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: tabs.asMap().entries.map((e) {
                  final i = e.key;
                  final (label, count, color) = e.value;
                  final selected = _tabIndex == i;
                  return Padding(
                    padding: EdgeInsets.only(right: i < tabs.length - 1 ? 8 : 0),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _tabIndex = i);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? color.withValues(alpha: 0.15) : AppColors.darkCardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? color.withValues(alpha: 0.5) : AppColors.darkBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              label,
                              style: AppTextStyles.labelSmall.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                                color: selected ? color : AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: selected ? color.withValues(alpha: 0.25) : AppColors.darkSurface,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: selected ? color : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // List
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accentTeal, strokeWidth: 2),
                  )
                : users.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: AppColors.accentTeal,
                        backgroundColor: AppColors.darkCardBg,
                        onRefresh: () => ref.read(connectionProvider.notifier).fetchNetworkOverview(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: users.length,
                          itemBuilder: (context, index) => _buildUserCard(users[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14)),
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildUserCard(dynamic user) {
    final tabColors = [AppColors.accentTeal, AppColors.primaryYellow, AppColors.accentBlue, AppColors.accentOrange];
    final cardColor = tabColors[_tabIndex];
    return GestureDetector(
      onTap: () => context.push('/profile/${user.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.darkCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: cardColor.withValues(alpha: 0.6), width: 1.5),
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.darkSurface,
                backgroundImage: isValidNetworkUrl(user.avatarUrl)
                    ? CachedNetworkImageProvider(user.avatarUrl!)
                    : null,
                child: !isValidNetworkUrl(user.avatarUrl)
                    ? Text(
                        user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                        style: TextStyle(color: cardColor, fontWeight: FontWeight.w900, fontSize: 16),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName.isEmpty ? user.username : user.displayName,
                    style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '@${user.username}',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildActionButton(user),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(dynamic user) {
    switch (_tabIndex) {
      case 0:
        return _neonButton('MSG', AppColors.accentTeal, () => context.push('/messages'));
      case 1:
        return _neonButton('UNFOLLOW', AppColors.errorRed, () => ref.read(connectionProvider.notifier).unfollow(user.id));
      case 2:
        return _neonButton('FOLLOW', AppColors.accentBlue, () => ref.read(connectionProvider.notifier).follow(user.id));
      default:
        return _neonButton('FOLLOW', AppColors.accentOrange, () => ref.read(connectionProvider.notifier).follow(user.id));
    }
  }

  Widget _neonButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final emptyMessages = [
      'No connections yet — start debating!',
      'Not following anyone yet',
      'No followers yet',
      'No suggestions right now',
    ];
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline_rounded, color: AppColors.darkBorder, size: 48),
            const SizedBox(height: 16),
            Text(
              emptyMessages[_tabIndex],
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
