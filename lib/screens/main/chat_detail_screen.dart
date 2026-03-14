import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/room.dart';
import '../../providers/message_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatDetailScreen extends ConsumerStatefulWidget {
  final Room room;
  const ChatDetailScreen({super.key, required this.room});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(messageProvider(widget.room.id).notifier).fetchMessages();
      ref.read(messageProvider(widget.room.id).notifier).subscribe();
    });
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isNotEmpty) {
      await ref.read(messageProvider(widget.room.id).notifier).sendMessage(_messageController.text.trim());
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final messageState = ref.watch(messageProvider(widget.room.id));
    final currentUserId = messageState.currentUserId;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.darkText, size: 20),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/rooms');
            }
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentTeal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accentTeal.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.groups_rounded, color: AppColors.accentTeal, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.room.name,
                    style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${widget.room.memberCount ?? 0} members',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.accentTeal,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.darkBorder),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messageState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accentTeal, strokeWidth: 2),
                  )
                : messageState.messages.isEmpty
                    ? _buildEmptyMessages()
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: messageState.messages.length,
                        itemBuilder: (context, index) {
                          final message = messageState.messages[index];
                          final isCurrentUser = currentUserId != null && message.senderId == currentUserId;
                          final isRetrying = messageState.retryingMessageIds.contains(message.id);
                          final isRetrySuccess = messageState.retrySuccessMessageIds.contains(message.id);
                          return _buildMessageBubble(
                            message,
                            isCurrentUser: isCurrentUser,
                            isRetrying: isRetrying,
                            isRetrySuccess: isRetrySuccess,
                          );
                        },
                      ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyMessages() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentTeal.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.accentTeal.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.accentTeal, size: 36),
          ),
          const SizedBox(height: 16),
          Text('Be the first to say something!', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }

  // Deterministic color for a sender name
  Color _senderColor(String name) {
    final colors = [
      AppColors.accentBlue,
      AppColors.accentTeal,
      AppColors.primaryYellow,
      AppColors.accentOrange,
      AppColors.errorRed,
    ];
    final idx = name.isNotEmpty ? name.codeUnitAt(0) % colors.length : 0;
    return colors[idx];
  }

  Widget _buildMessageBubble(
    dynamic message, {
    required bool isCurrentUser,
    required bool isRetrying,
    required bool isRetrySuccess,
  }) {
    final failed = message.status == 'failed';
    final name = message.senderName ?? 'User';
    final senderColor = _senderColor(name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          child: Column(
            crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isCurrentUser)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    name,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: senderColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              GestureDetector(
                onTap: failed
                    ? () => ref.read(messageProvider(widget.room.id).notifier).retryFailedMessage(message.id)
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isCurrentUser
                        ? AppColors.accentTeal.withValues(alpha: 0.18)
                        : AppColors.darkCardBg,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
                      bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
                    ),
                    border: Border.all(
                      color: isCurrentUser
                          ? AppColors.accentTeal.withValues(alpha: 0.4)
                          : AppColors.darkBorder,
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.darkText,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeago.format(message.createdAt),
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 10),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 4),
                      if (isRetrying)
                        const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.accentTeal),
                        )
                      else if (isRetrySuccess)
                        const Icon(Icons.check_circle_rounded, size: 12, color: AppColors.accentTeal)
                      else if (failed)
                        const Icon(Icons.refresh_rounded, size: 12, color: AppColors.errorRed)
                      else
                        Icon(
                          message.status == 'read' ? Icons.done_all_rounded : Icons.check_rounded,
                          size: 12,
                          color: message.status == 'read' ? AppColors.accentTeal : AppColors.textMuted,
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    final state = ref.watch(messageProvider(widget.room.id));

    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).viewPadding.bottom + 12),
      decoration: const BoxDecoration(
        color: AppColors.darkCardBg,
        border: Border(top: BorderSide(color: AppColors.darkBorder, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                state.error!,
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.errorRed),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: TextField(
                    controller: _messageController,
                    onChanged: (_) => setState(() {}),
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.darkText),
                    decoration: InputDecoration(
                      hintText: 'Message the room...',
                      hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    minLines: 1,
                    maxLines: 4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: _messageController.text.trim().isNotEmpty
                      ? const LinearGradient(
                          colors: [AppColors.accentTeal, AppColors.accentBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [AppColors.darkSurface, AppColors.darkSurface],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  shape: BoxShape.circle,
                  boxShadow: _messageController.text.trim().isNotEmpty
                      ? [BoxShadow(color: AppColors.accentTeal.withValues(alpha: 0.4), blurRadius: 12)]
                      : [],
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: _messageController.text.trim().isEmpty ? null : _sendMessage,
                  icon: Icon(
                    Icons.send_rounded,
                    color: _messageController.text.trim().isNotEmpty ? AppColors.primaryBlack : AppColors.textMuted,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
