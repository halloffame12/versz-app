import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/conversation_provider.dart';

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
            backgroundColor: AppColors.background.withValues(alpha: 0.8),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              title: Text(
                'MESSAGES',
                style: AppTextStyles.h2.copyWith(
                  letterSpacing: 4,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.premiumGradient,
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded, color: Colors.white),
                onPressed: () => _showSearchDialog(context),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
        body: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
          ),
          child: conversationsState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : conversationsState.conversations.isEmpty
              ? _buildEmptyState()
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
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.message_rounded, color: Colors.black),
        label: Text('NEW', style: AppTextStyles.labelMedium.copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceLight.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.2), width: 2),
              ),
              child: const Icon(Icons.forum_rounded, size: 64, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            Text('No Messages Yet', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            Text(
              'Start a conversation, debate privately, or share your thoughts with someone new.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showSearchDialog(context),
              icon: const Icon(Icons.search_rounded, color: Colors.black),
              label: Text('FIND PEOPLE', style: AppTextStyles.labelMedium.copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
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
        color: unreadCount > 0 ? AppColors.surfaceLight.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: unreadCount > 0 ? AppColors.primary.withValues(alpha: 0.3) : AppColors.surfaceLight.withValues(alpha: 0.1),
          width: 1,
        ),
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
                        color: unreadCount > 0 ? AppColors.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.surface,
                      backgroundImage: otherParticipantAvatar != null
                          ? CachedNetworkImageProvider(otherParticipantAvatar)
                          : null,
                      child: otherParticipantAvatar == null
                          ? Text(otherParticipantName[0].toUpperCase(),
                              style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary))
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
                                  color: unreadCount > 0 ? AppColors.primary : AppColors.textMuted,
                                  fontSize: 10,
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
                              color: unreadCount > 0 ? Colors.white : AppColors.textSecondary,
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
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: AppColors.primary, blurRadius: 10, spreadRadius: -2),
                        ],
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.black,
                          fontSize: 10,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Start New Conversation', style: AppTextStyles.h3),
        content: Text('Search functionality will be implemented here.',
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
}