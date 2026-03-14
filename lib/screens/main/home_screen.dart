import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/debate_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/debate/debate_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(debateProvider.notifier).fetchDebates(feedType: DebateFeedType.forYou);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    final feedType = [DebateFeedType.forYou, DebateFeedType.trending, DebateFeedType.following][index];
    ref.read(debateProvider.notifier).fetchDebates(feedType: feedType, refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final debateState = ref.watch(debateProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(debateProvider.notifier).fetchDebates(
            feedType: debateState.feedType,
            refresh: true,
          );
        },
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              snap: true,
              floating: true,
              backgroundColor: AppColors.darkCardBg,
              elevation: 0,
              automaticallyImplyLeading: false,
              centerTitle: true,
              title: Text(
                'Versz',
                style: AppTextStyles.h1.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                Consumer(
                  builder: (context, ref, child) {
                    final unread = ref.watch(notificationProvider).unreadCount;
                    return IconButton(
                      onPressed: () => context.push('/notifications'),
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
                          if (unread > 0)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.errorRed,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  unread > 99 ? '99+' : '$unread',
                                  style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Container(
                  color: AppColors.darkCardBg,
                  child: TabBar(
                    controller: _tabController,
                    onTap: _onTabChanged,
                    indicatorColor: AppColors.accentTeal,
                    indicatorWeight: 3,
                    labelColor: AppColors.textPrimary,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: AppTextStyles.labelSmall,
                    tabs: const [
                      Tab(text: 'FOR YOU'),
                      Tab(text: 'TRENDING'),
                      Tab(text: 'FOLLOWING'),
                    ],
                  ),
                ),
              ),
            ),
          ],
          body: debateState.isLoading && debateState.debates.isEmpty
                ? ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: 4,
                    itemBuilder: (context, index) => _FeedSkeletonCard(index: index),
                  )
                : debateState.error != null && debateState.debates.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.errorRed, size: 42),
                              const SizedBox(height: 10),
                              Text(
                                'Could not load debates',
                                style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                debateState.error!,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton(
                                onPressed: () => ref.read(debateProvider.notifier).fetchDebates(
                                      feedType: debateState.feedType,
                                      refresh: true,
                                    ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
              : debateState.debates.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.forum_outlined,
                              size: 64,
                              color: AppColors.accentTeal.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text('No Debates Yet', style: AppTextStyles.h2),
                            const SizedBox(height: 8),
                            Text(
                              'New debates will appear here',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: debateState.debates.length + (debateState.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == debateState.debates.length) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: OutlinedButton(
                                onPressed: debateState.isLoadingMore
                                    ? null
                                    : () => ref.read(debateProvider.notifier).loadMore(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.accentTeal,
                                  side: const BorderSide(color: AppColors.accentTeal),
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                ),
                                child: debateState.isLoadingMore
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentTeal),
                                      )
                                    : const Text('Load More'),
                              ),
                            ),
                          );
                        }

                        final debate = debateState.debates[index];
                        return GestureDetector(
                          onTap: () => context.push('/debate-detail', extra: debate),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: DebateCard(debate: debate),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}

class _FeedSkeletonCard extends StatelessWidget {
  final int index;
  const _FeedSkeletonCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.darkSurface),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 12, width: double.infinity, color: AppColors.darkSurface),
          const SizedBox(height: 8),
          Container(height: 12, width: 220, color: AppColors.darkSurface),
          const SizedBox(height: 12),
          Container(height: 8, width: double.infinity, color: AppColors.darkSurface),
        ],
      ),
    );
  }
}
