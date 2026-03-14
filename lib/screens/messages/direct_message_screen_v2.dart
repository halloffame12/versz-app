import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/conversation.dart';

class DirectMessageScreenV2 extends ConsumerStatefulWidget {
  final Conversation conversation;

  const DirectMessageScreenV2({super.key, required this.conversation});

  @override
  ConsumerState<DirectMessageScreenV2> createState() => _DirectMessageScreenV2State();
}

class _DirectMessageScreenV2State extends ConsumerState<DirectMessageScreenV2> {
  late TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AppColors.backgroundColor(isDark);
    final cardBg = AppColors.cardBackground(isDark);

    final messages = [
      {'user': 'Jordan', 'text': 'Hi! How are you doing?', 'time': '2:15 PM', 'isSent': false},
      {'user': 'You', 'text': 'Hey! Doing great, thanks for asking!', 'time': '2:16 PM', 'isSent': true},
      {'user': 'Jordan', 'text': 'Want to start a debate together?', 'time': '2:17 PM', 'isSent': false},
      {'user': 'You', 'text': 'Absolutely! That sounds fun', 'time': '2:18 PM', 'isSent': true},
    ];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Icon(Icons.arrow_back_rounded, color: AppColors.accentCyan),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jordan Smith',
              style: AppTextStyles.bodyL.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            Text(
              'Active now',
              style: AppTextStyles.bodyS.copyWith(color: Colors.green),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(Icons.videocam_rounded, color: AppColors.accentCyan),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[messages.length - 1 - index];
                final isSent = msg['isSent'] as bool;

                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 400 + (index * 100)),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, (1 - value) * 30),
                      child: Opacity(
                        opacity: value,
                        child: Align(
                          alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                            decoration: BoxDecoration(
                              gradient: isSent
                                  ? LinearGradient(colors: [AppColors.accentPrimary, AppColors.accentPrimaryDark])
                                  : null,
                              color: isSent ? null : cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: isSent
                                  ? null
                                  : Border.all(color: AppColors.accentIndigo.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg['text'] as String,
                                  style: AppTextStyles.bodyM.copyWith(color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  msg['time'] as String,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: isSent ? AppColors.mutedGray : AppColors.mutedGray.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(
                top: BorderSide(color: AppColors.accentIndigo.withValues(alpha: 0.2)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: AppTextStyles.bodyM.copyWith(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      hintStyle: AppTextStyles.bodyM.copyWith(color: AppColors.mutedGray),
                      prefixIcon: Icon(Icons.emoji_emotions_rounded, color: AppColors.accentCyan),
                      filled: true,
                      fillColor: bg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: AppColors.accentIndigo.withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: AppColors.accentIndigo.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppColors.accentCyan, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.accentPurple, AppColors.accentIndigo]),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(Icons.send_rounded, color: AppColors.textPrimary, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
