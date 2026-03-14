import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appwrite/appwrite.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/appwrite_service.dart';
import '../../core/constants/appwrite_constants.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _websiteController;
  late TextEditingController _locationController;

  File? _avatarFile;
  File? _bannerFile;
  bool _isSaving = false;
  String? _avatarPreviewUrl;
  String? _bannerPreviewUrl;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _displayNameController = TextEditingController(text: user?.displayName ?? '');
    _usernameController = TextEditingController(text: user?.username ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _websiteController = TextEditingController(text: user?.website ?? '');
    _locationController = TextEditingController(text: '');
    _avatarPreviewUrl = user?.avatarUrl;
    _bannerPreviewUrl = user?.coverImage;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _websiteController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _avatarFile = File(picked.path);
        _avatarPreviewUrl = null;
      });
    }
  }

  Future<void> _pickBanner() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 600,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _bannerFile = File(picked.path);
        _bannerPreviewUrl = null;
      });
    }
  }

  Future<String?> _uploadFile(File file, String bucketId) async {
    try {
      final appwrite = AppwriteService();
      final result = await appwrite.storage.createFile(
        bucketId: bucketId,
        fileId: ID.unique(),
        file: InputFile.fromPath(path: file.path),
        permissions: [
          Permission.read(Role.any()),
        ],
      );
      // Build the file URL
      final fileUrl =
          '${AppwriteConstants.endpoint}/storage/buckets/$bucketId/files/${result.$id}/view?project=${AppwriteConstants.projectId}';
      return fileUrl;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final displayName = _displayNameController.text.trim();
    final username = _usernameController.text.trim().toLowerCase();
    final bio = _bioController.text.trim();
    final website = _websiteController.text.trim();

    // Username validation
    final usernameRegex = RegExp(r'^[a-z0-9_]{3,30}$');
    if (!usernameRegex.hasMatch(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username: 3-30 chars, letters/numbers/underscores only'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    String? newAvatarUrl = _avatarPreviewUrl;
    String? newBannerUrl = _bannerPreviewUrl;

    // Upload avatar if changed
    if (_avatarFile != null) {
      newAvatarUrl = await _uploadFile(_avatarFile!, AppwriteConstants.avatarsBucket);
      if (newAvatarUrl == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar upload failed. Please try again.')),
        );
        setState(() => _isSaving = false);
        return;
      }
    }

    // Upload banner if changed
    if (_bannerFile != null) {
      newBannerUrl = await _uploadFile(_bannerFile!, AppwriteConstants.coverImagesBucket);
      if (newBannerUrl == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banner upload failed. Please try again.')),
        );
        setState(() => _isSaving = false);
        return;
      }
    }

    final data = <String, dynamic>{
      'displayName': displayName,
      'username': username,
      'bio': bio,
      'website': website,
      if (newAvatarUrl != null) 'avatarUrl': newAvatarUrl,
      if (newBannerUrl != null) 'coverImage': newBannerUrl,
    };

    await ref.read(authProvider.notifier).updateProfile(data);

    if (!mounted) return;
    setState(() => _isSaving = false);

    final error = ref.read(authProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.errorRed),
      );
      ref.read(authProvider.notifier).clearError();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Edit Profile',
          style: AppTextStyles.headlineS.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: AppColors.accentCyan,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Save',
                      style: AppTextStyles.bodyL.copyWith(
                        color: AppColors.accentCyan,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner section
              Stack(
                children: [
                  GestureDetector(
                    onTap: _pickBanner,
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.darkSurface,
                        image: _bannerFile != null
                            ? DecorationImage(
                                image: FileImage(_bannerFile!),
                                fit: BoxFit.cover,
                              )
                            : (_bannerPreviewUrl != null && _bannerPreviewUrl!.isNotEmpty)
                                ? DecorationImage(
                                    image: NetworkImage(_bannerPreviewUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                      ),
                      child: (_bannerFile == null &&
                              (_bannerPreviewUrl == null || _bannerPreviewUrl!.isEmpty))
                          ? Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.accentPurple.withValues(alpha: 0.6),
                                    AppColors.accentIndigo.withValues(alpha: 0.6),
                                    AppColors.accentCyan.withValues(alpha: 0.4),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_photo_alternate_rounded,
                                        color: Colors.white70, size: 32),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to add banner',
                                      style: AppTextStyles.bodyS.copyWith(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                  // Edit icon overlay on banner
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: GestureDetector(
                      onTap: _pickBanner,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),

              // Avatar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Transform.translate(
                  offset: const Offset(0, -40),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: _pickAvatar,
                        child: Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.darkBackground, width: 3),
                                gradient: const LinearGradient(
                                  colors: [AppColors.accentPurple, AppColors.accentIndigo],
                                ),
                                image: _avatarFile != null
                                    ? DecorationImage(
                                        image: FileImage(_avatarFile!),
                                        fit: BoxFit.cover,
                                      )
                                    : (_avatarPreviewUrl != null && _avatarPreviewUrl!.isNotEmpty)
                                        ? DecorationImage(
                                            image: NetworkImage(_avatarPreviewUrl!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                              ),
                              child: (_avatarFile == null &&
                                      (_avatarPreviewUrl == null || _avatarPreviewUrl!.isEmpty))
                                  ? Center(
                                      child: Text(
                                        _displayNameController.text.isNotEmpty
                                            ? _displayNameController.text[0].toUpperCase()
                                            : 'U',
                                        style: AppTextStyles.headlineM.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: AppColors.accentCyan,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.darkBackground, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt_rounded,
                                    color: Colors.black, size: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Tap avatar or banner to change',
                          style: AppTextStyles.bodyS.copyWith(color: AppColors.mutedGray),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Form fields
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField(
                      label: 'Display Name',
                      controller: _displayNameController,
                      hint: 'Your full name',
                      validator: (v) {
                        if (v == null || v.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Username',
                      controller: _usernameController,
                      hint: 'unique_username',
                      prefixText: '@',
                      validator: (v) {
                        if (v == null || v.trim().length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Bio',
                      controller: _bioController,
                      hint: 'Tell the world about yourself...',
                      maxLines: 3,
                      maxLength: 200,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Website',
                      controller: _websiteController,
                      hint: 'https://yourwebsite.com',
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentIndigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Save Changes',
                                style: AppTextStyles.bodyL.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? hint,
    String? prefixText,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelM.copyWith(
            color: AppColors.mutedGray,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          validator: validator,
          style: AppTextStyles.bodyM.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            prefixStyle: AppTextStyles.bodyM.copyWith(color: AppColors.mutedGray),
            hintStyle: AppTextStyles.bodyM.copyWith(color: AppColors.textMuted),
            counterStyle: AppTextStyles.bodyS.copyWith(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.darkSurface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.darkBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.darkBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.accentCyan, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.errorRed),
            ),
          ),
        ),
      ],
    );
  }
}
