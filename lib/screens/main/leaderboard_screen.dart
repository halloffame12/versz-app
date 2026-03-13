import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/leaderboard_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    ref.read(leaderboardProvider.notifier).fetchLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaderboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildPillTabs(),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : state.entries.isEmpty
                    ? _buildEmptyState()
                    : _buildLeaderboardContent(state.entries),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
      child: Row(
        children: [
          const Icon(Icons.leaderboard_rounded, color: AppColors.accent, size: 28),
          const SizedBox(width: 12),
          Text('TOP DEBATERS', style: AppTextStyles.h2.copyWith(letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildPillTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w900, fontSize: 10),
        indicator: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        tabs: const [
          Tab(text: 'WEEKLY'),
          Tab(text: 'MONTHLY'),
          Tab(text: 'ALL TIME'),
        ],
      ),
    );
  }

  Widget _buildLeaderboardContent(List<dynamic> entries) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: [
        if (entries.length >= 3) _buildPodium(entries.take(3).toList().cast<dynamic>()),
        const SizedBox(height: 32),
        ...entries.cast<dynamic>().skip(entries.length >= 3 ? 3 : 0).toList().asMap().entries.map((e) {
          final index = e.key + (entries.length >= 3 ? 4 : 1);
          return _buildLeaderboardRow(e.value, index);
        }),
      ],
    );
  }

  Widget _buildPodium(List<dynamic> top3) {
    // top3[0] is 1st, [1] is 2nd, [2] is 3rd
    // Display sequence: 2nd, 1st, 3rd
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildPodiumItem(top3[1], 2, 100, Colors.grey),
        const SizedBox(width: 16),
        _buildPodiumItem(top3[0], 1, 130, AppColors.accent),
        const SizedBox(width: 16),
        _buildPodiumItem(top3[2], 3, 90, Colors.orangeAccent),
      ],
    );
  }

  Widget _buildPodiumItem(dynamic entry, int rank, double height, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
              ),
              child: CircleAvatar(
                radius: rank == 1 ? 40 : 32,
                backgroundColor: AppColors.surface,
                backgroundImage: entry.userAvatar != null ? CachedNetworkImageProvider(entry.userAvatar!) : null,
              ),
            ),
            Container(
              transform: Matrix4.translationValues(0, 10, 0),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('#$rank', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 10)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(entry.username, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w900), textAlign: TextAlign.center),
        Text('${entry.points} pts', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildLeaderboardRow(dynamic entry, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('$rank', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w900)),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surfaceLight,
            backgroundImage: entry.userAvatar != null ? CachedNetworkImageProvider(entry.userAvatar!) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(entry.username, style: AppTextStyles.labelLarge),
          ),
          Text(
            '${entry.points} PTS', 
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.accent, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text('NO DATA AVAILABLE', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted)),
    );
  }
}
