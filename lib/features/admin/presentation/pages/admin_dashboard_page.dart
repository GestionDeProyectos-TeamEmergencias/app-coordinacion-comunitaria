import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Panel principal del Administrador Vecinal. [T-AUTH-01, T-AUTH-08, T-REP-06, T-NLP-09]
///
/// El badge en "Gestión de usuarios" muestra en tiempo real la cantidad de
/// cuentas pendientes de aprobación, cumpliendo con el criterio de notificación
/// al administrador definido en T-AUTH-01.
class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escucha en tiempo real los usuarios pendientes para el badge. [T-AUTH-01]
    final pendingCount =
        ref.watch(pendingUsersProvider).valueOrNull?.length ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.adminDashboard)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DashboardCard(
            icon: Icons.people,
            title: AppStrings.usersManagement,
            subtitle: 'Gestionar roles, reputación y bloqueos',
            badge: pendingCount > 0 ? pendingCount : null,
            onTap: () => context.go(AppRoutes.adminUsers),
          ),
          _DashboardCard(
            icon: Icons.report_gmailerrorred,
            title: AppStrings.incidentModeration,
            subtitle: 'Moderar incidentes y actualizar estados',
            onTap: () => context.go(AppRoutes.adminIncidents),
          ),
          _DashboardCard(
            icon: Icons.notifications_active,
            title: 'Notificaciones masivas',
            subtitle: 'Enviar alertas a todos los vecinos (T-NLP-09)',
            onTap: () {
              // TODO(T-NLP-09): implementar envío de notificaciones masivas
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Próximamente: notificaciones masivas')),
              );
            },
          ),
          _DashboardCard(
            icon: Icons.tune,
            title: 'Configuración del algoritmo NLP',
            subtitle: 'Calibrar pesos y palabras clave (T-NLP-06)',
            onTap: () {
              // TODO(T-NLP-06): implementar calibración del algoritmo
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Próximamente: calibración NLP')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Número mostrado como badge rojo. Null = sin badge.
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
            if (badge != null)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    '$badge',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onError,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
