import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/category_provider.dart';
import '../../providers/debate_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/debate.dart';

class CreateDebateScreen extends ConsumerStatefulWidget {
  const CreateDebateScreen({super.key});

  @override
  ConsumerState<CreateDebateScreen> createState() => _CreateDebateScreenState();
}

class _CreateDebateScreenState extends ConsumerState<CreateDebateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategoryId;
  bool _isReady = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _createDebate() async {
    if (_formKey.currentState!.validate() && _selectedCategoryId != null) {
      final authState = ref.read(authProvider);
      if (authState.user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to create a debate')),
        );
        return;
      }
      final newDebate = Debate(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        categoryId: _selectedCategoryId!,
        creatorId: authState.user!.id,
        mediaType: 'text',
        status: 'active',
        createdAt: DateTime.now(),
      );
      await ref.read(debateProvider.notifier).createDebate(newDebate);
      if (mounted) {
        final debateState = ref.read(debateProvider);
        if (debateState.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${debateState.error}'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        } else {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Debate launched! 🔥')),
          );
        }
      }
    } else if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category first'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryProvider);
    final debateState = ref.watch(debateProvider);
    final isLoading = debateState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.darkCardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: const Icon(Icons.close_rounded, color: AppColors.darkText, size: 18),
          ),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.errorRed,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'DEBATE STUDIO',
              style: AppTextStyles.labelMedium.copyWith(
                letterSpacing: 1.5,
                color: AppColors.darkText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Form(
          key: _formKey,
          onChanged: () {
            final ready = _titleController.text.trim().length >= 5 && _selectedCategoryId != null;
            if (ready != _isReady) setState(() => _isReady = ready);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero prompt
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryYellow.withValues(alpha: 0.08),
                      AppColors.accentOrange.withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryYellow.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flash_on_rounded, color: AppColors.primaryYellow, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'THE TOPIC',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primaryYellow,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        ValueListenableBuilder(
                          valueListenable: _titleController,
                          builder: (_, v, __) => Text(
                            '${v.text.length}/120',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: v.text.length > 100 ? AppColors.errorRed : AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _titleController,
                      inputFormatters: [LengthLimitingTextInputFormatter(120)],
                      onChanged: (_) => setState(() {}),
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.darkText),
                      decoration: InputDecoration(
                        hintText: 'Should AI have constitutional rights?',
                        hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.darkSurface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.darkBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.darkBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primaryYellow, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Description section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.darkCardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.edit_note_rounded, color: AppColors.accentBlue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'CONTEXT (OPTIONAL)',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.accentBlue,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        ValueListenableBuilder(
                          valueListenable: _descriptionController,
                          builder: (_, v, __) => Text(
                            '${v.text.length}/500',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: v.text.length > 450 ? AppColors.errorRed : AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      inputFormatters: [LengthLimitingTextInputFormatter(500)],
                      onChanged: (_) => setState(() {}),
                      maxLines: 4,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.darkText),
                      decoration: InputDecoration(
                        hintText: 'Give context, set stakes, or drop receipts...',
                        hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.darkSurface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.darkBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.darkBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Category
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.darkCardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.category_rounded, color: AppColors.accentTeal, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'CATEGORY',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.accentTeal,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (_selectedCategoryId == null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.errorRed.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                'REQUIRED',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.errorRed,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildCategorySelector(categoryState, isLoading),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
        child: _buildLaunchButton(isLoading),
      ),
    );
  }

  Widget _buildLaunchButton(bool isLoading) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      height: 56,
      decoration: BoxDecoration(
        gradient: _isReady
            ? const LinearGradient(
                colors: [AppColors.primaryYellow, AppColors.accentOrange],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : LinearGradient(
                colors: [AppColors.darkSurface, AppColors.darkSurface],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isReady
            ? [BoxShadow(color: AppColors.primaryYellow.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 6))]
            : [],
        border: Border.all(
          color: _isReady ? Colors.transparent : AppColors.darkBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isLoading ? null : (_isReady ? _createDebate : null),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: _isReady ? AppColors.primaryBlack : AppColors.textMuted,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.rocket_launch_rounded,
                        color: _isReady ? AppColors.primaryBlack : AppColors.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'LAUNCH DEBATE',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: _isReady ? AppColors.primaryBlack : AppColors.textMuted,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(CategoryState state, bool isLoading) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentTeal, strokeWidth: 2),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: state.categories.map((cat) {
        final isSelected = _selectedCategoryId == cat.id;
        return GestureDetector(
          onTap: isLoading
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedCategoryId = isSelected ? null : cat.id;
                    _isReady = _titleController.text.trim().length >= 5 && !isSelected;
                  });
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryYellow : AppColors.darkSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primaryYellow : AppColors.darkBorder,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: AppColors.primaryYellow.withValues(alpha: 0.3), blurRadius: 10)]
                  : [],
            ),
            child: Text(
              '${cat.emoji}  ${cat.name.toUpperCase()}',
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? AppColors.primaryBlack : AppColors.textSecondary,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
