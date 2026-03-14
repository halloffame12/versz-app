import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class SearchScreenV2 extends ConsumerStatefulWidget {
  const SearchScreenV2({super.key});

  @override
  ConsumerState<SearchScreenV2> createState() => _SearchScreenV2State();
}

class _SearchScreenV2State extends ConsumerState<SearchScreenV2> with TickerProviderStateMixin {
  late TextEditingController _searchController;
  late AnimationController _searchAnimation;
  String _searchQuery = '';
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchAnimation = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AppColors.backgroundColor(isDark);
    final cardBg = AppColors.cardBackground(isDark);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                  CurvedAnimation(parent: _searchAnimation, curve: Curves.easeOut),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: AppTextStyles.bodyM.copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search debates, users, communities...',
                    hintStyle: AppTextStyles.bodyM.copyWith(color: AppColors.mutedGray),
                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.accentCyan),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: Icon(Icons.close_rounded, color: AppColors.mutedGray),
                          )
                        : null,
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.accentIndigo.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.accentIndigo.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.accentCyan,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            // Tabs
            if (_searchQuery.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    'Trending',
                    'Users',
                    'Debates',
                    'Communities',
                  ]
                      .asMap()
                      .entries
                      .map((entry) {
                        final index = entry.key;
                        final label = entry.value;
                        final isSelected = _selectedTab == index;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTab = index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.accentPurple : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: !isSelected
                                    ? Border.all(
                                        color: AppColors.accentIndigo.withValues(alpha: 0.3),
                                      )
                                    : null,
                              ),
                              child: Text(
                                label,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isSelected ? AppColors.textPrimary : AppColors.mutedGray,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      })
                      .toList(),
                ),
              ),

            const SizedBox(height: 16),

            // Content
            Expanded(
              child: _searchQuery.isEmpty
                  ? _buildTrendingContent()
                  : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppColors.cardBackground(isDark);

    final trending = [
      {'tag': '#AI', 'debates': 2341, 'trend': 'up'},
      {'tag': '#Technology', 'debates': 1856, 'trend': 'up'},
      {'tag': '#Politics', 'debates': 1623, 'trend': 'stable'},
      {'tag': '#Science', 'debates': 1401, 'trend': 'down'},
      {'tag': '#Entertainment', 'debates': 1289, 'trend': 'up'},
      {'tag': '#Sports', 'debates': 1156, 'trend': 'up'},
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: trending.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = trending[index];
        final tag = item['tag'] as String;
        final debates = item['debates'] as int;
        final trend = item['trend'] as String;
        
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 600 + (index * 100)),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, (1 - value) * 30),
              child: Opacity(
                opacity: value,
                child: GestureDetector(
                  onTap: () {
                    _searchController.text = tag;
                    setState(() => _searchQuery = tag);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.accentIndigo.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.accentPurple.withValues(alpha: 0.3),
                                AppColors.accentIndigo.withValues(alpha: 0.3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.local_fire_department_rounded,
                              color: AppColors.accentCyan,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tag,
                                style: AppTextStyles.bodyL.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '$debates debates',
                                style: AppTextStyles.bodyS.copyWith(
                                  color: AppColors.mutedGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          trend == 'up'
                              ? Icons.trending_up_rounded
                              : trend == 'down'
                                  ? Icons.trending_down_rounded
                                  : Icons.trending_flat_rounded,
                          color: trend == 'up'
                              ? Colors.green
                              : trend == 'down'
                                  ? Colors.red
                                  : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchResults() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppColors.cardBackground(isDark);

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accentIndigo.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentPurple,
                        AppColors.accentIndigo,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: AppTextStyles.headlineM.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Result ${index + 1}',
                        style: AppTextStyles.bodyL.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Description for search result',
                        style: AppTextStyles.bodyS.copyWith(
                          color: AppColors.mutedGray,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: AppColors.accentCyan, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
