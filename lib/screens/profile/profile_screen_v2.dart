import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../models/user_account.dart';

class ProfileScreenV2 extends ConsumerStatefulWidget {
  final String userId;
  const ProfileScreenV2({super.key, required this.userId});

  @override
  ConsumerState<ProfileScreenV2> createState() => _ProfileScreenV2State();
}

class _ProfileScreenV2State extends ConsumerState<ProfileScreenV2> {
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authUser = ref.read(authProvider).user;
      final isOwn = widget.userId == 'current' || widget.userId == authUser?.id;
      if (!isOwn) {
        ref.read(profileProvider(widget.userId).notifier).fetchProfile();
      }
    });
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  String _joined(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return 'Joined ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AppColors.backgroundColor(isDark);

    final authUser = ref.watch(authProvider).user;
    final isCurrentUser =
        widget.userId == 'current' || widget.userId == authUser?.id;

    UserAccount? profile;
    bool isLoading = false;
    String? loadError;

    if (isCurrentUser) {
      profile = authUser;
    } else {
      final ps = ref.watch(profileProvider(widget.userId));
      profile = ps.profile;
      isLoading = ps.isLoading;
      loadError = ps.error;
    }

    // Show loading spinner while:
    // - own profile: waiting for authProvider.checkAuthStatus()
    // - other user: waiting for profileProvider fetch
    if ((isLoading || (isCurrentUser && authUser == null)) && profile == null) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.accentCyan, strokeWidth: 2),
        ),
      );
    }

    if (loadError != null && profile == null) {
      return Scaffold(
        backgroundColor: bg,
        body: _buildErrorState(loadError),
      );
    }

    final displayName = profile?.displayName ?? 'Versz User';
    final username = profile?.username ?? widget.userId.replaceAll('@', '');
    final bio = (profile?.bio?.isNotEmpty == true)
        ? profile!.bio!
        : 'Passionate about debates and building great ideas.';
    final avatarUrl = profile?.avatarUrl;
    final coverUrl = profile?.coverImage;
    final followersCount = profile?.followersCount ?? 0;
    final followingCount = profile?.followingCount ?? 0;
    final debatesCreated = profile?.debatesCreated ?? 0;
    final xp = profile?.xp ?? 0;
    final isVerified = profile?.isVerified ?? false;
    final joinedDate = profile?.createdAt ?? DateTime.now();
    final website = profile?.website;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // Cover / AppBar
          SliverAppBar(
            expandedHeight: 210,
            stretch: true,
            backgroundColor: bg,
            elevation: 0,
            pinned: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (isCurrentUser)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                  ),
                  onPressed: () => context.push('/edit-profile'),
                )
              else
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
                  ),
                  onPressed: () => _showUserOptions(context, username),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  (coverUrl != null && coverUrl.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: coverUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _gradientCover(),
                          errorWidget: (_, __, ___) => _gradientCover(),
                        )
                      : _gradientCover(),
                  // Fade to background at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [bg, Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Profile info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar row + action buttons
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: bg, width: 3),
                          gradient: const LinearGradient(
                            colors: [AppColors.accentPrimary, AppColors.accentPrimaryDark],
                          ),
                        ),
                        child: ClipOval(
                          child: (avatarUrl != null && avatarUrl.isNotEmpty)
                              ? CachedNetworkImage(
                                  imageUrl: avatarUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => _avatarFallback(displayName),
                                  errorWidget: (_, __, ___) => _avatarFallback(displayName),
                                )
                              : _avatarFallback(displayName),
                        ),
                      ),
                      const Spacer(),
                      if (isCurrentUser)
                        OutlinedButton(
                          onPressed: () => context.push('/edit-profile'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.darkBorder),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Edit Profile'),
                        )
                      else ...[
                        ElevatedButton(
                          onPressed: () => setState(() => _isFollowing = !_isFollowing),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFollowing
                                ? AppColors.darkSurface
                                : AppColors.accentIndigo,
                            foregroundColor: AppColors.textPrimary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(_isFollowing ? 'Following' : 'Follow'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Start a conversation from the Messages tab'),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accentCyan,
                            side: const BorderSide(color: AppColors.accentCyan),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Message'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Name & verified badge
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: AppTextStyles.h1.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified_rounded,
                          color: AppColors.accentCyan,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@$username',
                    style: AppTextStyles.bodyM.copyWith(color: AppColors.mutedGray),
                  ),
                  const SizedBox(height: 10),

                  // Bio
                  Text(
                    bio,
                    style: AppTextStyles.bodyM.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  // Website
                  if (website != null && website.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.link_rounded,
                          color: AppColors.accentCyan, size: 14),
                      const SizedBox(width: 4),
                      Text(website,
                          style: AppTextStyles.bodyS.copyWith(
                              color: AppColors.accentCyan)),
                    ]),
                  ],
                  const SizedBox(height: 6),

                  // Joined date
                  Row(children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: AppColors.mutedGray, size: 13),
                    const SizedBox(width: 4),
                    Text(_joined(joinedDate),
                        style: AppTextStyles.bodyS.copyWith(
                            color: AppColors.mutedGray)),
                  ]),
                  const SizedBox(height: 20),

                  // Stats row
                  Row(
                    children: [
                      _StatItem(
                        value: _fmt(followersCount),
                        label: 'Followers',
                      ),
                      const SizedBox(width: 24),
                      _StatItem(
                        value: _fmt(followingCount),
                        label: 'Following',
                      ),
                      const SizedBox(width: 24),
                      _StatItem(
                        value: _fmt(debatesCreated),
                        label: 'Debates',
                      ),
                      const SizedBox(width: 24),
                      _StatItem(
                        value: _fmt(xp),
                        label: 'XP',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Connections button (own profile)
                  if (isCurrentUser)
                    OutlinedButton.icon(
                      onPressed: () => context.push('/connections'),
                      icon: const Icon(Icons.people_rounded,
                          color: AppColors.accentCyan, size: 18),
                      label: Text('My Connections',
                          style: AppTextStyles.bodyM.copyWith(
                              color: AppColors.accentCyan)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: AppColors.accentCyan, width: 1.5),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),

          // Achievements
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Achievements',
                      style: AppTextStyles.headlineM
                          .copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 5,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: [
                      _AchievementBadge(
                          emoji: '??', label: 'Champion', earned: xp > 1000),
                      _AchievementBadge(
                          emoji: '?', label: 'Active', earned: debatesCreated > 0),
                      _AchievementBadge(
                          emoji: '??',
                          label: 'Streak',
                          earned: (profile?.currentStreak ?? 0) > 2),
                      _AchievementBadge(
                          emoji: '??', label: 'Elite', earned: xp > 10000),
                      _AchievementBadge(
                          emoji: '??',
                          label: 'Sharp',
                          earned: (profile?.winRate ?? 0) > 0.5),
                      _AchievementBadge(
                          emoji: '?',
                          label: 'Popular',
                          earned: followersCount > 50),
                      _AchievementBadge(
                          emoji: '??',
                          label: 'Rising',
                          earned: (profile?.weeklyXp ?? 0) > 100),
                      _AchievementBadge(
                          emoji: '??', label: 'Legend', earned: xp > 50000),
                      _AchievementBadge(
                          emoji: '??',
                          label: 'Verified',
                          earned: isVerified),
                      _AchievementBadge(
                          emoji: '??',
                          label: 'Social',
                          earned: (profile?.connectionsCount ?? 0) > 5),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 48)),
        ],
      ),
    );
  }

  Widget _gradientCover() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accentLight,
              AppColors.accentPrimary,
              AppColors.accentPrimaryDark,
            ],
          ),
        ),
      );

  Widget _avatarFallback(String name) => Container(
        color: AppColors.accentIndigo.withValues(alpha: 0.3),
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'U',
            style: AppTextStyles.displayM.copyWith(color: AppColors.textPrimary),
          ),
        ),
      );

  Widget _buildErrorState(String err) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off_rounded,
                  color: AppColors.mutedGray, size: 64),
              const SizedBox(height: 16),
              Text('Profile unavailable',
                  style: AppTextStyles.headlineS
                      .copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(err,
                  style: AppTextStyles.bodyS
                      .copyWith(color: AppColors.mutedGray),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Go Back')),
            ],
          ),
        ),
      );

  void _showUserOptions(BuildContext ctx, String username) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final cardBg = AppColors.cardBackground(isDark);

    showModalBottomSheet(
      context: ctx,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
                color: AppColors.darkBorder,
                borderRadius: BorderRadius.circular(2)),
          ),
          ListTile(
            leading: const Icon(Icons.flag_rounded,
                color: AppColors.warningOrange),
            title: Text('Report @$username',
                style:
                    AppTextStyles.bodyM.copyWith(color: AppColors.textPrimary)),
            onTap: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report sent for review.')),
              );
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.block_rounded, color: AppColors.errorRed),
            title: Text('Block @$username',
                style: AppTextStyles.bodyM.copyWith(color: AppColors.errorRed)),
            onTap: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('@$username has been blocked.')),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// --- Helper Widgets ------------------------------------------------------------

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTextStyles.headlineS.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodyS.copyWith(color: AppColors.mutedGray),
        ),
      ],
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final String emoji;
  final String label;
  final bool earned;

  const _AchievementBadge(
      {required this.emoji, required this.label, required this.earned});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Container(
        decoration: BoxDecoration(
          gradient: earned
              ? const LinearGradient(
                  colors: [AppColors.accentPrimary, AppColors.accentPrimaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: earned ? null : AppColors.darkSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: earned
                ? AppColors.accentPrimary.withValues(alpha: 0.4)
                : AppColors.darkBorder,
          ),
        ),
        child: Center(
          child: Opacity(
            opacity: earned ? 1.0 : 0.25,
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
      ),
    );
  }
}
