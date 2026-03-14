import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/url_utils.dart';
import '../../models/conversation.dart';
import '../../models/message.dart' as model;
import '../../providers/conversation_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connection_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/ui_preferences_provider.dart';
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
    final validOtherAvatarUrl = isValidNetworkUrl(otherParticipantAvatar)
      ? otherParticipantAvatar!
      : null;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.5), width: 2),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.darkSurface,
                backgroundImage: validOtherAvatarUrl != null
                    ? CachedNetworkImageProvider(validOtherAvatarUrl)
                    : null,
                child: validOtherAvatarUrl == null
                    ? Text(
                        otherParticipantName[0].toUpperCase(),
                        style: AppTextStyles.labelMedium.copyWith(color: AppColors.accentBlue, fontWeight: FontWeight.w800),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherParticipantName,
                    style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Direct Message',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.accentBlue, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
            onPressed: () => _showOptionsMenu(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.darkBorder),
        ),
      ),
      body: Column(
        children: [
          if (_isCheckingConnection)
            const LinearProgressIndicator(minHeight: 2, color: AppColors.accentBlue),
          if (!_isCheckingConnection && !_canMessage)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.darkSurface,
              child: Row(
                children: [
                  const Icon(Icons.lock_outline_rounded, color: AppColors.accentOrange, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Messaging locked. Connect with this user first.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.accentOrange),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: conversationState.isLoading && conversationState.messages.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.accentBlue, strokeWidth: 2))
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: conversationState.messages.length,
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.darkCardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Text(
                      '$otherParticipantName is typing...',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ),
                ],
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          child: Column(
            crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isCurrentUser
                        ? AppColors.accentBlue.withValues(alpha: 0.18)
                        : AppColors.darkCardBg,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isCurrentUser ? const Radius.circular(16) : const Radius.circular(4),
                      bottomRight: isCurrentUser ? const Radius.circular(4) : const Radius.circular(16),
                    ),
                    border: Border.all(
                      color: didRetrySucceed
                          ? AppColors.accentBlue.withValues(alpha: subtleFeedback ? 0.5 : 0.8)
                          : isCurrentUser
                              ? AppColors.accentBlue.withValues(alpha: 0.4)
                              : AppColors.darkBorder,
                    ),
                    boxShadow: didRetrySucceed
                        ? [
                            BoxShadow(
                              color: AppColors.accentBlue.withValues(alpha: subtleFeedback ? 0.14 : 0.26),
                              blurRadius: subtleFeedback ? 8 : 12,
                              spreadRadius: subtleFeedback ? 0 : 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    message.content,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.darkText),
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
                      Icon(_statusIcon(message), size: 11, color: _statusColor(message)),
                    ],
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
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.errorRed),
                          )
                        : const Icon(Icons.refresh_rounded, key: ValueKey('retry_icon'), size: 14),
                  ),
                  label: AnimatedSwitcher(
                    duration: Duration(milliseconds: fastRetryAnimations ? 120 : 180),
                    transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                    child: Text(
                      isRetrying ? 'Retrying...' : 'Tap to retry',
                      key: ValueKey(isRetrying ? 'retrying_label' : 'retry_label'),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.errorRed,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ),
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
    if (s == 'failed') return AppColors.errorRed;
    if (s == 'read' || message.isRead) return AppColors.accentBlue;
    return AppColors.textMuted;
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).viewPadding.bottom + 12),
      decoration: const BoxDecoration(
        color: AppColors.darkCardBg,
        border: Border(top: BorderSide(color: AppColors.darkBorder, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _messageController.text.trim().isNotEmpty
                      ? AppColors.accentBlue.withValues(alpha: 0.4)
                      : AppColors.darkBorder,
                ),
              ),
              child: TextField(
                controller: _messageController,
                onChanged: (_) => setState(() {}),
                enabled: _canMessage,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: _canMessage ? 'Message...' : 'Connect to send messages',
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
              gradient: (_canMessage && _messageController.text.trim().isNotEmpty)
                  ? const LinearGradient(
                      colors: [AppColors.accentBlue, AppColors.accentTeal],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [AppColors.darkSurface, AppColors.darkSurface],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              shape: BoxShape.circle,
              boxShadow: (_canMessage && _messageController.text.trim().isNotEmpty)
                  ? [BoxShadow(color: AppColors.accentBlue.withValues(alpha: 0.4), blurRadius: 12)]
                  : [],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: (_canMessage && _messageController.text.trim().isNotEmpty) ? _sendMessage : null,
              icon: Icon(
                Icons.send_rounded,
                color: (_canMessage && _messageController.text.trim().isNotEmpty)
                    ? AppColors.primaryBlack
                    : AppColors.textMuted,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.darkBorder),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.darkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.block_rounded, color: AppColors.errorRed, size: 18),
              ),
              title: Text('Block User', style: AppTextStyles.labelMedium.copyWith(color: AppColors.darkText)),
              subtitle: Text('Hide their messages', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
              onTap: () {
                Navigator.pop(context);
                _blockUser();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.flag_rounded, color: AppColors.accentOrange, size: 18),
              ),
              title: Text('Report Conversation', style: AppTextStyles.labelMedium.copyWith(color: AppColors.darkText)),
              subtitle: Text('Send to moderation', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
              onTap: () {
                Navigator.pop(context);
                _reportConversation();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _blockUser() async {
    try {
      final otherId = _getOtherParticipantId();
      await ref.read(connectionProvider.notifier).blockUser(otherId);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User blocked. Conversations with them are hidden.'),
          duration: Duration(seconds: 2),
        ),
      );
      // Navigate back to conversations
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to block user: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
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