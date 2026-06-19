import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../admin/presentation/providers/coverage_config_provider.dart';
import '../../../incidents/domain/entities/incident_event.dart';
import '../../../incidents/presentation/providers/incidents_provider.dart';
import '../../../incidents/presentation/widgets/incident_status_badge.dart';

/// Pantalla de gestión de alertas para el Referente Barrial. [T-AUTH-04]
///
/// Muestra los incidentes activos con prioridad Urgente o Alta — son los que
/// generan notificaciones push geolocalizadas (T-NLP-07). Esta vista cumple el
/// criterio "se habilita la pantalla de gestión de alertas" de RF-ROL-02.
class ReferentAlertsPage extends ConsumerWidget {
  const ReferentAlertsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentsAsync = ref.watch(activeIncidentsStreamProvider);
    final coverageAsync = ref.watch(coverageConfigProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.referentAlertsTitle)),
      body: incidentsAsync.when(
        loading: () => const AppLoading(message: 'Cargando alertas...'),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (incidents) {
          // Usa la cobertura configurada por el admin (T-AUTH-06).
          // Si todavía no se cargó, no filtra por zona — evita ocultar alertas
          // mientras carga el stream de config.
          final coverage = coverageAsync.valueOrNull;

          final alerts = incidents
              .where((i) =>
                  (i.priority == IncidentPriority.urgente ||
                      i.priority == IncidentPriority.alta) &&
                  (coverage == null ||
                      coverage.isWithinCoverage(i.latitude, i.longitude)))
              .toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

          if (alerts.isEmpty) {
            return const _EmptyAlerts();
          }

          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  AppStrings.referentAlertsSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: alerts.length,
                  itemBuilder: (context, i) => _AlertCard(incident: alerts[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyAlerts extends StatelessWidget {
  const _EmptyAlerts();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.noActiveAlerts,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.incident});

  final IncidentEvent incident;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          incident.priority == IncidentPriority.urgente
              ? Icons.warning
              : Icons.notifications_active,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(
          incident.description ??
              incident.category?.displayName ??
              AppStrings.mapDefaultCategory,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            if (incident.priority != null) ...[
              IncidentPriorityBadge(priority: incident.priority!),
              const SizedBox(width: 8),
            ],
            IncidentStatusBadge(status: incident.status),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: incident.eventId == null
            ? null
            : () => context.go(AppRoutes.incidentDetailPath(incident.eventId!)),
      ),
    );
  }
}
