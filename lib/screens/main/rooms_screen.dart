import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/url_utils.dart';
import '../../models/room.dart';
import '../../providers/room_provider.dart';

import 'package:cached_network_image/cached_network_image.dart';

class RoomsScreen extends ConsumerStatefulWidget {
  const RoomsScreen({super.key});

  @override
  ConsumerState<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends ConsumerState<RoomsScreen> {
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => AppColors.backgroundColor(_isDark);
  Color get _cardBg => AppColors.cardBackground(_isDark);
  Color get _border => AppColors.borderColor(_isDark);
  Color get _text => AppColors.textColor(_isDark);
  Color get _muted => AppColors.mutedTextColor(_isDark);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(roomProvider.notifier).fetchRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            stretch: true,
            backgroundColor: _bg,
            elevation: 0,
            leading: Navigator.of(context).canPop()
                ? IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: _text, size: 20),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              title: Text(
                'COMMUNITIES',
                style: AppTextStyles.h2.copyWith(
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: _text,
                ),
              ),
              centerTitle: true,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.accentTeal, AppColors.accentBlue],
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                            colors: [Colors.transparent, _bg],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.add_box_outlined, color: _text),
                onPressed: _showCreateRoomSheet,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
        body: Container(
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
          ),
          child: roomState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentTeal))
          : roomState.rooms.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  itemCount: roomState.rooms.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final room = roomState.rooms[index];
                    return _buildPremiumRoomCard(room);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildPremiumRoomCard(Room room) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentTeal.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/rooms/${room.id}', extra: room),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isValidNetworkUrl(room.bannerUrl) || isValidNetworkUrl(room.iconUrl))
                  SizedBox(
                    height: 100,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (isValidNetworkUrl(room.bannerUrl))
                          CachedNetworkImage(
                            imageUrl: room.bannerUrl!,
                            fit: BoxFit.cover,
                          )
                        else
                          Container(decoration: BoxDecoration(color: AppColors.surfaceLight.withValues(alpha: 0.5))),
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
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        margin: EdgeInsets.only(top: (room.bannerUrl != null || room.iconUrl != null) ? -40 : 0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _cardBg, width: 3),
                          image: room.iconUrl != null
                              && isValidNetworkUrl(room.iconUrl)
                              ? DecorationImage(image: CachedNetworkImageProvider(room.iconUrl!), fit: BoxFit.cover)
                              : null,
                          color: _cardBg,
                        ),
                        child: !isValidNetworkUrl(room.iconUrl)
                            ? const Icon(Icons.groups_rounded, color: AppColors.accentTeal, size: 28)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    room.name,
                                    style: AppTextStyles.h3.copyWith(fontSize: 18),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) => _handleRoomAction(value, room),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'members',
                                      child: Text('View Members'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'leave',
                                      child: Text('Leave Room'),
                                    ),
                                  ],
                                  child: Icon(Icons.more_vert_rounded, color: _muted, size: 20),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (room.description != null)
                              Text(
                                room.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildStatBadge(Icons.people_alt_rounded, '${room.memberCount} MEMBERS'),
                                const SizedBox(width: 8),
                                _buildStatBadge(Icons.forum_rounded, '${room.debateCount ?? 0} DEBATES'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => context.push('/chat/${room.id}', extra: room),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.accentTeal,
                                  side: const BorderSide(color: AppColors.accentTeal),
                                ),
                                icon: const Icon(Icons.forum_rounded, size: 16),
                                label: const Text('Open Room Chat'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.accentTeal),
          const SizedBox(width: 4),
          Text(text, style: AppTextStyles.labelSmall.copyWith(fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _handleRoomAction(String action, dynamic room) {
    switch (action) {
      case 'members':
        context.push('/rooms/${room.id}/members', extra: room);
        break;
      case 'leave':
        _showLeaveConfirmation(room);
        break;
    }
  }

  void _showLeaveConfirmation(dynamic room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardBg,
        title: Text('Leave Room', style: AppTextStyles.h3),
        content: Text('Are you sure you want to leave ${room.name}?',
            style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(roomProvider.notifier).leaveRoom(room.id);
              if (!mounted) return;
              final error = ref.read(roomProvider).error;
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(error ?? 'You left ${room.name}.'),
                  backgroundColor: error == null ? AppColors.accentTeal : AppColors.error,
                ),
              );
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
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
                color: AppColors.accentTeal.withValues(alpha: 0.07),
                border: Border.all(color: AppColors.accentTeal.withValues(alpha: 0.3), width: 2),
              ),
              child: const Icon(Icons.groups_rounded, size: 64, color: AppColors.accentTeal),
            ),
            const SizedBox(height: 24),
            Text('No Communities Yet', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            Text(
              'Join an existing community or start your own to engage in focused debates.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showCreateRoomSheet,
              icon: const Icon(Icons.explore_rounded, color: AppColors.primaryBlack),
              label: Text('DISCOVER', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primaryBlack, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYellow,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateRoomSheet() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Community', style: AppTextStyles.h3),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Community name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final notifier = ref.read(roomProvider.notifier);
                    final userId = await notifier.currentUserId();
                    if (userId == null) return;

                    await notifier.createRoom(
                      Room(
                        id: '',
                        name: name,
                        description: descController.text.trim().isEmpty
                            ? null
                            : descController.text.trim(),
                        creatorId: userId,
                        createdAt: DateTime.now(),
                      ),
                    );

                    if (!mounted) return;
                    Navigator.of(this.context).pop();
                    final error = ref.read(roomProvider).error;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text(error ?? 'Community created successfully.'),
                        backgroundColor: error == null ? AppColors.accentTeal : AppColors.error,
                      ),
                    );
                  },
                  child: const Text('Create'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
