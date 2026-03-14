import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/connection_provider.dart';

class PendingConnectionsScreen extends ConsumerStatefulWidget {
  const PendingConnectionsScreen({super.key});

  @override
  ConsumerState<PendingConnectionsScreen> createState() => _PendingConnectionsScreenState();
}

class _PendingConnectionsScreenState extends ConsumerState<PendingConnectionsScreen> {
  int _tabIndex = 0;
  final Set<String> _busyUserIds = <String>{};

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(connectionProvider.notifier).fetchPendingRequests());
  }

  Future<void> _runUserAction(String userId, Future<void> Function() action) async {
    if (_busyUserIds.contains(userId)) return;
    setState(() => _busyUserIds.add(userId));
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request updated')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busyUserIds.remove(userId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(connectionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final list = _tabIndex == 0 ? state.receivedPendingUsers : state.sentPendingUsers;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCardBg : AppColors.surface,
        title: const Text('Pending Requests'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                _buildTabChip('Received (${state.receivedPendingUsers.length})', 0),
                const SizedBox(width: 10),
                _buildTabChip('Sent (${state.sentPendingUsers.length})', 1),
              ],
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: () => ref.read(connectionProvider.notifier).fetchPendingRequests(),
                    child: list.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 160),
                              Center(
                                child: Text(
                                  _tabIndex == 0 ? 'No received requests' : 'No sent requests',
                                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: list.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final u = list[index];
                              final busy = _busyUserIds.contains(u.id);

                              return Card(
                                elevation: 0,
                                color: isDark ? AppColors.darkCardBg : AppColors.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(color: isDark ? AppColors.accentIndigo : AppColors.mutedGray),
                                ),
                                child: ListTile(
                                  title: Text(u.displayName),
                                  subtitle: Text('@${u.username}'),
                                  onTap: () => context.push('/profile/${u.id}'),
                                  trailing: busy
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : _tabIndex == 0
                                          ? Wrap(
                                              spacing: 8,
                                              children: [
                                                TextButton(
                                                  onPressed: () => _runUserAction(
                                                    u.id,
                                                    () => ref.read(connectionProvider.notifier).acceptRequest(u.id),
                                                  ),
                                                  child: const Text('Accept'),
                                                ),
                                                TextButton(
                                                  onPressed: () => _runUserAction(
                                                    u.id,
                                                    () => ref.read(connectionProvider.notifier).declineRequest(u.id),
                                                  ),
                                                  child: const Text('Decline'),
                                                ),
                                              ],
                                            )
                                          : TextButton(
                                              onPressed: () => _runUserAction(
                                                u.id,
                                                () => ref.read(connectionProvider.notifier).withdrawRequest(u.id),
                                              ),
                                              child: const Text('Withdraw'),
                                            ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip(String label, int index) {
    final selected = _tabIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _tabIndex = index),
      selectedColor: AppColors.accentCyan.withValues(alpha: 0.15),
      labelStyle: AppTextStyles.labelSmall.copyWith(
        color: selected ? AppColors.accentCyan : AppColors.textSecondary,
      ),
      side: BorderSide(
        color: selected ? AppColors.accentCyan : AppColors.mutedGray,
      ),
    );
  }
}
