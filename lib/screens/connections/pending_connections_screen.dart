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
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(connectionProvider.notifier).fetchPendingRequests());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(connectionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Pending Requests'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () => ref.read(connectionProvider.notifier).fetchPendingRequests(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Received', style: AppTextStyles.h3),
                  const SizedBox(height: 8),
                  if (state.receivedPendingUsers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('No received requests', style: AppTextStyles.bodySmall),
                    ),
                  ...state.receivedPendingUsers.map((u) => Card(
                        child: ListTile(
                          title: Text(u.displayName),
                          subtitle: Text('@${u.username}'),
                          onTap: () => context.push('/profile/${u.id}'),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: () => ref.read(connectionProvider.notifier).acceptRequest(u.id),
                                child: const Text('Accept'),
                              ),
                              TextButton(
                                onPressed: () => ref.read(connectionProvider.notifier).declineRequest(u.id),
                                child: const Text('Decline'),
                              ),
                            ],
                          ),
                        ),
                      )),
                  const SizedBox(height: 20),
                  Text('Sent', style: AppTextStyles.h3),
                  const SizedBox(height: 8),
                  if (state.sentPendingUsers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('No sent requests', style: AppTextStyles.bodySmall),
                    ),
                  ...state.sentPendingUsers.map((u) => Card(
                        child: ListTile(
                          title: Text(u.displayName),
                          subtitle: Text('@${u.username}'),
                          onTap: () => context.push('/profile/${u.id}'),
                          trailing: TextButton(
                            onPressed: () => ref.read(connectionProvider.notifier).withdrawRequest(u.id),
                            child: const Text('Withdraw'),
                          ),
                        ),
                      )),
                ],
              ),
            ),
    );
  }
}
