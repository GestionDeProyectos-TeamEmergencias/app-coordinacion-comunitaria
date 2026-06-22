import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/moderation_provider.dart';

/// Panel de gestión de usuarios pendientes y activos.
/// [T-AUTH-01] aprobación de cuentas pendientes.
/// [T-AUTH-04] promoción/degradación de referentes barriales (RF-ROL-02).
/// [T-AUTH-08] lista de usuarios con filtros por rol y reputación.
class UsersManagementPage extends ConsumerWidget {
  const UsersManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.usersManagement),
          bottom: const TabBar(
            tabs: [
              Tab(text: AppStrings.tabPending),
              Tab(text: AppStrings.tabActive),
              Tab(text: AppStrings.tabBlocked),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PendingUsersTab(),
            _ActiveUsersTab(),
            _BlockedUsersTab(),
          ],
        ),
      ),
    );
  }
}

// ── Tab: Pendientes ──────────────────────────────────────────────────────────

class _PendingUsersTab extends ConsumerWidget {
  const _PendingUsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingUsersProvider);

    return pendingAsync.when(
      loading: () => const AppLoading(message: 'Cargando solicitudes…'),
      error: (e, _) => Center(
        child: Text(
          e.toString(),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
      data: (users) => users.isEmpty
          ? const _EmptyState(
              icon: Icons.how_to_reg_outlined,
              message: AppStrings.noPendingUsers,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) =>
                  _PendingUserCard(user: users[index]),
            ),
    );
  }
}

// ── Tab: Activos (T-AUTH-04) ─────────────────────────────────────────────────

class _ActiveUsersTab extends ConsumerStatefulWidget {
  const _ActiveUsersTab();

  @override
  ConsumerState<_ActiveUsersTab> createState() => _ActiveUsersTabState();
}

class _ActiveUsersTabState extends ConsumerState<_ActiveUsersTab> {
  UserRole? _roleFilter;

  @override
  Widget build(BuildContext context) {
    final activeAsync = ref.watch(activeUsersProvider(_roleFilter));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _RoleFilterChip(
                  label: 'Todos',
                  selected: _roleFilter == null,
                  onSelected: () => setState(() => _roleFilter = null),
                ),
                const SizedBox(width: 8),
                _RoleFilterChip(
                  label: AppStrings.roleVecino,
                  selected: _roleFilter == UserRole.vecinoInformante,
                  onSelected: () =>
                      setState(() => _roleFilter = UserRole.vecinoInformante),
                ),
                const SizedBox(width: 8),
                _RoleFilterChip(
                  label: AppStrings.roleReferente,
                  selected: _roleFilter == UserRole.referenteBarrial,
                  onSelected: () =>
                      setState(() => _roleFilter = UserRole.referenteBarrial),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: activeAsync.when(
            loading: () => const AppLoading(message: 'Cargando usuarios…'),
            error: (e, _) => Center(
              child: Text(
                e.toString(),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
            data: (users) => users.isEmpty
                ? const _EmptyState(
                    icon: Icons.people_outline,
                    message: AppStrings.noActiveUsers,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: users.length,
                    itemBuilder: (context, index) =>
                        _ActiveUserCard(user: users[index]),
                  ),
          ),
        ),
      ],
    );
  }
}

class _RoleFilterChip extends StatelessWidget {
  const _RoleFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

// ── Cards ────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            message,
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
            _UserHeader(user: user, statusChip: _StatusChip.pending()),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
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
      BuildContext context, WidgetRef ref, String uid) async {
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
      BuildContext context, WidgetRef ref, String uid) async {
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
}

class _ActiveUserCard extends ConsumerWidget {
  const _ActiveUserCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(userManagementNotifierProvider).isLoading;
    final isAdmin = user.role == UserRole.administrador;
    final isReferent = user.role == UserRole.referenteBarrial;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _UserHeader(
              user: user,
              statusChip: _StatusChip.role(user.role),
            ),
            if (!isAdmin) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isReferent)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.arrow_downward, size: 18),
                      label: const Text(AppStrings.demoteToVecino),
                      onPressed: isLoading
                          ? null
                          : () => _confirmDemote(context, ref, user.userId),
                    )
                  else
                    FilledButton.icon(
                      icon: const Icon(Icons.shield_outlined, size: 18),
                      label: const Text(AppStrings.promoteToReferent),
                      onPressed: isLoading
                          ? null
                          : () => _confirmPromote(context, ref, user.userId),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmPromote(
      BuildContext context, WidgetRef ref, String uid) async {
    final confirmed = await _showConfirmDialog(
      context: context,
      title: AppStrings.promoteConfirmTitle,
      body: AppStrings.promoteConfirmBody,
      confirmLabel: AppStrings.promoteToReferent,
      confirmColor: Theme.of(context).colorScheme.primary,
    );
    if (confirmed != true || !context.mounted) return;
    await ref
        .read(userManagementNotifierProvider.notifier)
        .promoteToReferent(uid);
    if (!context.mounted) return;
    final error = ref.read(userManagementNotifierProvider).error;
    if (error != null) {
      context.showSnackBar(error.toString(), isError: true);
    } else {
      context.showSnackBar(AppStrings.userPromoted);
    }
  }

  Future<void> _confirmDemote(
      BuildContext context, WidgetRef ref, String uid) async {
    final confirmed = await _showConfirmDialog(
      context: context,
      title: AppStrings.demoteConfirmTitle,
      body: AppStrings.demoteConfirmBody,
      confirmLabel: AppStrings.demoteToVecino,
      confirmColor: Theme.of(context).colorScheme.error,
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(userManagementNotifierProvider.notifier).demoteToVecino(uid);
    if (!context.mounted) return;
    final error = ref.read(userManagementNotifierProvider).error;
    if (error != null) {
      context.showSnackBar(error.toString(), isError: true);
    } else {
      context.showSnackBar(AppStrings.userDemoted);
    }
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.user, required this.statusChip});

  final AppUser user;
  final Widget statusChip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
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
              if (user.reputationScore < 30.0) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 14, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 4),
                    Text(
                      '${AppStrings.lowReputationWarning} ${user.reputationScore.toInt()} pts',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        statusChip,
      ],
    );
  }
}

enum _StatusChipVariant { pending, vecino, referente, admin }

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.variant, required this.label});

  factory _StatusChip.pending() => const _StatusChip(
      variant: _StatusChipVariant.pending, label: 'Pendiente');

  factory _StatusChip.role(UserRole role) {
    switch (role) {
      case UserRole.administrador:
        return const _StatusChip(
            variant: _StatusChipVariant.admin, label: AppStrings.roleAdmin);
      case UserRole.referenteBarrial:
        return const _StatusChip(
            variant: _StatusChipVariant.referente,
            label: AppStrings.roleReferente);
      case UserRole.vecinoInformante:
        return const _StatusChip(
            variant: _StatusChipVariant.vecino, label: AppStrings.roleVecino);
    }
  }

  final _StatusChipVariant variant;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (variant) {
      _StatusChipVariant.pending => (
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer
        ),
      _StatusChipVariant.referente => (
          scheme.secondaryContainer,
          scheme.onSecondaryContainer
        ),
      _StatusChipVariant.admin || _StatusChipVariant.vecino => (
          scheme.primaryContainer,
          scheme.onPrimaryContainer
        ),
    };
    return Chip(
      label: Text(label),
      backgroundColor: bg,
      labelStyle: TextStyle(color: fg, fontSize: 11),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

// ── Tab: Bloqueados (T-AUTH-07) ──────────────────────────────────────────────

class _BlockedUsersTab extends ConsumerWidget {
  const _BlockedUsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedAsync = ref.watch(blockedUsersProvider);

    return blockedAsync.when(
      loading: () => const AppLoading(message: 'Cargando bloqueados…'),
      error: (e, _) => Center(
        child: Text(
          e.toString(),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
      data: (users) => users.isEmpty
          ? const _EmptyState(
              icon: Icons.lock_open_outlined,
              message: AppStrings.noBlockedUsers,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) =>
                  _BlockedUserCard(user: users[index]),
            ),
    );
  }
}

class _BlockedUserCard extends ConsumerWidget {
  const _BlockedUserCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(moderationNotifierProvider).isLoading;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _UserHeader(
              user: user,
              statusChip: _StatusChip.role(user.role),
            ),
            const SizedBox(height: 4),
            Text(
              'Reportes falsos: ${user.falseReportsCount}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.lock_open, size: 18),
                  label: const Text(AppStrings.unblockUser),
                  onPressed: isLoading
                      ? null
                      : () => _confirmUnblock(context, ref, user.userId),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmUnblock(
      BuildContext context, WidgetRef ref, String uid) async {
    final confirmed = await _showConfirmDialog(
      context: context,
      title: AppStrings.unblockConfirmTitle,
      body: AppStrings.unblockConfirmBody,
      confirmLabel: AppStrings.unblockUser,
      confirmColor: Theme.of(context).colorScheme.primary,
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(moderationNotifierProvider.notifier).unblock(userId: uid);
    if (!context.mounted) return;
    final state = ref.read(moderationNotifierProvider);
    if (state.hasError) {
      context.showSnackBar(state.error.toString(), isError: true);
    } else {
      context.showSnackBar(AppStrings.userUnblocked);
    }
  }
}

// ── Dialog helper ────────────────────────────────────────────────────────────

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
          child: const Text(AppStrings.cancel),
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
