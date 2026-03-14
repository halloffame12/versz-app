import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class RoomsScreenV2 extends ConsumerStatefulWidget {
  const RoomsScreenV2({super.key});

  @override
  ConsumerState<RoomsScreenV2> createState() => _RoomsScreenV2State();
}

class _RoomsScreenV2State extends ConsumerState<RoomsScreenV2> with TickerProviderStateMixin {
  late AnimationController _fabAnimation;
  late List<Map<String, dynamic>> _communities;

  @override
  void initState() {
    super.initState();
    _fabAnimation = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
    _communities = [
      {
        'name': 'AI & Technology',
        'icon': '🤖',
        'members': 3452,
        'description': 'Discuss latest in AI and tech',
        'isJoined': true,
      },
      {
        'name': 'Philosophy Debate',
        'icon': '🧠',
        'members': 2104,
        'description': 'Deep philosophical discussions',
        'isJoined': true,
      },
      {
        'name': 'Sports Talk',
        'icon': '⚽',
        'members': 4821,
        'description': 'All things sports',
        'isJoined': false,
      },
      {
        'name': 'Science Lovers',
        'icon': '🔬',
        'members': 2563,
        'description': 'Science and research community',
        'isJoined': true,
      },
      {
        'name': 'Entertainment',
        'icon': '🎬',
        'members': 5234,
        'description': 'Movies, music, and pop culture',
        'isJoined': false,
      },
      {
        'name': 'Business & Economics',
        'icon': '💼',
        'members': 1876,
        'description': 'Career and business discussions',
        'isJoined': true,
      },
    ];
  }

  void _toggleJoin(int index) {
    setState(() {
      final joined = _communities[index]['isJoined'] as bool;
      _communities[index]['isJoined'] = !joined;
      final members = _communities[index]['members'] as int;
      _communities[index]['members'] = joined ? members - 1 : members + 1;
    });
    final name = _communities[index]['name'] as String;
    final nowJoined = _communities[index]['isJoined'] as bool;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(nowJoined ? 'Joined $name' : 'Left $name')),
    );
  }

  void _openCommunity(int index) {
    final name = _communities[index]['name'] as String;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening $name community...')),
    );
  }

  @override
  void dispose() {
    _fabAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AppColors.backgroundColor(isDark);
    final cardBg = AppColors.cardBackground(isDark);

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: ScaleTransition(
        scale: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _fabAnimation, curve: Curves.elasticOut),
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Community creation coming in the next update.')),
            );
          },
          backgroundColor: AppColors.accentIndigo,
          label: const Text('New Community'),
          icon: const Icon(Icons.add_rounded),
        ),
      ),
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [AppColors.accentPurple, AppColors.accentIndigo, AppColors.accentCyan],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'COMMUNITIES',
            style: AppTextStyles.headlineL.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        itemCount: _communities.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final community = _communities[index];
          final name = community['name'] as String;
          final icon = community['icon'] as String;
          final members = community['members'] as int;
          final description = community['description'] as String;
          final isJoined = community['isJoined'] as bool;

          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 600 + (index * 100)),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, (1 - value) * 50),
                child: Opacity(
                  opacity: value,
                  child: GestureDetector(
                    onTap: () => _openCommunity(index),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.accentIndigo.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Icon
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.accentPurple.withValues(alpha: 0.3),
                                      AppColors.accentIndigo.withValues(alpha: 0.3),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    icon,
                                    style: const TextStyle(fontSize: 36),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: AppTextStyles.bodyL.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.people_rounded,
                                          size: 14,
                                          color: AppColors.accentCyan,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$members members',
                                          style: AppTextStyles.labelSmall.copyWith(
                                            color: AppColors.mutedGray,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Join button
                              if (!isJoined)
                                ScaleTransition(
                                  scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                                    CurvedAnimation(
                                      parent: _fabAnimation,
                                      curve: Curves.elasticOut,
                                    ),
                                  ),
                                  child: GestureDetector(
                                    onTap: () => _toggleJoin(index),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [AppColors.accentPurple, AppColors.accentIndigo],
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Join',
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
                          const SizedBox(height: 12),
                          Text(
                            description,
                            style: AppTextStyles.bodyS.copyWith(
                              color: AppColors.mutedGray,
                            ),
                          ),
                          if (isJoined) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _openCommunity(index),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentCyan.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: AppColors.accentCyan.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'View',
                                          style: AppTextStyles.labelSmall.copyWith(
                                            color: AppColors.accentCyan,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {},
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [AppColors.accentPurple, AppColors.accentIndigo],
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Browse',
                                          style: AppTextStyles.labelSmall.copyWith(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
