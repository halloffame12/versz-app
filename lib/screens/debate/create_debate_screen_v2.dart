import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/debate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/debate_provider.dart';

class CreateDebateScreenV2 extends ConsumerStatefulWidget {
  const CreateDebateScreenV2({super.key});

  @override
  ConsumerState<CreateDebateScreenV2> createState() => _CreateDebateScreenV2State();
}

class _CreateDebateScreenV2State extends ConsumerState<CreateDebateScreenV2> with TickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late AnimationController _pageAnimation;
  String _selectedCategory = 'Technology';
  bool _isSubmitting = false;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => AppColors.backgroundColor(_isDark);
  Color get _cardBg => AppColors.cardBackground(_isDark);

  final categories = [
    'Technology',
    'Politics',
    'Sports',
    'Science',
    'Entertainment',
    'Philosophy',
    'Health',
    'Education',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _pageAnimation = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pageAnimation.dispose();
    super.dispose();
  }

  Future<void> _submitDebate() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final userId = ref.read(authProvider).user?.id;

    if (title.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title must be at least 8 characters.')),
      );
      return;
    }
    if (description.length < 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Description must be at least 16 characters.')),
      );
      return;
    }
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in again and try creating the debate.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final debate = Debate(
      id: '',
      title: title,
      description: description,
      categoryId: _selectedCategory.toLowerCase(),
      creatorId: userId,
      mediaType: 'text',
      status: 'active',
      createdAt: DateTime.now(),
    );

    await ref.read(debateProvider.notifier).createDebate(debate);
    if (!mounted) return;
    final debateState = ref.read(debateProvider);
    setState(() => _isSubmitting = false);

    if (debateState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create debate: ${debateState.error}')),
      );
      return;
    }

    _titleController.clear();
    _descriptionController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Debate created successfully.')),
    );
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Icon(Icons.arrow_back_rounded, color: AppColors.accentCyan),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.accentLight, AppColors.accentPrimary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'START A DEBATE',
            style: AppTextStyles.headlineM.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
        centerTitle: false,
      ),
      body: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _pageAnimation, curve: Curves.easeOut),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title input
              _buildInputField(
                label: 'Debate Title',
                hint: 'What is your question or statement?',
                controller: _titleController,
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // Description input
              _buildInputField(
                label: 'Description',
                hint: 'Provide context and background information...',
                controller: _descriptionController,
                maxLines: 4,
              ),
              const SizedBox(height: 20),

              // Category selection
              Text(
                'CATEGORY',
                style: AppTextStyles.labelL.copyWith(
                  color: AppColors.mutedGray,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories
                      .map((category) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedCategory = category),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: _selectedCategory == category
                                      ? LinearGradient(
                                          colors: [AppColors.accentPurple, AppColors.accentIndigo],
                                        )
                                      : null,
                                  color: _selectedCategory == category ? null : _cardBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: _selectedCategory != category
                                      ? Border.all(
                                          color: AppColors.accentIndigo.withValues(alpha: 0.3),
                                        )
                                      : null,
                                ),
                                child: Text(
                                  category,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: _selectedCategory == category
                                        ? AppColors.textPrimary
                                        : AppColors.mutedGray,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 30),

              // Create button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                    CurvedAnimation(parent: _pageAnimation, curve: Curves.elasticOut),
                  ),
                  child: GestureDetector(
                    onTap: _isSubmitting ? null : _submitDebate,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.accentLight, AppColors.accentPrimary],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentPrimary.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_rounded, color: AppColors.textPrimary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'START DEBATE',
                                    style: AppTextStyles.bodyL.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelL.copyWith(
            color: AppColors.mutedGray,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: AppTextStyles.bodyM.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyM.copyWith(color: AppColors.mutedGray.withValues(alpha: 0.6)),
            filled: true,
            fillColor: _cardBg,
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
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }
}
