import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/debate_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/debate/debate_card.dart';
import '../../widgets/common/state_widgets.dart';

class HomeScreenV2 extends ConsumerStatefulWidget {
  const HomeScreenV2({super.key});

  @override
  ConsumerState<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends ConsumerState<HomeScreenV2> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fabAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fabAnimation = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(debateProvider.notifier).fetchDebates(feedType: DebateFeedType.forYou);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fabAnimation.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    final feedType = [DebateFeedType.forYou, DebateFeedType.trending, DebateFeedType.following][index];
    ref.read(debateProvider.notifier).fetchDebates(feedType: feedType, refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final debateState = ref.watch(debateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AppColors.backgroundColor(isDark);
    final cardBg = AppColors.cardBackground(isDark);
    final border = AppColors.borderColor(isDark);
    final text = AppColors.textColor(isDark);
    final muted = AppColors.mutedTextColor(isDark);

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: ScaleTransition(
        scale: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _fabAnimation, curve: Curves.elasticOut),
        ),
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/create-debate'),
          backgroundColor: AppColors.accentPurple,
          label: const Text('New Debate'),
          icon: const Icon(Icons.add_rounded),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(debateProvider.notifier).fetchDebates(
            feedType: debateState.feedType,
            refresh: true,
          );
        },
        color: AppColors.accentCyan,
        backgroundColor: cardBg,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              snap: true,
              floating: true,
              backgroundColor: bg,
              elevation: 0,
              automaticallyImplyLeading: false,
              centerTitle: false,
              title: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.accentLight, AppColors.accentPrimary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  'Versz',
                  style: AppTextStyles.h0.copyWith(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () => context.push('/leaderboard'),
                  icon: Icon(Icons.emoji_events_rounded, color: text, size: 24),
                ),
                IconButton(
                  onPressed: () => context.push('/settings'),
                  icon: Icon(Icons.settings_rounded, color: text, size: 24),
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final unread = ref.watch(notificationProvider).unreadCount;
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Center(
                        child: IconButton(
                          onPressed: () => context.push('/notifications'),
                          icon: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(Icons.notifications_none_rounded, 
                                color: Colors.white, size: 28),
                              if (unread > 0)
                                Positioned(
                                  right: -4,
                                  top: -4,
                                  child: ScaleTransition(
                                    scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                                      CurvedAnimation(parent: _fabAnimation, curve: Curves.elasticOut),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [AppColors.accentLight, AppColors.accentPrimary],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: bg,
                                          width: 2,
                                        ),
                                      ),
                                      child: Text(
                                        unread > 99 ? '99+' : '$unread',
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: border.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      onTap: _onTabChanged,
                      indicatorColor: AppColors.accentCyan,
                      indicatorWeight: 3,
                      labelColor: text,
                      unselectedLabelColor: muted,
                      labelStyle: AppTextStyles.labelL.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      tabs: const [
                        Tab(text: 'FOR YOU'),
                        Tab(text: 'TRENDING'),
                        Tab(text: 'FOLLOWING'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildFeedList(debateState, ref),
              _buildFeedList(debateState, ref),
              _buildFeedList(debateState, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedList(DebateState debateState, WidgetRef ref) {
    if (debateState.isLoading && debateState.debates.isEmpty) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.all(16),
          child: ShimmerDebateCard(),
        ),
      );
    }

    if (debateState.error != null && debateState.debates.isEmpty) {
      return ErrorStateWidget(
        title: 'Could not load debates',
        message: 'Unable to load debates',
        errorDetails: debateState.error ?? 'Something went wrong',
        onRetry: () => ref.read(debateProvider.notifier).fetchDebates(
          feedType: debateState.feedType,
          refresh: true,
        ),
      );
    }

    if (debateState.debates.isEmpty) {
      return EmptyStateWidget(
        title: 'No debates yet',
        subtitle: 'Start or follow creators to see debates here',
        icon: Icons.forum_rounded,
        iconColor: AppColors.accentPurple,
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 300 &&
            !debateState.isLoadingMore &&
            debateState.hasMore) {
          ref.read(debateProvider.notifier).fetchDebates(
            feedType: debateState.feedType,
            refresh: false,
          );
        }
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        itemCount: debateState.debates.length + (debateState.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == debateState.debates.length) {
            return const SizedBox(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final debate = debateState.debates[index];
          return AnimatedOpacity(
            opacity: 1.0,
            duration: Duration(milliseconds: 300 + (index * 50)),
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero).animate(
                CurvedAnimation(
                  parent: ModalRoute.of(context)?.animation ?? AlwaysStoppedAnimation(1.0),
                  curve: Curves.easeOut,
                ),
              ),
              child: DebateCard(debate: debate),
            ),
          );
        },
      ),
    );
  }
}

class ShimmerDebateCard extends StatelessWidget {
  const ShimmerDebateCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppColors.cardBackground(isDark);
    final border = AppColors.borderColor(isDark);
    final shimmer = AppColors.mutedTextColor(isDark).withValues(alpha: 0.2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 20,
            width: 150,
            decoration: BoxDecoration(
              color: shimmer,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 16,
            width: double.infinity,
            decoration: BoxDecoration(
              color: shimmer,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 16,
            width: 200,
            decoration: BoxDecoration(
              color: shimmer,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}
