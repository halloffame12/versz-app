import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/url_utils.dart';
import '../../providers/conversation_provider.dart';
import '../../models/user_account.dart';
import '../../models/conversation.dart';
import '../../widgets/common/state_widgets.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationsListProvider.notifier).fetchConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversationsState = ref.watch(conversationsListProvider);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.darkBackground,
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
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              title: Text(
                'MESSAGES',
                style: AppTextStyles.h2.copyWith(
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: AppColors.textPrimary,
                ),
              ),
              centerTitle: true,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.accentLight, AppColors.accentPrimary],
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppColors.darkBackground],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary),
                onPressed: () => _showSearchDialog(context),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
        body: Container(
          decoration: const BoxDecoration(
            color: AppColors.darkBackground,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
          ),
          child: conversationsState.isLoading
          ? SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: LoadingSkeleton(itemCount: 5, height: 100),
            )
          : conversationsState.error != null
              ? ErrorStateWidget(
                  title: 'Couldn\'t load messages',
                  message: 'Unable to fetch your conversations.',
                  errorDetails: conversationsState.error ?? 'Unknown error',
                  accentColor: AppColors.errorRed,
                  onRetry: () => ref.read(conversationsListProvider.notifier).fetchConversations(),
                )
              : conversationsState.conversations.isEmpty
                  ? EmptyStateWidget(
                      title: 'No messages yet',
                      subtitle: 'Start a conversation with someone to begin chatting.',
                      icon: Icons.forum_rounded,
                      iconColor: AppColors.accentTeal,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      itemCount: conversationsState.conversations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final conversationData = conversationsState.conversations[index];
                        // conversationData is already a Conversation model, not a Map
                        return _buildPremiumConversationTile(conversationData);
                      },
                    ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSearchDialog(context),
        backgroundColor: AppColors.primaryYellow,
        icon: const Icon(Icons.message_rounded, color: AppColors.primaryBlack),
        label: Text(
          'NEW',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.primaryBlack,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumConversationTile(dynamic conversation) {
    final currentUserId = ref.watch(conversationsListProvider.notifier).currentUserId;
    final otherParticipantName = currentUserId == conversation.participant1
      ? (conversation.participant2Name ?? conversation.participant2)
      : (conversation.participant1Name ?? conversation.participant1);
    final otherParticipantAvatar = currentUserId == conversation.participant1
      ? conversation.participant2Avatar
      : conversation.participant1Avatar;
    final unreadCount = currentUserId == conversation.participant1
      ? conversation.unreadCount1
      : conversation.unreadCount2;
    final lastMessageDate = conversation.lastMessageAt == null
      ? null
      : DateTime.tryParse(conversation.lastMessageAt as String);

    return Container(
      decoration: BoxDecoration(
        color: unreadCount > 0 ? AppColors.accentBlue.withValues(alpha: 0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: unreadCount > 0 ? AppColors.accentBlue.withValues(alpha: 0.4) : AppColors.darkBorder,
          width: 1,
        ),
        boxShadow: unreadCount > 0
            ? [BoxShadow(color: AppColors.accentBlue.withValues(alpha: 0.1), blurRadius: 12, spreadRadius: 0)]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/messages/${conversation.id}', extra: conversation),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: unreadCount > 0 ? AppColors.accentBlue : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.surface,
                      backgroundImage: isValidNetworkUrl(otherParticipantAvatar)
                          ? CachedNetworkImageProvider(otherParticipantAvatar)
                          : null,
                      child: !isValidNetworkUrl(otherParticipantAvatar)
                          ? Text(otherParticipantName[0].toUpperCase(),
                              style: AppTextStyles.labelLarge.copyWith(color: AppColors.accentTeal))
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                otherParticipantName,
                                style: AppTextStyles.labelLarge.copyWith(
                                  fontSize: 16,
                                  fontWeight: unreadCount > 0 ? FontWeight.w900 : FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (lastMessageDate != null)
                              Text(
                                timeago.format(lastMessageDate),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: unreadCount > 0 ? AppColors.accentBlue : AppColors.textMuted,
                                  fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (conversation.lastMessage != null)
                          Text(
                            conversation.lastMessage!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          Text(
                            'No messages yet',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontStyle: FontStyle.italic),
                          ),
                      ],
                    ),
                  ),
                  if (unreadCount > 0) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: AppColors.accentBlue.withValues(alpha: 0.45), blurRadius: 10, spreadRadius: -2),
                        ],
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primaryBlack,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    final searchController = TextEditingController();
    List<UserAccount> users = const [];
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> runSearch(String value) async {
            final query = value.trim();
            setModalState(() {
              isLoading = true;
            });

            final result = query.isEmpty
                ? <UserAccount>[]
                : await ref.read(conversationsListProvider.notifier).searchUsers(query);

            if (!mounted) return;
            setModalState(() {
              users = result;
              isLoading = false;
            });
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Start New Conversation', style: AppTextStyles.h3),
                const SizedBox(height: 12),
                TextField(
                  controller: searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search by username',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: runSearch,
                ),
                const SizedBox(height: 12),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(color: AppColors.accentBlue),
                  )
                else if (users.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      searchController.text.trim().isEmpty
                          ? 'Type to find people'
                          : 'No users found',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 360),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: users.length,
                      separatorBuilder: (_, __) => Divider(color: AppColors.darkBorder),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final avatar = isValidNetworkUrl(user.avatarUrl) ? user.avatarUrl : null;
                        final displayLabel = user.displayName.isEmpty ? user.username : user.displayName;
                        final initial = displayLabel.isEmpty ? '?' : displayLabel.substring(0, 1).toUpperCase();
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.background,
                            backgroundImage: avatar != null ? CachedNetworkImageProvider(avatar) : null,
                            child: avatar == null ? Text(initial) : null,
                          ),
                          title: Text(
                            displayLabel,
                            style: AppTextStyles.labelLarge,
                          ),
                          subtitle: Text('@${user.username}', style: AppTextStyles.bodySmall),
                          onTap: () async {
                            Navigator.pop(context);
                            await _openConversationWithUser(user);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openConversationWithUser(UserAccount user) async {
    final notifier = ref.read(conversationsListProvider.notifier);
    final conversationId = await notifier.ensureConversationWith(user.id);

    if (!mounted) return;

    if (conversationId == null) {
      final error = ref.read(conversationsListProvider).error ?? 'Unable to start conversation.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    await notifier.fetchConversations();
    if (!mounted) return;

    final state = ref.read(conversationsListProvider);
    final currentUserId = notifier.currentUserId;
    final conversation = state.conversations.where((c) => c.id == conversationId).firstWhere(
          (_) => true,
          orElse: () => Conversation(
            id: conversationId,
            participant1: currentUserId,
            participant2: user.id,
            participant1Name: 'You',
            participant2Name: user.displayName.isEmpty ? user.username : user.displayName,
            participant2Avatar: user.avatarUrl,
            lastMessage: '',
            lastMessageAt: DateTime.now().toIso8601String(),
          ),
        );

    context.push('/messages/$conversationId', extra: conversation);
  }
}