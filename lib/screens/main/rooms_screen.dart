import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/room_provider.dart';

import 'package:cached_network_image/cached_network_image.dart';

class RoomsScreen extends ConsumerStatefulWidget {
  const RoomsScreen({super.key});

  @override
  ConsumerState<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends ConsumerState<RoomsScreen> {
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.background.withValues(alpha: 0.8),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              title: Text(
                'COMMUNITIES',
                style: AppTextStyles.h2.copyWith(
                  letterSpacing: 4,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.premiumGradient,
                    ),
                  ),
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
            actions: [
              IconButton(
                icon: const Icon(Icons.add_box_outlined, color: Colors.white),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
        body: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
          ),
          child: roomState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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

  Widget _buildPremiumRoomCard(dynamic room) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
                if (room.bannerUrl != null || room.iconUrl != null)
                  SizedBox(
                    height: 100,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (room.bannerUrl != null)
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
                          border: Border.all(color: AppColors.surface, width: 3),
                          image: room.iconUrl != null
                              ? DecorationImage(image: CachedNetworkImageProvider(room.iconUrl!), fit: BoxFit.cover)
                              : null,
                          color: AppColors.surfaceLight,
                        ),
                        child: room.iconUrl == null ? const Icon(Icons.groups_rounded, color: AppColors.primary, size: 28) : null,
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
                                  child: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted, size: 20),
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
                                _buildStatBadge(Icons.forum_rounded, '${room.debateCount} DEBATES'),
                              ],
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
        color: AppColors.surfaceLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
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
        backgroundColor: AppColors.surface,
        title: Text('Leave Room', style: AppTextStyles.h3),
        content: Text('Are you sure you want to leave ${room.name}?',
            style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement leave room functionality
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
                color: AppColors.surfaceLight.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.2), width: 2),
              ),
              child: const Icon(Icons.groups_rounded, size: 64, color: AppColors.textMuted),
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
              onPressed: () {},
              icon: const Icon(Icons.explore_rounded, color: Colors.black),
              label: Text('DISCOVER', style: AppTextStyles.labelMedium.copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
