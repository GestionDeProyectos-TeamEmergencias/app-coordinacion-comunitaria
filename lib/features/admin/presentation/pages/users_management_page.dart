import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Panel de gestión de usuarios pendientes de aprobación. [T-AUTH-01]
/// RF-ADM-03: lista de usuarios con filtros por rol y reputación. [T-AUTH-08]
class UsersManagementPage extends ConsumerWidget {
  const UsersManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.usersManagement),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: _PendingTabLabel(pendingAsync: pendingAsync),
        ),
      ),
      body: pendingAsync.when(
        loading: () => const AppLoading(message: 'Cargando solicitudes…'),
        error: (e, _) => Center(
          child: Text(
            e.toString(),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
        data: (users) => users.isEmpty
            ? const _EmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) =>
                    _PendingUserCard(user: users[index]),
              ),
      ),
    );
  }
}

// ── Widgets internos ──────────────────────────────────────────────────────────

class _PendingTabLabel extends StatelessWidget {
  const _PendingTabLabel({required this.pendingAsync});

  final AsyncValue<List<AppUser>> pendingAsync;

  @override
  Widget build(BuildContext context) {
    final count = pendingAsync.valueOrNull?.length ?? 0;
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.pending_actions,
            size: 16,
            color: count > 0
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 6),
          Text(
            count > 0
                ? '$count ${count == 1 ? 'solicitud pendiente' : 'solicitudes pendientes'}'
                : AppStrings.noPendingUsers,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: count > 0
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.how_to_reg_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.noPendingUsers,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PendingUserCard extends ConsumerWidget {
  const _PendingUserCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(userManagementNotifierProvider).isLoading;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Datos del solicitante
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: const Text('Pendiente'),
                  backgroundColor:
                      Theme.of(context).colorScheme.tertiaryContainer,
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                    fontSize: 11,
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // Acciones
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text(AppStrings.rejectUser),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side:
                        BorderSide(color: Theme.of(context).colorScheme.error),
                  ),
                  onPressed: isLoading
                      ? null
                      : () => _confirmReject(context, ref, user.userId),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text(AppStrings.approveUser),
                  onPressed: isLoading
                      ? null
                      : () => _confirmApprove(context, ref, user.userId),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmApprove(
    BuildContext context,
    WidgetRef ref,
    String uid,
  ) async {
    final confirmed = await _showConfirmDialog(
      context: context,
      title: AppStrings.approveConfirmTitle,
      body: AppStrings.approveConfirmBody,
      confirmLabel: AppStrings.approveUser,
      confirmColor: Theme.of(context).colorScheme.primary,
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(userManagementNotifierProvider.notifier).approveUser(uid);

    if (!context.mounted) return;
    final error = ref.read(userManagementNotifierProvider).error;
    if (error != null) {
      context.showSnackBar(error.toString(), isError: true);
    } else {
      context.showSnackBar(AppStrings.userApproved);
    }
  }

  Future<void> _confirmReject(
    BuildContext context,
    WidgetRef ref,
    String uid,
  ) async {
    final confirmed = await _showConfirmDialog(
      context: context,
      title: AppStrings.rejectConfirmTitle,
      body: AppStrings.rejectConfirmBody,
      confirmLabel: AppStrings.rejectUser,
      confirmColor: Theme.of(context).colorScheme.error,
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(userManagementNotifierProvider.notifier).rejectUser(uid);

    if (!context.mounted) return;
    final error = ref.read(userManagementNotifierProvider).error;
    if (error != null) {
      context.showSnackBar(error.toString(), isError: true);
    } else {
      context.showSnackBar(AppStrings.userRejected);
    }
  }

  Future<bool?> _showConfirmDialog({
    required BuildContext context,
    required String title,
    required String body,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}
