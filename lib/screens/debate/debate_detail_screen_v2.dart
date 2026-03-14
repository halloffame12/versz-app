import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/debate.dart';
import '../../providers/debate_provider.dart';
import '../../providers/profile_provider.dart';
import '../../core/utils/url_utils.dart';

class DebateDetailScreenV2 extends ConsumerWidget {
  final Debate debate;

  const DebateDetailScreenV2({super.key, required this.debate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AppColors.backgroundColor(isDark);
    final cardBg = AppColors.cardBackground(isDark);
    final border = AppColors.borderColor(isDark);
    final text = AppColors.textColor(isDark);
    final muted = AppColors.mutedTextColor(isDark);

    final profileState = ref.watch(profileProvider(debate.creatorId));
    if (profileState.profile == null && !profileState.isLoading && profileState.error == null) {
      Future.microtask(() => ref.read(profileProvider(debate.creatorId).notifier).fetchProfile());
    }

    final debateState = ref.watch(debateProvider);
    final userVote = debateState.userVotes[debate.id];
    final isLiked = debateState.likedDebateIds.contains(debate.id);
    final isSaved = debateState.savedDebateIds.contains(debate.id);

    final author = profileState.profile;
    final totalVotes = debate.upvotes + debate.downvotes;
    final agreePct = totalVotes == 0 ? 0.0 : (debate.upvotes / totalVotes) * 100;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: bg,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.accentCyan),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accentPrimary.withValues(alpha: 0.25),
                      AppColors.accentPrimaryDark.withValues(alpha: 0.18),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debate.title,
                        style: AppTextStyles.headlineL.copyWith(
                          color: text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.accentPrimary, AppColors.accentPrimaryDark],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              debate.categoryId.isEmpty ? 'General' : debate.categoryId,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.visibility_rounded, color: AppColors.accentCyan, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${debate.viewCount} views',
                                style: AppTextStyles.labelSmall.copyWith(color: muted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.accentIndigo.withValues(alpha: 0.2),
                          backgroundImage: isValidNetworkUrl(author?.avatarUrl)
                              ? CachedNetworkImageProvider(author!.avatarUrl!)
                              : null,
                          child: !isValidNetworkUrl(author?.avatarUrl)
                              ? Text(
                                  (author?.displayName ?? 'U').substring(0, 1).toUpperCase(),
                                  style: AppTextStyles.labelL.copyWith(color: text),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                author?.displayName ?? 'User',
                                style: AppTextStyles.bodyL.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: text,
                                ),
                              ),
                              Text(
                                '@${author?.username ?? 'unknown'} • ${timeago.format(debate.createdAt)}',
                                style: AppTextStyles.bodyS.copyWith(color: muted),
                              ),
                            ],
                          ),
                        ),
                        if (author != null)
                          OutlinedButton(
                            onPressed: () => context.push('/profile/${author.id}'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.accentCyan,
                              side: const BorderSide(color: AppColors.accentCyan),
                            ),
                            child: const Text('Profile'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (debate.description != null && debate.description!.trim().isNotEmpty)
                      Text(
                        debate.description!,
                        style: AppTextStyles.bodyM.copyWith(color: text, height: 1.6),
                      ),
                    if (debate.mediaType == 'image' && isValidNetworkUrl(debate.mediaUrl)) ...[
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CachedNetworkImage(
                          imageUrl: debate.mediaUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 220,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Debate pulse', style: AppTextStyles.labelM.copyWith(color: muted)),
                              const Spacer(),
                              Text(
                                '${agreePct.toStringAsFixed(0)}% agree',
                                style: AppTextStyles.labelM.copyWith(
                                  color: AppColors.accentCyan,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: totalVotes == 0 ? 0.5 : debate.upvotes / totalVotes,
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(8),
                            backgroundColor: AppColors.errorRed.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.successGreen),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _statChip(
                                icon: Icons.trending_up_rounded,
                                label: '${debate.upvotes} Agree',
                                color: userVote == 1 ? AppColors.accentCyan : muted,
                              ),
                              const SizedBox(width: 8),
                              _statChip(
                                icon: Icons.trending_down_rounded,
                                label: '${debate.downvotes} Disagree',
                                color: userVote == -1 ? AppColors.errorRed : muted,
                              ),
                              const SizedBox(width: 8),
                              _statChip(
                                icon: Icons.mode_comment_outlined,
                                label: '${debate.commentCount} Comments',
                                color: muted,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _actionButton(
                          icon: Icons.thumb_up_alt_rounded,
                          label: 'Agree',
                          active: userVote == 1,
                          activeColor: AppColors.successGreen,
                          onTap: () => ref.read(debateProvider.notifier).castDebateVoteOptimistic(debate.id, 1),
                        ),
                        _actionButton(
                          icon: Icons.thumb_down_alt_rounded,
                          label: 'Disagree',
                          active: userVote == -1,
                          activeColor: AppColors.errorRed,
                          onTap: () => ref.read(debateProvider.notifier).castDebateVoteOptimistic(debate.id, -1),
                        ),
                        _actionButton(
                          icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          label: isLiked ? 'Liked' : 'Like',
                          active: isLiked,
                          activeColor: AppColors.errorRed,
                          onTap: () => ref.read(debateProvider.notifier).toggleLikeOptimistic(debate.id),
                        ),
                        _actionButton(
                          icon: isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                          label: isSaved ? 'Saved' : 'Save',
                          active: isSaved,
                          onTap: () => ref.read(debateProvider.notifier).toggleSaveOptimistic(debate.id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _statChip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label, style: AppTextStyles.labelSmall.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
    Color? activeColor,
  }) {
    final Color color = active ? (activeColor ?? AppColors.accentPrimary) : AppColors.textSecondary;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(
          color: active ? color : AppColors.darkBorder,
        ),
      ),
    );
  }
}
