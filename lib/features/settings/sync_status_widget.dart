import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/providers.dart';
import '../../core/services/sync/sync_service.dart';

class SyncStatusWidget extends ConsumerWidget {
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final syncStatusAsync = ref.watch(syncStatusProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Sync & Account',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Account status
            if (authState.isAuthenticated) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(authState.userEmail ?? 'User'),
                subtitle: const Text('Signed in'),
                trailing: IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await ref.read(authStateProvider.notifier).logout();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Signed out successfully'),
                        ),
                      );
                    }
                  },
                ),
              ),
              const Divider(),

              // Sync status
              syncStatusAsync.when(
                data: (status) => _buildSyncStatus(context, ref, status),
                loading: () => const LinearProgressIndicator(),
                error: (error, stack) => Text('Error: $error'),
              ),
            ] else ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cloud_off_outlined),
                title: const Text('Not signed in'),
                subtitle: const Text('Sign in to sync your data'),
                trailing: FilledButton(
                  onPressed: () {
                    context.push('/login');
                  },
                  child: const Text('Sign In'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatus(
    BuildContext context,
    WidgetRef ref,
    SyncStatus status,
  ) {
    final theme = Theme.of(context);
    final syncService = ref.read(syncServiceProvider);

    IconData icon;
    String text;
    Color? color;

    switch (status) {
      case SyncStatus.idle:
        icon = Icons.check_circle_outline;
        text = 'Up to date';
        color = Colors.green;
        break;
      case SyncStatus.connecting:
        icon = Icons.sync;
        text = 'Connecting...';
        color = theme.colorScheme.primary;
        break;
      case SyncStatus.syncing:
        icon = Icons.sync;
        text = 'Syncing...';
        color = theme.colorScheme.primary;
        break;
      case SyncStatus.success:
        icon = Icons.check_circle;
        text = 'Synced successfully';
        color = Colors.green;
        break;
      case SyncStatus.error:
        icon = Icons.error_outline;
        text = 'Sync failed';
        color = Colors.red;
        break;
      case SyncStatus.disconnected:
        icon = Icons.cloud_off_outlined;
        text = 'Disconnected';
        color = Colors.orange;
        break;
    }

    final lastSync = syncService.lastSyncAt;
    final lastSyncText = lastSync != null
        ? 'Last sync: ${_formatDateTime(DateTime.parse(lastSync))}'
        : 'Never synced';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(color: color, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    lastSyncText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (status != SyncStatus.syncing && status != SyncStatus.connecting)
              IconButton(
                icon: const Icon(Icons.sync),
                onPressed: () async {
                  await syncService.sync();
                },
                tooltip: 'Sync now',
              ),
          ],
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
