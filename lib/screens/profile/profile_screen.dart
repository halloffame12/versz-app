import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connection_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/badge_provider.dart';
import '../../providers/ui_preferences_provider.dart';
import '../../models/badge.dart';
import '../../core/utils/url_utils.dart';
import '../../widgets/common/verz_button.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? userId; // Null means current user
  const ProfileScreen({super.key, this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final uid = widget.userId ?? ref.read(authProvider).user?.id;
    if (uid != null) {
      // Delay provider modification until after widget build
      Future(() {
        ref.read(profileProvider(uid).notifier).fetchProfile();
      });
      if (widget.userId != null) {
        ref.read(connectionProvider.notifier).fetchStatus(uid);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(authProvider).user?.id;
    final targetId = widget.userId ?? currentUserId;
    
    if (targetId == null) {
       return const Scaffold(body: Center(child: Text('User not found')));
    }

    final profileState = ref.watch(profileProvider(targetId));
    final isMe = targetId == currentUserId;
    final connectionStatus = ref.watch(connectionStatusProvider(targetId));
    final isIncomingPending = ref.watch(connectionPendingIncomingProvider(targetId));

    final bannerUrl = profileState.profile?.coverImage;
    final validBannerUrl = isValidNetworkUrl(bannerUrl) ? bannerUrl : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.pop(context);
                } else {
                  context.go('/home');
                }
              },
            ),
            actions: [
              if (isMe)
                IconButton(
                  icon: const Icon(Icons.tune_rounded, color: AppColors.textPrimary),
                  onPressed: _showUiPreferences,
                ),
              if (isMe)
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
                  onPressed: () => context.push('/settings'),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  validBannerUrl != null
                      ? CachedNetworkImage(imageUrl: validBannerUrl, fit: BoxFit.cover)
                      : Container(decoration: const BoxDecoration(gradient: AppColors.premiumGradient)),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x1A000000)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.translate(
                  offset: const Offset(0, -50),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildAvatar(profileState.profile?.avatarUrl),
                      const Spacer(),
                      if (isMe)
                        VerzButton(
                          text: 'EDIT PROFILE',
                          isFullWidth: false,
                          isOutlined: true,
                          onPressed: () {},
                        )
                      else
                        _buildConnectionActions(
                          targetId: targetId,
                          status: connectionStatus,
                          incomingPending: isIncomingPending,
                        ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profileState.profile?.displayName ?? 'User', style: AppTextStyles.h1),
                      Text(
                        '@${profileState.profile?.username ?? 'username'}', 
                        style: AppTextStyles.labelMedium.copyWith(color: AppColors.primaryYellow, fontWeight: FontWeight.bold),
                      ),
                      if (profileState.profile?.bio != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          profileState.profile!.bio!, 
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
                        ),
                      ],
                      const SizedBox(height: 32),
                      _buildStatsContainer(profileState.profile),
                      const SizedBox(height: 40),
                      Text('BADGES', style: AppTextStyles.labelMedium.copyWith(letterSpacing: 2)),
                      const SizedBox(height: 16),
                      _buildBadgesSection(targetId),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionActions({
    required String targetId,
    required ConnectionStatus status,
    required bool incomingPending,
  }) {
    final notifier = ref.read(connectionProvider.notifier);

    if (status == ConnectionStatus.blocked) {
      return const SizedBox.shrink();
    }

    if (status == ConnectionStatus.connected) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          VerzButton(
            text: 'CONNECTED',
            isFullWidth: false,
            backgroundColor: AppColors.surfaceLight,
            textColor: AppColors.textPrimary,
            onPressed: null,
          ),
          const SizedBox(width: 8),
          VerzButton(
            text: 'MESSAGE',
            isFullWidth: false,
            onPressed: () => context.push('/messages'),
          ),
        ],
      );
    }

    if (status == ConnectionStatus.pending) {
      if (incomingPending) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            VerzButton(
              text: 'ACCEPT',
              isFullWidth: false,
              onPressed: () => notifier.acceptRequest(targetId),
            ),
            const SizedBox(width: 8),
            VerzButton(
              text: 'DECLINE',
              isFullWidth: false,
              isOutlined: true,
              onPressed: () => notifier.declineRequest(targetId),
            ),
          ],
        );
      }

      return VerzButton(
        text: 'PENDING...',
        isFullWidth: false,
        backgroundColor: AppColors.surfaceLight,
        textColor: AppColors.textPrimary,
        onPressed: () => notifier.withdrawRequest(targetId),
      );
    }

    if (status == ConnectionStatus.follow) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          VerzButton(
            text: 'FOLLOWING',
            isFullWidth: false,
            backgroundColor: AppColors.surfaceLight,
            textColor: AppColors.textPrimary,
            onPressed: () => notifier.unfollow(targetId),
          ),
          const SizedBox(width: 8),
          VerzButton(
            text: 'CONNECT',
            isFullWidth: false,
            onPressed: () => notifier.sendConnectionRequest(targetId),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        VerzButton(
          text: 'FOLLOW',
          isFullWidth: false,
          onPressed: () => notifier.follow(targetId),
        ),
        const SizedBox(width: 8),
        VerzButton(
          text: 'CONNECT',
          isFullWidth: false,
          isOutlined: true,
          onPressed: () => notifier.sendConnectionRequest(targetId),
        ),
      ],
    );
  }

  Widget _buildAvatar(String? url) {
    final validAvatarUrl = isValidNetworkUrl(url) ? url : null;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: AppColors.accentBlue.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2)],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.6), width: 2.5),
        ),
        child: CircleAvatar(
          radius: 50,
          backgroundColor: AppColors.surface,
          backgroundImage: validAvatarUrl != null ? CachedNetworkImageProvider(validAvatarUrl) : null,
          child: validAvatarUrl == null ? const Icon(Icons.person, size: 50, color: AppColors.textMuted) : null,
        ),
      ),
    );
  }

  Widget _buildStatsContainer(dynamic profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.darkBorder, width: 1),
        boxShadow: [BoxShadow(color: AppColors.accentBlue.withValues(alpha: 0.06), blurRadius: 20, spreadRadius: 0)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('XP', '${profile?.xp ?? 0}'),
          _buildDivider(),
          _buildStatItem('FOLLOWERS', '${profile?.followersCount ?? 0}'),
          _buildDivider(),
          _buildStatItem('FOLLOWING', '${profile?.followingCount ?? 0}'),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 30, width: 1, color: AppColors.darkBorder);
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.labelSmall.copyWith(fontSize: 8)),
      ],
    );
  }

  Widget _buildBadgesSection(String userId) {
    final userBadgesState = ref.watch(userBadgesProvider);

    if (userBadgesState.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (userBadgesState.badges.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.darkCardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.darkBorder, width: 1),
        ),
        child: Center(
          child: Text('NO BADGES YET', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted)),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: userBadgesState.badges.length,
      itemBuilder: (context, index) => _buildBadgeCard(userBadgesState.badges[index]),
    );
  }

  Widget _buildBadgeCard(UserBadge userBadge) {
    // Static mapping for demo purposes, in real app would use a provider
    final badgeInfo = {
      'firstDebate': ('🌱', 'FIRST DEBATE'),
      'debater': ('🎙️', 'DEBATER'),
      'commentator': ('💬', 'COMMENTATOR'),
      'voter': ('🗳️', 'VOTER'),
    }[userBadge.badgeId] ?? ('🏅', 'BADGE');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(badgeInfo.$1, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            badgeInfo.$2,
            style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w900, fontSize: 8),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showUiPreferences() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final prefs = ref.watch(uiPreferencesProvider);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Subtle Chat Feedback'),
                      subtitle: const Text('Use lighter retry success pulse in direct messages.'),
                      trailing: Switch.adaptive(
                        value: prefs.subtleChatFeedback,
                        activeTrackColor: AppColors.accentTeal,
                        onChanged: (value) {
                          ref.read(uiPreferencesProvider.notifier).setSubtleChatFeedback(value);
                        },
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Fast Retry Animations'),
                      subtitle: const Text('Speed up retry transitions and success confirmation timing.'),
                      trailing: Switch.adaptive(
                        value: prefs.fastRetryAnimations,
                        activeTrackColor: AppColors.accentTeal,
                        onChanged: (value) {
                          ref.read(uiPreferencesProvider.notifier).setFastRetryAnimations(value);
                        },
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () async {
                          await ref.read(uiPreferencesProvider.notifier).resetToDefaults();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Chat feedback preferences reset to defaults.')),
                          );
                        },
                        icon: const Icon(Icons.restart_alt_rounded, size: 16),
                        label: const Text('Reset Defaults'),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
