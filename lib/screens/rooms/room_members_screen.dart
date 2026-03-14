import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/url_utils.dart';
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
  final TextEditingController _inviteSearchController = TextEditingController();

  @override
  void dispose() {
    _inviteSearchController.dispose();
    super.dispose();
  }

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
                backgroundImage: isValidNetworkUrl(member.avatarUrl)
                  ? CachedNetworkImageProvider(member.avatarUrl!)
                  : null,
                child: !isValidNetworkUrl(member.avatarUrl)
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
                    '${member.followersCount} followers',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMuted,
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
    List<dynamic> results = const [];
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> runSearch(String query) async {
            setModalState(() => isLoading = true);
            final users = await ref
                .read(roomMembersProvider(widget.room.id).notifier)
                .searchUsers(query);
            if (!mounted) return;
            setModalState(() {
              results = users;
              isLoading = false;
            });
          }

          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text('Invite Members', style: AppTextStyles.h3),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _inviteSearchController,
                    decoration: const InputDecoration(
                      hintText: 'Search users',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: runSearch,
                  ),
                  const SizedBox(height: 12),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  else if (results.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        _inviteSearchController.text.trim().isEmpty
                            ? 'Type a username to find people'
                            : 'No users found',
                        style: AppTextStyles.bodySmall,
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final user = results[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundImage: isValidNetworkUrl(user.avatarUrl)
                                  ? CachedNetworkImageProvider(user.avatarUrl!)
                                  : null,
                              child: !isValidNetworkUrl(user.avatarUrl)
                                  ? Text(user.displayName.isEmpty ? '?' : user.displayName[0].toUpperCase())
                                  : null,
                            ),
                            title: Text(user.displayName, style: AppTextStyles.labelLarge),
                            subtitle: Text('@${user.username}'),
                            trailing: TextButton(
                              onPressed: () async {
                                await ref
                                    .read(roomMembersProvider(widget.room.id).notifier)
                                    .addMember(user.id);
                                if (!mounted) return;
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(content: Text('${user.displayName} invited to room')),
                                );
                              },
                              child: const Text('Invite'),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
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
    ref.read(roomMembersProvider(widget.room.id).notifier).makeAdmin(member.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${member.displayName} is now a room admin'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}