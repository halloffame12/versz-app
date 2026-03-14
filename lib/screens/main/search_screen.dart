import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/url_utils.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/search_provider.dart';
import '../../widgets/common/verz_text_field.dart';
import '../../widgets/common/state_widgets.dart';
import '../../models/debate.dart';
import '../../models/room.dart';
import '../../models/user_account.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  Timer? _debounce;
  late TabController _tabController;
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadRecentSearches();
      await ref.read(searchProvider.notifier).loadDiscovery();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final recent = prefs.getStringList('recent_searches') ?? [];
    if (!mounted) return;
    setState(() {
      _recentSearches = recent;
    });
    ref.read(searchProvider.notifier).setRecentSearches(recent);
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = List<String>.from(_recentSearches);
    list.remove(query);
    list.insert(0, query);
    final trimmed = list.take(10).toList();
    await prefs.setStringList('recent_searches', trimmed);
    if (!mounted) return;
    setState(() {
      _recentSearches = trimmed;
    });
    ref.read(searchProvider.notifier).setRecentSearches(trimmed);
  }

  void _runSearch(String query) {
    ref.read(searchProvider.notifier).search(query);
    _saveRecentSearch(query);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (query.isNotEmpty) {
        _runSearch(query);
      } else {
        ref.read(searchProvider.notifier).search('');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final hasQuery = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 80,
        title: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: VerzTextField(
            label: '',
            hintText: 'Search debates, people, rooms...',
            controller: _searchController,
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 6),
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                onPressed: () {
                  _searchController.clear();
                  ref.read(searchProvider.notifier).search('');
                },
              ),
            ),
        ],
      ),
      body: hasQuery
          ? _buildSearchResults(searchState)
          : _buildDiscoveryContent(),
    );
  }

  Widget _buildSearchResults(SearchState searchState) {
    final allCount = searchState.debates.length + searchState.users.length + searchState.rooms.length + searchState.hashtags.length;

    if (searchState.isLoading) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: LoadingSkeleton(itemCount: 5),
      );
    }

    if (searchState.error != null) {
      return ErrorStateWidget(
        title: 'Search failed',
        message: 'Unable to search. Please try again.',
        errorDetails: searchState.error ?? 'Unknown error',
        accentColor: AppColors.errorRed,
        onRetry: () => ref.read(searchProvider.notifier).search(_searchController.text),
      );
    }

    if (allCount == 0) {
      return EmptyStateWidget(
        title: 'No results found',
        subtitle: 'Try searching with different keywords or check your spelling.',
        icon: Icons.not_interested_rounded,
        iconColor: AppColors.accentBlue,
      );
    }

    return Column(
      children: [
        Container(
          color: AppColors.darkBackground,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.accentTeal,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.accentTeal,
            indicatorWeight: 2,
            isScrollable: true,
            dividerColor: AppColors.darkBorder,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Debates'),
              Tab(text: 'People'),
              Tab(text: 'Rooms'),
              Tab(text: 'Hashtags'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAllResults(searchState),
              _buildDebatesResults(searchState.debates),
              _buildUsersResults(searchState.users),
              _buildRoomsResults(searchState.rooms),
              _buildHashtagsResults(searchState),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllResults(SearchState searchState) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        if (searchState.debates.isNotEmpty) ...[
          _buildSectionHeader('DEBATES', AppColors.accentBlue, Icons.gavel_rounded),
          const SizedBox(height: 12),
          ...searchState.debates.map((d) => _buildDebateResultTile(d)),
          const SizedBox(height: 20),
        ],
        if (searchState.users.isNotEmpty) ...[
          _buildSectionHeader('PEOPLE', AppColors.primaryYellow, Icons.person_rounded),
          const SizedBox(height: 12),
          ...searchState.users.map((u) => _buildUserResultTile(u)),
          const SizedBox(height: 20),
        ],
        if (searchState.rooms.isNotEmpty) ...[
          _buildSectionHeader('ROOMS', AppColors.accentTeal, Icons.groups_rounded),
          const SizedBox(height: 12),
          ...searchState.rooms.map((r) => _buildRoomResultTile(r)),
          const SizedBox(height: 20),
        ],
        if (searchState.hashtags.isNotEmpty) ...[
          _buildSectionHeader('HASHTAGS', AppColors.accentBlue, Icons.tag_rounded),
          const SizedBox(height: 12),
          ...searchState.hashtags.map((h) => _buildHashtagResultTile(h.tag, h.debateCount)),
        ],
      ],
    );
  }

  Widget _buildDebatesResults(List<Debate> debates) {
    if (debates.isEmpty) return _buildSimpleEmpty('No debates found for this query.');
    return ListView(
      padding: const EdgeInsets.all(24),
      children: debates.map((d) => _buildDebateResultTile(d)).toList(),
    );
  }

  Widget _buildUsersResults(List<UserAccount> users) {
    if (users.isEmpty) return _buildSimpleEmpty('No people found for this query.');
    return ListView(
      padding: const EdgeInsets.all(24),
      children: users.map((u) => _buildUserResultTile(u)).toList(),
    );
  }

  Widget _buildRoomsResults(List<Room> rooms) {
    if (rooms.isEmpty) return _buildSimpleEmpty('No rooms found for this query.');
    return ListView(
      padding: const EdgeInsets.all(24),
      children: rooms.map((r) => _buildRoomResultTile(r)).toList(),
    );
  }

  Widget _buildHashtagsResults(SearchState state) {
    if (state.hashtags.isEmpty) return _buildSimpleEmpty('No hashtags found for this query.');
    return ListView(
      padding: const EdgeInsets.all(24),
      children: state.hashtags.map((h) => _buildHashtagResultTile(h.tag, h.debateCount)).toList(),
    );
  }

  Widget _buildDiscoveryContent() {
    final state = ref.watch(searchProvider);
    if (state.isLoading && state.trendingRooms.isEmpty && state.trendingSearches.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow, strokeWidth: 2));
    }

    return RefreshIndicator(
      color: AppColors.primaryYellow,
      backgroundColor: AppColors.darkCardBg,
      onRefresh: () => ref.read(searchProvider.notifier).loadDiscovery(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('TRENDING NOW', AppColors.accentOrange, Icons.trending_up_rounded),
            const SizedBox(height: 14),
            if (state.trendingSearches.isEmpty)
              _buildSimpleEmpty('No trending searches yet.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: state.trendingSearches.map((term) => _buildTrendChip(term)).toList(),
              ),
            const SizedBox(height: 28),
            _buildSectionHeader('RECENT SEARCHES', AppColors.textMuted, Icons.history_rounded),
            const SizedBox(height: 12),
            if (_recentSearches.isEmpty)
              Text('No recent searches', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _recentSearches.map((term) => GestureDetector(
                  onTap: () {
                    _searchController.text = term;
                    _searchController.selection = TextSelection.collapsed(offset: term.length);
                    _runSearch(term);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.darkCardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history_rounded, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(term, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                )).toList(),
              ),
            const SizedBox(height: 28),
            _buildSectionHeader('TOP ROOMS', AppColors.accentTeal, Icons.groups_rounded),
            const SizedBox(height: 14),
            _buildTrendingRoomsSection(state),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.labelSmall.copyWith(
            letterSpacing: 1.5,
            fontWeight: FontWeight.w900,
            color: color,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendChip(String label) {
    return GestureDetector(
      onTap: () {
        _searchController.text = label;
        _searchController.selection = TextSelection.collapsed(offset: label.length);
        _runSearch(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.accentOrange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.trending_up_rounded, size: 13, color: AppColors.accentOrange),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.darkText,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingRoomsSection(SearchState searchState) {
    if (searchState.trendingRooms.isEmpty) {
      return _buildSimpleEmpty('No top rooms yet.');
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: searchState.trendingRooms.length,
        itemBuilder: (context, index) {
          final room = searchState.trendingRooms[index];
          return GestureDetector(
            onTap: () => context.push('/chat/${room.id}', extra: room),
            child: Container(
              width: 130,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accentTeal.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accentTeal.withValues(alpha: 0.25)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentTeal.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.groups_3_rounded, color: AppColors.accentTeal, size: 24),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    room.name,
                    style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${room.membersCount} members',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDebateResultTile(Debate debate) {
    return GestureDetector(
      onTap: () => context.push('/debate-detail', extra: debate),
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
              width: 3,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.accentBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(debate.title, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    '${debate.upvotes + debate.downvotes} votes',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.accentBlue, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomResultTile(Room room) {
    return GestureDetector(
      onTap: () => context.push('/chat/${room.id}', extra: room),
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
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.accentTeal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accentTeal.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.group_rounded, color: AppColors.accentTeal, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room.name, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                  Text('${room.membersCount} members', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildUserResultTile(UserAccount user) {
    return GestureDetector(
      onTap: () => context.push('/profile/${user.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
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
                border: Border.all(color: AppColors.primaryYellow.withValues(alpha: 0.5)),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.darkSurface,
                backgroundImage: isValidNetworkUrl(user.avatarUrl)
                    ? CachedNetworkImageProvider(user.avatarUrl!)
                    : null,
                child: !isValidNetworkUrl(user.avatarUrl)
                    ? Text(
                        user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppColors.primaryYellow, fontWeight: FontWeight.w800),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.displayName, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                  Text('@${user.username}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryYellow, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildHashtagResultTile(String tag, int count) {
    return GestureDetector(
      onTap: () {
        _searchController.text = tag;
        _searchController.selection = TextSelection.collapsed(offset: tag.length);
        _runSearch(tag);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.darkCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.3)),
              ),
              child: const Center(
                child: Text('#', style: TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#$tag', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.accentBlue)),
                  Text('$count debates', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleEmpty(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
        ),
      ),
    );
  }
}
