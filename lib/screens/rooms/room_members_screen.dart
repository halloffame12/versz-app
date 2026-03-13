import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/room.dart';
import '../../providers/room_members_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/verz_card.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RoomMembersScreen extends ConsumerStatefulWidget {
  final Room room;
  const RoomMembersScreen({super.key, required this.room});

  @override
  ConsumerState<RoomMembersScreen> createState() => _RoomMembersScreenState();
}

class _RoomMembersScreenState extends ConsumerState<RoomMembersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(roomMembersProvider(widget.room.id).notifier).fetchMembers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final membersState = ref.watch(roomMembersProvider(widget.room.id));
    final currentUserId = ref.watch(authProvider).user?.id;
    final isOwner = currentUserId == widget.room.creatorId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('${widget.room.name} Members'),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () => _showInviteDialog(context),
            ),
        ],
      ),
      body: membersState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : membersState.members.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: membersState.members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final member = membersState.members[index];
                    return _buildMemberTile(member, isOwner, currentUserId == member.id);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text('No members found', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text('This room has no members yet',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildMemberTile(dynamic member, bool isOwner, bool isCurrentUser) {
    return VerzCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.surface,
              backgroundImage: member.avatarUrl != null
                  ? CachedNetworkImageProvider(member.avatarUrl!)
                  : null,
              child: member.avatarUrl == null
                  ? Text(member.displayName[0].toUpperCase(),
                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        member.displayName,
                        style: AppTextStyles.labelLarge,
                      ),
                      if (isCurrentUser)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'You',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    '@${member.username}',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                  ),
                  Text(
                    'Joined ${member.joinedAt != null ? _formatDate(member.joinedAt) : 'recently'}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (isOwner && !isCurrentUser)
              PopupMenuButton<String>(
                onSelected: (value) => _handleMemberAction(value, member),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'remove',
                    child: Text('Remove from room'),
                  ),
                  const PopupMenuItem(
                    value: 'make_admin',
                    child: Text('Make admin'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Invite Members', style: AppTextStyles.h3),
        content: Text('Invite functionality will be implemented here.',
            style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleMemberAction(String action, dynamic member) {
    switch (action) {
      case 'remove':
        _showRemoveConfirmation(member);
        break;
      case 'make_admin':
        _makeUserAdmin(member);
        break;
    }
  }

  void _showRemoveConfirmation(dynamic member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Remove Member', style: AppTextStyles.h3),
        content: Text('Are you sure you want to remove ${member.displayName} from this room?',
            style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeMemberAction(member);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _removeMemberAction(dynamic member) {
    ref.read(roomMembersProvider(widget.room.id).notifier).removeMember(member.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${member.displayName} has been removed from the room')),
    );
  }

  void _makeUserAdmin(dynamic member) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${member.displayName} is now a room admin'),
        duration: const Duration(seconds: 2),
      ),
    );
    // TODO: Implement admin assignment in room_members_provider
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}