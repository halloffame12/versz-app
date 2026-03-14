import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/url_utils.dart';
import '../../models/comment.dart';
import '../../providers/profile_provider.dart';
import '../../providers/vote_provider.dart';

class CommentTile extends ConsumerWidget {
  final Comment comment;
  final String? voteType; // 'agree' or 'disagree' from parent context if needed

  const CommentTile({
    super.key,
    required this.comment,
    this.voteType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider(comment.userId));
    final creator = profileState.profile;
    final voteState = ref.watch(voteProvider('comment:${comment.id}'));

    // Trigger fetch if not loaded
    if (creator == null && !profileState.isLoading && profileState.error == null) {
      Future.microtask(() => ref.read(profileProvider(comment.userId).notifier).fetchProfile());
    }

    final isAgree = voteType == 'agree';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.surfaceLight,
          backgroundImage: isValidNetworkUrl(creator?.avatarUrl)
              ? CachedNetworkImageProvider(creator!.avatarUrl!)
              : null,
          child: !isValidNetworkUrl(creator?.avatarUrl)
              ? const Icon(Icons.person, size: 18, color: AppColors.textMuted)
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(creator?.displayName ?? 'User', style: AppTextStyles.labelLarge.copyWith(fontSize: 14)),
                  const SizedBox(width: 8),
                  if (voteType != null) 
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isAgree ? AppColors.textPrimary.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isAgree ? 'AGREE' : 'DISAGREE',
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 8,
                          color: isAgree ? AppColors.textPrimary : AppColors.error,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(timeago.format(comment.createdAt).toUpperCase(), style: AppTextStyles.labelSmall.copyWith(fontSize: 8)),
                ],
              ),
              const SizedBox(height: 6),
              Text(comment.content, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary.withValues(alpha: 0.9), height: 1.4)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildCommentAction(
                    icon: voteState.userVote == 1 ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                    label: '${comment.upvotes}',
                    color: voteState.userVote == 1 ? AppColors.accent : AppColors.textMuted,
                    onTap: () => ref.read(voteProvider('comment:${comment.id}').notifier).castVote(1),
                  ),
                  const SizedBox(width: 20),
                  _buildCommentAction(
                    icon: voteState.userVote == -1 ? Icons.thumb_down_rounded : Icons.thumb_down_outlined,
                    label: '${comment.downvotes}',
                    color: voteState.userVote == -1 ? AppColors.error : AppColors.textMuted,
                    onTap: () => ref.read(voteProvider('comment:${comment.id}').notifier).castVote(-1),
                  ),
                  const SizedBox(width: 20),
                  _buildCommentAction(
                    icon: Icons.reply_rounded,
                    label: 'REPLY',
                    color: AppColors.textMuted,
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            if (label != '0' && label.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(label, style: AppTextStyles.labelSmall.copyWith(color: color, fontSize: 10)),
            ],
          ],
        ),
      ),
    );
  }
}
