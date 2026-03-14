import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/conversation_provider.dart';
import '../../widgets/common/state_widgets.dart';

class ConversationsScreenV2 extends ConsumerStatefulWidget {
  const ConversationsScreenV2({super.key});

  @override
  ConsumerState<ConversationsScreenV2> createState() => _ConversationsScreenV2State();
}

class _ConversationsScreenV2State extends ConsumerState<ConversationsScreenV2> with TickerProviderStateMixin {
  late AnimationController _fabAnimation;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fabAnimation = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationsListProvider.notifier).fetchConversations();
    });
  }

  @override
  void dispose() {
    _fabAnimation.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversationsState = ref.watch(conversationsListProvider);
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
          onPressed: () => context.push('/start-new-conversation'),
          backgroundColor: AppColors.accentCyan,
          label: const Text('NEW'),
          icon: const Icon(Icons.add_rounded),
        ),
      ),
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.accentLight, AppColors.accentPrimary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'MESSAGES',
            style: AppTextStyles.headlineL.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary),
                onPressed: () {
                  // Implement search functionality
                },
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: AppTextStyles.bodyM.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search conversations',
                hintStyle: AppTextStyles.bodyM.copyWith(color: AppColors.mutedGray),
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.accentCyan),
                filled: true,
                fillColor: cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.accentIndigo.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.accentIndigo.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.accentCyan,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),

          // Conversations List
          Expanded(
            child: conversationsState.isLoading && conversationsState.conversations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation(AppColors.accentPurple),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading conversations...',
                          style: AppTextStyles.bodyM.copyWith(
                            color: AppColors.mutedGray,
                          ),
                        ),
                      ],
                    ),
                  )
                : conversationsState.error != null && conversationsState.conversations.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: ErrorStateWidget(
                          title: 'Couldn\'t load messages',
                          message: 'Unable to fetch conversations',
                          errorDetails: conversationsState.error ?? 'Unable to fetch your conversations',
                          onRetry: () {
                            ref.read(conversationsListProvider.notifier).fetchConversations();
                          },
                        ),
                      )
                    : conversationsState.conversations.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: EmptyStateWidget(
                              title: 'No messages yet',
                              subtitle: 'Start a conversation with someone to begin chatting',
                              icon: Icons.forum_rounded,
                              iconColor: AppColors.accentPurple,
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            itemCount: conversationsState.conversations.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final conversation = conversationsState.conversations[index];
                              final otherUserName = conversation.participant1Name ?? 'User';
                              final otherUserAvatar = conversation.participant1Avatar;

                              // Filter by search
                              if (_searchQuery.isNotEmpty &&
                                  !otherUserName.toLowerCase().contains(_searchQuery.toLowerCase())) {
                                return const SizedBox.shrink();
                              }

                              return GestureDetector(
                                onTap: () => context.push('/chat/${conversation.id}'),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.accentIndigo.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Avatar
                                      Stack(
                                        children: [
                                          Container(
                                            width: 56,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  AppColors.accentPurple.withValues(alpha: 0.5),
                                                  AppColors.accentIndigo.withValues(alpha: 0.5),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(28),
                                              border: Border.all(
                                                color: AppColors.accentCyan.withValues(alpha: 0.5),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: otherUserAvatar != null
                                                ? null // Would show cached network image here
                                                : Center(
                                                    child: Text(
                                                      otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
                                                      style: AppTextStyles.headlineM.copyWith(
                                                        color: AppColors.textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                          ),
                                          // Online indicator
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              width: 14,
                                              height: 14,
                                              decoration: BoxDecoration(
                                                color: AppColors.accentCyan,
                                                borderRadius: BorderRadius.circular(7),
                                                border: Border.all(
                                                  color: cardBg,
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      // Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              otherUserName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTextStyles.bodyL.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              conversation.lastMessage ?? 'No messages yet',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTextStyles.bodyS.copyWith(
                                                color: AppColors.mutedGray,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Unread badge
                                      if (conversation.unreadCount1 > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [AppColors.accentPrimary, AppColors.accentPrimaryDark],
                                            ),
                                            borderRadius: BorderRadius.circular(99),
                                          ),
                                          child: Text(
                                            '${conversation.unreadCount1}',
                                            style: AppTextStyles.labelSmall.copyWith(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
