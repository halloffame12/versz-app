import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/leaderboard_provider.dart';
import '../../models/user_account.dart';

class LeaderboardScreenV2 extends ConsumerStatefulWidget {
  const LeaderboardScreenV2({super.key});

  @override
  ConsumerState<LeaderboardScreenV2> createState() => _LeaderboardScreenV2State();
}

class _LeaderboardScreenV2State extends ConsumerState<LeaderboardScreenV2> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _listAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _listAnimation = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(leaderboardProvider.notifier).fetchLeaderboard(period: LeaderboardPeriod.allTime);
    });

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _listAnimation.reset();
      _listAnimation.forward();
      final period = _tabController.index == 0 ? LeaderboardPeriod.allTime : LeaderboardPeriod.weekly;
      ref.read(leaderboardProvider.notifier).fetchLeaderboard(period: period);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _listAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AppColors.backgroundColor(isDark);
    final text = AppColors.textColor(isDark);
    final muted = AppColors.mutedTextColor(isDark);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.accentCyan),
          onPressed: () => context.pop(),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.accentLight, AppColors.accentPrimary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'LEADERBOARD',
            style: AppTextStyles.headlineL.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.accentCyan,
              indicatorWeight: 3,
              labelColor: text,
              unselectedLabelColor: muted,
              tabs: const [
                Tab(text: 'ALL TIME'),
                Tab(text: 'THIS WEEK'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaderboardTab(),
          _buildLeaderboardTab(),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    final leaderState = ref.watch(leaderboardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppColors.cardBackground(isDark);
    final text = AppColors.textColor(isDark);
    final muted = AppColors.mutedTextColor(isDark);

    if (leaderState.isLoading && leaderState.entries.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentCyan, strokeWidth: 2),
      );
    }

    if (leaderState.error != null && leaderState.entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.errorRed, size: 48),
            const SizedBox(height: 12),
            Text(
              'Failed to load leaderboard',
              style: AppTextStyles.bodyM.copyWith(color: muted),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(leaderboardProvider.notifier).fetchLeaderboard(),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentIndigo),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final entries = leaderState.entries;

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events_rounded, color: AppColors.accentCyan, size: 64),
            const SizedBox(height: 16),
            Text(
              'No rankings yet',
              style: AppTextStyles.headlineS.copyWith(color: text),
            ),
            const SizedBox(height: 8),
            Text(
              'Start debating to earn XP and rank up!',
              style: AppTextStyles.bodyS.copyWith(color: muted),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.accentCyan,
      backgroundColor: cardBg,
      onRefresh: () => ref.read(leaderboardProvider.notifier).fetchLeaderboard(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final user = entries[index];
          final rank = index + 1;
          final isTopThree = rank <= 3;
          final xp = ref.read(leaderboardProvider.notifier).scoreFor(user);

          return AnimatedBuilder(
            animation: _listAnimation,
            builder: (context, _) {
              final startTime = (index * 0.1).clamp(0.0, 0.7);
              final endTime = (startTime + 0.3).clamp(0.0, 1.0);
              final animProgress = _listAnimation.value;

              double animValue;
              if (animProgress < startTime) {
                animValue = 0.0;
              } else if (animProgress > endTime) {
                animValue = 1.0;
              } else {
                animValue = (animProgress - startTime) / (endTime - startTime);
                animValue = Curves.easeOut.transform(animValue);
              }

              return Transform.translate(
                offset: Offset(0, (1 - animValue) * 50),
                child: Opacity(
                  opacity: animValue.clamp(0.0, 1.0),
                  child: _buildUserCard(user, rank, isTopThree, xp),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildUserCard(UserAccount user, int rank, bool isTopThree, int xp) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppColors.cardBackground(isDark);
    final border = AppColors.borderColor(isDark);
    final text = AppColors.textColor(isDark);
    final muted = AppColors.mutedTextColor(isDark);

    // Safe lists — only indexed when isTopThree (rank 1-3)
    const topGradients = [
      [AppColors.accentLight, AppColors.accentPrimary],
      [AppColors.accentPrimary, AppColors.accentPrimaryDark],
      [AppColors.accentPrimaryDark, AppColors.chromeGold],
    ];
    const topBorderColors = [
      AppColors.accentLight,
      AppColors.accentPrimary,
      AppColors.accentPrimaryDark,
    ];
    const medals = ['🥇', '🥈', '🥉'];

    return GestureDetector(
      onTap: () => context.push('/profile/${user.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isTopThree
              ? LinearGradient(
                  colors: topGradients[rank - 1]
                      .map((c) => c.withValues(alpha: 0.15))
                      .toList(),
                )
              : null,
          color: isTopThree ? null : cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isTopThree
                ? topBorderColors[rank - 1]
                : border,
            width: isTopThree ? 2 : 1,
          ),
          boxShadow: isTopThree
              ? [
                  BoxShadow(
                    color: topBorderColors[rank - 1].withValues(alpha: 0.3),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Rank badge — top3 shows medal, others show plain number
            SizedBox(
              width: 48,
              height: 48,
              child: isTopThree
                  ? Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: topGradients[rank - 1]),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(medals[rank - 1], style: const TextStyle(fontSize: 22)),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: border),
                      ),
                      child: Center(
                        child: Text(
                          '$rank',
                          style: AppTextStyles.headlineS.copyWith(
                            color: text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.accentIndigo.withValues(alpha: 0.3),
              backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                  ? Text(
                      user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                      style: AppTextStyles.labelM.copyWith(color: AppColors.accentCyan),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            // Name & username
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.displayName,
                          style: AppTextStyles.bodyL.copyWith(
                            fontWeight: FontWeight.w600,
                            color: text,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, color: AppColors.accentCyan, size: 14),
                      ],
                    ],
                  ),
                  Text(
                    '@${user.username}',
                    style: AppTextStyles.bodyS.copyWith(color: muted),
                  ),
                ],
              ),
            ),
            // XP badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accentPrimary, AppColors.accentPrimaryDark],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    _formatXp(xp),
                    style: AppTextStyles.labelL.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'XP',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.mutedGray),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatXp(int xp) {
    if (xp >= 1000000) return '${(xp / 1000000).toStringAsFixed(1)}M';
    if (xp >= 1000) return '${(xp / 1000).toStringAsFixed(1)}K';
    return '$xp';
  }
}
