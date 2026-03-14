import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/debate.dart';
import '../../providers/debate_provider.dart';
import '../../providers/profile_provider.dart';
import '../../core/utils/url_utils.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

class DebateCard extends ConsumerWidget {
  final Debate debate;
  final VoidCallback? onTap;

  const DebateCard({
    super.key,
    required this.debate,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider(debate.creatorId));
    final creator = profileState.profile;
    final debateState = ref.watch(debateProvider);
    final userVote = debateState.userVotes[debate.id];
    final isLiked = debateState.likedDebateIds.contains(debate.id);
    final isSaved = debateState.savedDebateIds.contains(debate.id);

    // Trigger fetch if not loaded
    if (creator == null && !profileState.isLoading && profileState.error == null) {
      Future.microtask(() => ref.read(profileProvider(debate.creatorId).notifier).fetchProfile());
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.darkBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap ?? () => context.push('/debate-detail', extra: debate),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Creator Info
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1.5),
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.background,
                          backgroundImage: isValidNetworkUrl(creator?.avatarUrl)
                              ? CachedNetworkImageProvider(creator!.avatarUrl!) 
                              : null,
                          child: !isValidNetworkUrl(creator?.avatarUrl)
                              ? const Icon(Icons.person, size: 20, color: AppColors.textMuted) 
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  creator?.displayName ?? 'User', 
                                  style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800),
                                ),
                                if (debate.status == 'active') ...[
                                  const SizedBox(width: 8),
                                  _buildLiveBadge(),
                                ],
                              ],
                            ),
                            Text(
                              timeago.format(debate.createdAt).toUpperCase(),
                              style: AppTextStyles.labelSmall.copyWith(fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.more_horiz_rounded, color: AppColors.textMuted),
                    ],
                  ),
                ),

                // Content: Title & Media
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    debate.title,
                    style: AppTextStyles.h3.copyWith(height: 1.3),
                  ),
                ),

                if (debate.description != null && debate.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      debate.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ),

                if (debate.mediaType == 'image' && isValidNetworkUrl(debate.mediaUrl))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: CachedNetworkImage(
                          imageUrl: debate.mediaUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: AppColors.surfaceLight),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                      ),
                    ),
                  ),

                // Footer: Stats & Actions
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Modern Vote Indicator
                      _buildVoteBar(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildStatPill(
                            Icons.trending_up,
                            userVote == 1 ? AppColors.success : AppColors.textPrimary,
                            '${debate.upvotes} AGREE',
                            onTap: () => ref.read(debateProvider.notifier).castDebateVoteOptimistic(debate.id, 1),
                          ),
                          const SizedBox(width: 12),
                          _buildStatPill(
                            Icons.trending_down,
                            userVote == -1 ? AppColors.error : AppColors.error,
                            '${debate.downvotes} DISAGREE',
                            onTap: () => ref.read(debateProvider.notifier).castDebateVoteOptimistic(debate.id, -1),
                          ),
                          const Spacer(),
                          _buildIconStat(Icons.mode_comment_outlined, '${debate.commentCount}'),
                          const SizedBox(width: 16),
                          _buildIconStat(
                            isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            '',
                            iconColor: isLiked ? AppColors.error : AppColors.textSecondary,
                            onTap: () => ref.read(debateProvider.notifier).toggleLikeOptimistic(debate.id),
                          ),
                          const SizedBox(width: 16),
                          _buildIconStat(
                            isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                            '',
                            iconColor: isSaved ? AppColors.primary : AppColors.textSecondary,
                            onTap: () => ref.read(debateProvider.notifier).toggleSaveOptimistic(debate.id),
                          ),
                          const SizedBox(width: 16),
                          _buildIconStat(
                            Icons.share_outlined,
                            '',
                            onTap: () async {
                              await Clipboard.setData(ClipboardData(text: 'versz.app/debate/${debate.id}'));
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Copied to clipboard')),
                              );
                            },
                          ),
                        ],
                      ),
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

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        'LIVE',
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.error, fontSize: 8, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _buildVoteBar() {
    final total = debate.upvotes + debate.downvotes;
    final agreePercent = total == 0 ? 0.5 : debate.upvotes / total;

    return Container(
      height: 8,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.errorRed.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                width: constraints.maxWidth * agreePercent,
                height: 8,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.successGreen, AppColors.agreeGreen],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.successGreen.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(IconData icon, Color color, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textPrimary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconStat(
    IconData icon,
    String count, {
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor ?? AppColors.textSecondary),
          if (count.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              count,
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
