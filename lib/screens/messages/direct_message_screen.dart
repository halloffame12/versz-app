import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/conversation.dart';
import '../../models/message.dart' as model;
import '../../providers/conversation_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connection_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/ui_preferences_provider.dart';
import '../../widgets/common/verz_text_field.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';

class DirectMessageScreen extends ConsumerStatefulWidget {
  final Conversation conversation;
  const DirectMessageScreen({super.key, required this.conversation});

  @override
  ConsumerState<DirectMessageScreen> createState() => _DirectMessageScreenState();
}

class _DirectMessageScreenState extends ConsumerState<DirectMessageScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _typingDebounce;
  bool _lastTypingSent = false;
  bool _canMessage = true;
  bool _isCheckingConnection = true;

  @override
  void initState() {
    super.initState();
    ref.listenManual(conversationProvider(widget.conversation.id), (prev, next) {
      if (!mounted) return;
      final msg = next.error;
      if (msg != null && msg.isNotEmpty && msg != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlySendError(msg))),
        );
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(conversationProvider(widget.conversation.id).notifier);
      notifier.fetchMessages();
      notifier.subscribe();
      final currentUserId = ref.read(authProvider).user?.id;
      if (currentUserId != null) {
        notifier.markIncomingAsRead(currentUserId);
      }
      _checkConnectionAccess();
    });

    _messageController.addListener(_handleTypingChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleTypingChanged);
    _typingDebounce?.cancel();
    if (_lastTypingSent) {
      ref.read(conversationProvider(widget.conversation.id).notifier).updateTyping(isTyping: false);
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      _messageController.clear();
      await ref.read(conversationProvider(widget.conversation.id).notifier).sendMessage(text);
      ref.read(conversationProvider(widget.conversation.id).notifier).updateTyping(isTyping: false);
      _lastTypingSent = false;
      // Scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _handleTypingChanged() {
    if (!_canMessage) return;

    final notifier = ref.read(conversationProvider(widget.conversation.id).notifier);
    final hasText = _messageController.text.trim().isNotEmpty;

    if (hasText != _lastTypingSent) {
      notifier.updateTyping(isTyping: hasText);
      _lastTypingSent = hasText;
    }

    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 1200), () {
      if (_lastTypingSent) {
        notifier.updateTyping(isTyping: false);
        _lastTypingSent = false;
      }
    });
  }

  Future<void> _checkConnectionAccess() async {
    final otherId = _getOtherParticipantId();
    final connected = await ref.read(connectionProvider.notifier).isConnectedWith(otherId);
    if (!mounted) return;
    setState(() {
      _canMessage = connected;
      _isCheckingConnection = false;
    });
  }

  String _friendlySendError(String raw) {
    final message = raw.toLowerCase();
    if (message.contains('permission') || message.contains('unauthorized') || message.contains('forbidden')) {
      return 'You do not have permission to send this message.';
    }
    if (message.contains('network') || message.contains('socket') || message.contains('timeout')) {
      return 'Network issue while sending. Tap retry.';
    }
    return 'Message failed to send. Tap retry.';
  }

  String _getOtherParticipantName() {
    final currentUserId = ref.read(authProvider).user?.id;
    if (currentUserId == widget.conversation.participant1) {
      return widget.conversation.participant2;
    }
    return widget.conversation.participant1;
  }

  String _getOtherParticipantId() {
    final currentUserId = ref.read(authProvider).user?.id;
    if (currentUserId == widget.conversation.participant1) {
      return widget.conversation.participant2;
    }
    return widget.conversation.participant1;
  }

  String? _getOtherParticipantAvatar() {
    final currentUserId = ref.watch(authProvider).user?.id;
    if (currentUserId == widget.conversation.participant1) {
      return null; // Avatar not in Conversation model
    }
    return null; // Avatar not in Conversation model
  }

  @override
  Widget build(BuildContext context) {
    final conversationState = ref.watch(conversationProvider(widget.conversation.id));
    final currentUserId = ref.watch(authProvider).user?.id;
    final uiPrefs = ref.watch(uiPreferencesProvider);
    final subtleChatFeedback = uiPrefs.subtleChatFeedback;
    final fastRetryAnimations = uiPrefs.fastRetryAnimations;
    final otherParticipantName = _getOtherParticipantName();
    final otherParticipantAvatar = _getOtherParticipantAvatar();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.surface,
              backgroundImage: otherParticipantAvatar != null
                  ? CachedNetworkImageProvider(otherParticipantAvatar)
                  : null,
              child: otherParticipantAvatar == null
                  ? Text(otherParticipantName[0].toUpperCase(),
                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(otherParticipantName, style: AppTextStyles.labelLarge),
                  Text('Direct Message', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptionsMenu(context),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isCheckingConnection)
            const LinearProgressIndicator(minHeight: 2, color: AppColors.primary),
          if (!_isCheckingConnection && !_canMessage)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.surface,
              child: Text(
                'Messaging is locked. You can only message connected users.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ),
          Expanded(
            child: conversationState.isLoading && conversationState.messages.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : ListView.separated(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: conversationState.messages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final message = conversationState.messages[index];
                      final isCurrentUser = message.senderId == currentUserId;
                      final isRetrying = conversationState.retryingMessageIds.contains(message.id);
                      final didRetrySucceed = conversationState.retrySuccessMessageIds.contains(message.id);
                      return _buildMessageBubble(
                        message,
                        isCurrentUser,
                        isRetrying,
                        didRetrySucceed,
                        subtleChatFeedback,
                        fastRetryAnimations,
                      );
                    },
                  ),
          ),
          if (conversationState.isOtherUserTyping)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '$otherParticipantName is typing...',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    model.Message message,
    bool isCurrentUser,
    bool isRetrying,
    bool didRetrySucceed,
    bool subtleFeedback,
    bool fastRetryAnimations,
  ) {
    final isFailed = isCurrentUser && message.status.toLowerCase() == 'failed';

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            Row(
              children: [
                Text(message.senderId, style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold
                )),
                const SizedBox(width: 8),
                Text(timeago.format(message.createdAt),
                    style: AppTextStyles.labelSmall.copyWith(fontSize: 10)),
              ],
            ),
            const SizedBox(height: 4),
          ],
          AnimatedScale(
            scale: didRetrySucceed ? (subtleFeedback ? 1.018 : 1.03) : 1,
            duration: Duration(
              milliseconds: fastRetryAnimations
                  ? (subtleFeedback ? 120 : 150)
                  : (subtleFeedback ? 170 : 220),
            ),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: Duration(
                milliseconds: fastRetryAnimations
                    ? (subtleFeedback ? 120 : 150)
                    : (subtleFeedback ? 170 : 220),
              ),
              curve: Curves.easeOut,
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrentUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isCurrentUser ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isCurrentUser ? const Radius.circular(4) : const Radius.circular(16),
                ),
                border: didRetrySucceed
                    ? Border.all(
                        color: Colors.white.withValues(alpha: subtleFeedback ? 0.35 : 0.65),
                        width: 1,
                      )
                    : null,
                boxShadow: didRetrySucceed
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: subtleFeedback ? 0.14 : 0.26),
                          blurRadius: subtleFeedback ? 8 : 12,
                          spreadRadius: subtleFeedback ? 0 : 1,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                message.content,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isCurrentUser ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          if (isCurrentUser)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeago.format(message.createdAt),
                    style: AppTextStyles.labelSmall.copyWith(fontSize: 8, color: AppColors.textMuted),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _statusIcon(message),
                    size: 12,
                    color: _statusColor(message),
                  ),
                ],
              ),
            ),
          if (isFailed)
            TextButton.icon(
              onPressed: isRetrying
                  ? null
                  : () {
                      ref
                          .read(conversationProvider(widget.conversation.id).notifier)
                          .retryFailedMessage(
                            message.id,
                            message.content,
                            successHoldMillis: fastRetryAnimations ? 160 : 260,
                          );
                    },
              icon: AnimatedSwitcher(
                duration: Duration(milliseconds: fastRetryAnimations ? 120 : 180),
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                child: isRetrying
                    ? const SizedBox(
                        key: ValueKey('retrying_icon'),
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        key: ValueKey('retry_icon'),
                        size: 14,
                      ),
              ),
              label: AnimatedSwitcher(
                duration: Duration(milliseconds: fastRetryAnimations ? 120 : 180),
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                child: Text(
                  isRetrying ? 'Retrying...' : 'Retry',
                  key: ValueKey(isRetrying ? 'retrying_label' : 'retry_label'),
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }

  IconData _statusIcon(model.Message message) {
    final s = message.status.toLowerCase();
    if (s == 'failed') return Icons.error_outline_rounded;
    if (s == 'sending') return Icons.schedule_rounded;
    if (s == 'read' || message.isRead) return Icons.done_all_rounded;
    if (s == 'delivered') return Icons.done_all_rounded;
    return Icons.done_rounded;
  }

  Color _statusColor(model.Message message) {
    final s = message.status.toLowerCase();
    if (s == 'failed') return AppColors.error;
    if (s == 'read' || message.isRead) return AppColors.primary;
    return AppColors.textMuted;
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surface.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Expanded(
            child: VerzTextField(
              label: '',
              controller: _messageController,
              hintText: 'Type a message...',
              maxLines: 1,
              enabled: _canMessage,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _canMessage ? _sendMessage : null,
            icon: const Icon(Icons.send),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.block, color: Colors.red),
            title: const Text('Block User'),
            onTap: () {
              Navigator.pop(context);
              _blockUser();
            },
          ),
          ListTile(
            leading: const Icon(Icons.report, color: Colors.orange),
            title: const Text('Report Conversation'),
            onTap: () {
              Navigator.pop(context);
              _reportConversation();
            },
          ),
        ],
      ),
    );
  }

  void _blockUser() {
    // Block implementation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('User blocked. Conversations with them are hidden.'),
        duration: Duration(seconds: 2),
      ),
    );
    // TODO: Integrate with block_provider when created
  }

  void _reportConversation() {
    // Report implementation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conversation reported. Our team will review it.'),
        duration: Duration(seconds: 2),
      ),
    );
    ref.read(reportProvider.notifier).reportContent(
      targetId: widget.conversation.id,
      targetType: 'conversation',
      reportType: ReportType.offensiveContent,
      description: 'User reported conversation for moderation',
    );
  }
}