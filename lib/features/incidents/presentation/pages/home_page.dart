import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/incidents_provider.dart';
import '../widgets/incident_status_badge.dart';
import '../widgets/quick_report_button.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final incidentsAsync = ref.watch(incidentsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          if (user?.role == UserRole.administrador)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: AppStrings.adminDashboard,
              onPressed: () => context.go(AppRoutes.admin),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: AppStrings.logout,
            onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Botón de reporte rápido (RF-REP-01)
          Padding(
            padding: const EdgeInsets.all(16),
            child: const QuickReportButton(),
          ),
          const Divider(),
          // Lista de incidentes en tiempo real
          Expanded(
            child: incidentsAsync.when(
              loading: () =>
                  const AppLoading(message: 'Cargando incidentes...'),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (incidents) => incidents.isEmpty
                  ? const Center(child: Text('No hay incidentes reportados.'))
                  : ListView.builder(
                      itemCount: incidents.length,
                      itemBuilder: (context, i) {
                        final incident = incidents[i];
                        return ListTile(
                          leading: const Icon(Icons.report_problem),
                          title: Text(
                            incident.description ??
                                incident.category?.displayName ??
                                'Reporte rápido',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${incident.timestamp.day}/${incident.timestamp.month}/${incident.timestamp.year}',
                          ),
                          trailing:
                              IncidentStatusBadge(status: incident.status),
                          onTap: () => context.go(
                            AppRoutes.incidentDetailPath(incident.eventId!),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'voice',
            onPressed: () => context.go(AppRoutes.reportForm),
            icon: const Icon(Icons.edit_note),
            label: const Text('Reporte detallado'),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'map',
            onPressed: () => context.go(AppRoutes.map),
            child: const Icon(Icons.map),
          ),
        ],
      ),
    );
  }
}
