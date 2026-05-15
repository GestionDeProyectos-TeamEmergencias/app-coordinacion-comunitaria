import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/constants/app_strings.dart';

// Panel principal del Administrador Vecinal. [T-AUTH-08, T-REP-06, T-NLP-09]
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.adminDashboard)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DashboardCard(
            icon: Icons.people,
            title: AppStrings.usersManagement,
            subtitle: 'Gestionar roles, reputación y bloqueos',
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
                const SnackBar(content: Text('Próximamente: notificaciones masivas')),
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
