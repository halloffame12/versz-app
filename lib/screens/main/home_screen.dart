import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/debate_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/debate/debate_card.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  String? _selectedCategoryId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) _loadDebates();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (mounted) {
      await ref.read(categoryProvider.notifier).fetchCategories();
      _loadDebates();
    }
  }

  void _loadDebates() {
    final feedType = switch (_tabController.index) {
      1 => DebateFeedType.trending,
      2 => DebateFeedType.following,
      _ => DebateFeedType.forYou,
    };

    ref.read(debateProvider.notifier).fetchDebates(
          categoryId: _selectedCategoryId,
          feedType: feedType,
          refresh: true,
        );
  }

  Future<void> _onRefresh() async {
    await ref.read(debateProvider.notifier).fetchDebates(
          categoryId: _selectedCategoryId,
          feedType: switch (_tabController.index) {
            1 => DebateFeedType.trending,
            2 => DebateFeedType.following,
            _ => DebateFeedType.forYou,
          },
          refresh: true,
        );
    _refreshController.refreshCompleted();
    _refreshController.loadComplete();
  }

  Future<void> _onLoadingMore() async {
    await ref.read(debateProvider.notifier).loadMore();
    final hasMore = ref.read(debateProvider).hasMore;
    if (hasMore) {
      _refreshController.loadComplete();
    } else {
      _refreshController.loadNoData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final debateState = ref.watch(debateProvider);
    final categoryState = ref.watch(categoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            floating: true,
            pinned: true,
            snap: true,
            backgroundColor: AppColors.background.withValues(alpha: 0.8),
            elevation: 0,
            centerTitle: false,
            title: Text(
              AppStrings.appName.toUpperCase(),
              style: AppTextStyles.h2.copyWith(
                letterSpacing: 4,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary),
                onPressed: () => context.push('/search'),
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.textPrimary),
                onPressed: () => context.push('/messages'),
              ),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.surfaceLight.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorWeight: 3,
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
                  unselectedLabelStyle: AppTextStyles.labelMedium,
                  onTap: (_) => _loadDebates(),
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
        body: Column(
          children: [
            // Category Selector
            if (categoryState.categories.isNotEmpty)
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categoryState.categories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildCategoryChip('All', null);
                    }
                    final category = categoryState.categories[index - 1];
                    return _buildCategoryChip(
                      '${category.emoji} ${category.name}',
                      category.id,
                    );
                  },
                ),
              ),

            // Feed
            Expanded(
              child: SmartRefresher(
                controller: _refreshController,
                onRefresh: _onRefresh,
                enablePullUp: debateState.hasMore,
                onLoading: _onLoadingMore,
                header: ClassicHeader(
                  refreshingIcon: const SizedBox(
                    width: 25,
                    height: 25,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                  refreshingText: '',
                  releaseText: '',
                  completeText: '',
                  idleText: '',
                  idleIcon: Icon(Icons.arrow_downward, color: AppColors.textMuted, size: 20),
                ),
                child: debateState.isLoading
                  ? _buildFeedShimmer()
                    : debateState.error != null
                        ? _buildErrorState(debateState.error!)
                        : debateState.debates.isEmpty
                          ? _buildEmptyState(_tabController.index)
                            : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), // Extra padding for bottom nav
                            itemCount: debateState.debates.length + (debateState.isLoadingMore ? 1 : 0),
                            separatorBuilder: (_, __) => const SizedBox(height: 20),
                            itemBuilder: (context, index) {
                              if (index >= debateState.debates.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: CircularProgressIndicator(color: AppColors.primary),
                                  ),
                                );
                              }
                              return DebateCard(
                                debate: debateState.debates[index],
                                onTap: () => context.push('/debate-detail', extra: debateState.debates[index]),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90), // Offset for custom bottom nav
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/create-debate'),
          backgroundColor: AppColors.primary,
          elevation: 4,
          icon: const Icon(Icons.add_rounded, color: Colors.black, size: 28),
          label: Text('DEBATE', style: AppTextStyles.labelMedium.copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? id) {
    final isSelected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedCategoryId = id;
            });
            _loadDebates();
          }
        },
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        labelStyle: AppTextStyles.labelSmall.copyWith(
          color: isSelected ? Colors.white : AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildEmptyState(int tabIndex) {
    final title = switch (tabIndex) {
      1 => 'No trending debates yet',
      2 => 'No debates from people you follow',
      _ => 'No debates found',
    };

    final subtitle = switch (tabIndex) {
      1 => 'Votes and comments will push debates into trending.',
      2 => 'Follow more creators to populate this feed.',
      _ => 'Be the first to start a conversation!',
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 64, color: AppColors.surface),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTextStyles.h3.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Error loading debates',
            style: AppTextStyles.h3.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              error,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadDebates,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('Retry', style: AppTextStyles.labelMedium.copyWith(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.surface,
          highlightColor: AppColors.surfaceLight,
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }
}
