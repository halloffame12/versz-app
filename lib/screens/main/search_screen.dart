import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/search_provider.dart';
import '../../widgets/common/verz_text_field.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 100,
        title: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: VerzTextField(
            label: '',
            hintText: 'SEARCH VERSZ...',
            controller: _searchController,
            prefixIcon: const Icon(Icons.search_rounded),
          ),
        ),
      ),
      body: hasQuery
          ? _buildSearchResults(searchState)
          : _buildDiscoveryContent(),
    );
  }

  Widget _buildSearchResults(SearchState searchState) {
    final allCount = searchState.debates.length + searchState.users.length + searchState.rooms.length + searchState.hashtags.length;

    if (searchState.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (searchState.error != null) {
      return Center(
        child: Text('Error: ${searchState.error}', style: const TextStyle(color: AppColors.error)),
      );
    }

    final hasResults = allCount > 0;

    if (!hasResults) {
      return _buildNoResults();
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Debates'),
            Tab(text: 'People'),
            Tab(text: 'Rooms'),
            Tab(text: 'Hashtags'),
          ],
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
      padding: const EdgeInsets.all(24),
      children: [
        if (searchState.debates.isNotEmpty) ...[
          _buildSectionHeader('DEBATES'),
          const SizedBox(height: 16),
          ...searchState.debates.map((d) => _buildDebateResultTile(d)),
          const SizedBox(height: 24),
        ],
        if (searchState.users.isNotEmpty) ...[
          _buildSectionHeader('PEOPLE'),
          const SizedBox(height: 16),
          ...searchState.users.map((u) => _buildUserResultTile(u)),
          const SizedBox(height: 24),
        ],
        if (searchState.rooms.isNotEmpty) ...[
          _buildSectionHeader('ROOMS'),
          const SizedBox(height: 16),
          ...searchState.rooms.map((r) => _buildRoomResultTile(r)),
          const SizedBox(height: 24),
        ],
        if (searchState.hashtags.isNotEmpty) ...[
          _buildSectionHeader('HASHTAGS'),
          const SizedBox(height: 16),
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
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(searchProvider.notifier).loadDiscovery(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('TRENDING SEARCHES'),
            const SizedBox(height: 16),
            if (state.trendingSearches.isEmpty)
              _buildSimpleEmpty('No trending searches available right now.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 12,
                children: state.trendingSearches
                    .map((term) => _buildTrendChip(term))
                    .toList(),
              ),
            const SizedBox(height: 30),
            _buildSectionHeader('RECENT SEARCHES'),
            const SizedBox(height: 12),
            if (_recentSearches.isEmpty)
              Text('No recent searches', style: AppTextStyles.bodySmall)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _recentSearches
                    .map((term) => ActionChip(
                          label: Text(term),
                          onPressed: () {
                            _searchController.text = term;
                            _searchController.selection = TextSelection.collapsed(offset: term.length);
                            _runSearch(term);
                          },
                        ))
                    .toList(),
              ),
            const SizedBox(height: 32),
            _buildSectionHeader('TOP ROOMS'),
            const SizedBox(height: 16),
            _buildTrendingRoomsSection(state),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title, 
      style: AppTextStyles.labelMedium.copyWith(letterSpacing: 2, fontWeight: FontWeight.w900, color: AppColors.accent),
    );
  }

  Widget _buildTrendChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceLight, width: 1),
      ),
      child: InkWell(
        onTap: () {
          _searchController.text = label;
          _searchController.selection = TextSelection.collapsed(offset: label.length);
          _runSearch(label);
        },
        child: Text(label, style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _buildTrendingRoomsSection(SearchState searchState) {
    if (searchState.trendingRooms.isEmpty) {
      return _buildSimpleEmpty('No top rooms yet.');
    }

    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: searchState.trendingRooms.length,
        itemBuilder: (context, index) {
          final room = searchState.trendingRooms[index];
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.surfaceLight, width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.groups_3_rounded, color: AppColors.primary, size: 32),
                const SizedBox(height: 12),
                Text(room.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1),
                Text('${room.membersCount} MEMBERS', style: AppTextStyles.labelSmall.copyWith(fontSize: 8, color: AppColors.textMuted)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDebateResultTile(Debate debate) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(debate.title, style: AppTextStyles.labelLarge),
        subtitle: Text('${debate.upvotes + debate.downvotes} ARGUMENTS', style: AppTextStyles.labelSmall.copyWith(color: AppColors.accent, fontSize: 8)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
        onTap: () => context.push('/debate-detail', extra: debate),
      ),
    );
  }

  Widget _buildRoomResultTile(Room room) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.group_rounded, color: AppColors.primary),
        title: Text(room.name, style: AppTextStyles.labelLarge),
        subtitle: Text('${room.membersCount} MEMBERS', style: AppTextStyles.labelSmall.copyWith(fontSize: 8)),
        onTap: () => context.push('/chat/${room.id}', extra: room),
      ),
    );
  }

  Widget _buildUserResultTile(UserAccount user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: AppColors.surfaceLight,
          backgroundImage: user.avatarUrl != null ? CachedNetworkImageProvider(user.avatarUrl!) : null,
          child: user.avatarUrl == null ? Text(user.displayName[0].toUpperCase()) : null,
        ),
        title: Text(user.displayName, style: AppTextStyles.labelLarge),
        subtitle: Text('@${user.username}', style: AppTextStyles.labelSmall.copyWith(color: AppColors.accent)),
        onTap: () => context.push('/profile/${user.id}'),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: AppColors.surfaceLight),
          const SizedBox(height: 20),
          Text('NO RESULTS FOUND', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text('Try searching for something else', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildHashtagResultTile(String tag, int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.tag, color: AppColors.primary),
        title: Text('#$tag', style: AppTextStyles.labelLarge),
        subtitle: Text('$count debates', style: AppTextStyles.labelSmall),
        onTap: () => context.push('/hashtag/$tag'),
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
