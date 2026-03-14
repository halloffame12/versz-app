import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/room.dart';

class ChatDetailScreenV2 extends ConsumerStatefulWidget {
  final Room room;

  const ChatDetailScreenV2({super.key, required this.room});

  @override
  ConsumerState<ChatDetailScreenV2> createState() => _ChatDetailScreenV2State();
}

class _ChatDetailScreenV2State extends ConsumerState<ChatDetailScreenV2> {
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
      {'user': 'You', 'text': 'Hey, how is the debate going?', 'time': '10:30', 'isSent': true},
      {'user': 'Alex', 'text': 'Great! We have some interesting points', 'time': '10:32', 'isSent': false},
      {'user': 'You', 'text': 'That\'s awesome!', 'time': '10:33', 'isSent': true},
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
              widget.room.name,
              style: AppTextStyles.bodyL.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            Text(
              '5 members • 2 online',
              style: AppTextStyles.bodyS.copyWith(color: AppColors.mutedGray),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(Icons.call_rounded, color: AppColors.accentCyan),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isSent = msg['isSent'] as bool;

                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 400 + (index * 100)),
                  builder: (context, value, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(isSent ? 0.5 : -0.5, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: AlwaysStoppedAnimation(value),
                        curve: Curves.easeOut,
                      )),
                      child: Opacity(
                        opacity: value,
                        child: Align(
                          alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: isSent
                                  ? LinearGradient(
                                      colors: [AppColors.accentPrimary, AppColors.accentPrimaryDark],
                                    )
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
                      hintText: 'Type a message...',
                      hintStyle: AppTextStyles.bodyM.copyWith(color: AppColors.mutedGray),
                      prefixIcon: Icon(Icons.add_rounded, color: AppColors.accentCyan),
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
                ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                    CurvedAnimation(parent: AlwaysStoppedAnimation(1.0), curve: Curves.elasticOut),
                  ),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.accentPurple, AppColors.accentIndigo]),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(Icons.send_rounded, color: AppColors.textPrimary, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
