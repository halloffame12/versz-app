import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/url_utils.dart';
import '../../providers/leaderboard_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabLabels = ['WEEKLY', 'MONTHLY', 'ALL TIME'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLeaderboard();
    });
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _loadLeaderboard();
    });
  }

  void _loadLeaderboard() {
    final period = switch (_tabController.index) {
      0 => LeaderboardPeriod.weekly,
      1 => LeaderboardPeriod.monthly,
      _ => LeaderboardPeriod.allTime,
    };
    ref.read(leaderboardProvider.notifier).fetchLeaderboard(period: period);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaderboardProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // Radial glow backdrop
          Positioned(
            top: -60,
            left: MediaQuery.of(context).size.width / 2 - 120,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryYellow.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            children: [
              _buildHeader(),
              _buildPillTabs(),
              Expanded(
                child: state.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryYellow,
                          strokeWidth: 2,
                        ),
                      )
                    : state.entries.isEmpty
                        ? _buildEmptyState()
                        : _buildLeaderboardContent(state.entries),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryYellow.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryYellow.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.emoji_events_rounded, color: AppColors.primaryYellow, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HALL OF FAME',
                  style: AppTextStyles.h2.copyWith(
                    letterSpacing: 2,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkText,
                  ),
                ),
                Text(
                  'Top debaters on Versz',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillTabs() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.darkCardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Row(
            children: List.generate(_tabLabels.length, (i) {
              final isActive = _tabController.index == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _tabController.animateTo(i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primaryYellow : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isActive
                          ? [BoxShadow(color: AppColors.primaryYellow.withValues(alpha: 0.4), blurRadius: 12)]
                          : [],
                    ),
                    child: Text(
                      _tabLabels[i],
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        color: isActive ? AppColors.primaryBlack : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardContent(List<dynamic> entries) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        if (entries.length >= 3) _buildPodium(entries.take(3).toList().cast<dynamic>()),
        if (entries.length >= 3) const SizedBox(height: 24),
        if (entries.length >= 3)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'RANKINGS',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 2,
                fontSize: 10,
              ),
            ),
          ),
        ...entries.cast<dynamic>().skip(entries.length >= 3 ? 3 : 0).toList().asMap().entries.map((e) {
          final index = e.key + (entries.length >= 3 ? 4 : 1);
          return _buildLeaderboardRow(e.value, index);
        }),
      ],
    );
  }

  Widget _buildPodium(List<dynamic> top3) {
    return Column(
      children: [
        Text(
          'PODIUM',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 2,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildPodiumItem(top3[1], 2, AppColors.accentBlue),
            const SizedBox(width: 12),
            _buildPodiumItem(top3[0], 1, AppColors.primaryYellow),
            const SizedBox(width: 12),
            _buildPodiumItem(top3[2], 3, AppColors.accentOrange),
          ],
        ),
      ],
    );
  }

  Widget _buildPodiumItem(dynamic entry, int rank, Color color) {
    final score = ref.read(leaderboardProvider.notifier).scoreFor(entry);
    final displayName = (entry.displayName as String).trim().isEmpty
        ? entry.username as String
        : entry.displayName as String;
    final avatarRadius = rank == 1 ? 40.0 : 30.0;

    return Column(
      children: [
        if (rank == 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('👑', style: const TextStyle(fontSize: 20)),
          ),
        Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 0),
                ],
              ),
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: AppColors.darkSurface,
                backgroundImage: isValidNetworkUrl(entry.avatarUrl)
                    ? CachedNetworkImageProvider(entry.avatarUrl!)
                    : null,
                child: !isValidNetworkUrl(entry.avatarUrl)
                    ? Icon(Icons.person, color: AppColors.textMuted, size: avatarRadius)
                    : null,
              ),
            ),
            Positioned(
              bottom: -10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)],
                ),
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    color: rank == 1 ? AppColors.primaryBlack : AppColors.primaryBlack,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: 80,
          child: Text(
            displayName,
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: rank == 1 ? 13 : 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$score pts',
          style: AppTextStyles.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardRow(dynamic entry, int rank) {
    final score = ref.read(leaderboardProvider.notifier).scoreFor(entry);
    final displayName = (entry.displayName as String).trim().isEmpty
        ? entry.username as String
        : entry.displayName as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.darkCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.darkSurface,
            backgroundImage: isValidNetworkUrl(entry.avatarUrl)
                ? CachedNetworkImageProvider(entry.avatarUrl!)
                : null,
            child: !isValidNetworkUrl(entry.avatarUrl)
                ? const Icon(Icons.person, color: AppColors.textMuted, size: 18)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '@${entry.username}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryYellow.withValues(alpha: 0.25)),
            ),
            child: Text(
              '$score PTS',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primaryYellow,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.leaderboard_rounded, color: AppColors.darkBorder, size: 52),
          const SizedBox(height: 16),
          Text(
            'No rankings yet',
            style: AppTextStyles.h3.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
