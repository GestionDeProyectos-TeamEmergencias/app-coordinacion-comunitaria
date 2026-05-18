import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  String _roleLabel(UserRole role) => switch (role) {
        UserRole.vecinoInformante => 'Vecino informante',
        UserRole.referenteBarrial => 'Referente barrial',
        UserRole.administrador => 'Administrador',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.navProfile)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 48)),
          const SizedBox(height: 16),
          Center(
            child: Text(
              user.displayName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Center(
            child: Text(
              _roleLabel(user.role),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _InfoTile(
                label: 'Reputación',
                value: '${user.reputationScore.toStringAsFixed(0)} pts',
                icon: Icons.star_outline,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (user.role == UserRole.administrador) ...[
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text(AppStrings.adminDashboard),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/admin'),
            ),
            const Divider(height: 1),
          ],
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text(AppStrings.logout),
            onTap: () => ref.read(authNotifierProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
