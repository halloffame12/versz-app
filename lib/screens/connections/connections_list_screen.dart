import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/connection_provider.dart';

class ConnectionsListScreen extends ConsumerStatefulWidget {
  const ConnectionsListScreen({super.key});

  @override
  ConsumerState<ConnectionsListScreen> createState() => _ConnectionsListScreenState();
}

class _ConnectionsListScreenState extends ConsumerState<ConnectionsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(connectionProvider.notifier).fetchConnectedUsers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(connectionProvider);
    final q = _searchController.text.trim().toLowerCase();
    final users = state.connectedUsers.where((u) {
      if (q.isEmpty) return true;
      return u.displayName.toLowerCase().contains(q) || u.username.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Connections'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search connections',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : users.isEmpty
                    ? Center(
                        child: Text(
                          'No connected users yet',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.read(connectionProvider.notifier).fetchConnectedUsers(),
                        child: ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.surfaceLight,
                                child: Text(user.displayName.isEmpty ? '?' : user.displayName[0].toUpperCase()),
                              ),
                              title: Text(user.displayName),
                              subtitle: Text('@${user.username}'),
                              trailing: TextButton(
                                onPressed: () => context.push('/messages'),
                                child: const Text('Message'),
                              ),
                              onTap: () => context.push('/profile/${user.id}'),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
