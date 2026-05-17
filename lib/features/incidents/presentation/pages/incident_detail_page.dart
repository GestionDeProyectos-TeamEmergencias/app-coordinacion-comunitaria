import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/incidents_provider.dart';
import '../widgets/incident_status_badge.dart';

// RF-ADM-02: visualización del estado de resolución con histórico. [T-REP-06]
class IncidentDetailPage extends ConsumerWidget {
  const IncidentDetailPage({super.key, required this.incidentId});

  final String incidentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentAsync = ref.watch(incidentByIdProvider(incidentId));
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del incidente')),
      body: incidentAsync.when(
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (incident) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (incident.photoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    incident.photoUrl!,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IncidentStatusBadge(status: incident.status),
                  if (incident.priority != null) ...[
                    const SizedBox(width: 8),
                    IncidentPriorityBadge(priority: incident.priority!),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              if (incident.category != null)
                _InfoRow(
                    label: 'Categoría', value: incident.category!.displayName),
              if (incident.description != null)
                _InfoRow(label: 'Descripción', value: incident.description!),
              _InfoRow(
                label: 'Tipo de reporte',
                value: switch (incident.sourceType.value) {
                  'quick' => 'Reporte rápido',
                  'form' => 'Formulario',
                  'voice' => 'Voz',
                  _ => incident.sourceType.value,
                },
              ),
              _InfoRow(
                label: 'Fecha',
                value:
                    '${incident.timestamp.day}/${incident.timestamp.month}/${incident.timestamp.year} '
                    '${incident.timestamp.hour.toString().padLeft(2, '0')}:${incident.timestamp.minute.toString().padLeft(2, '0')}',
              ),
              _InfoRow(
                label: 'Ubicación',
                value:
                    '${incident.latitude.toStringAsFixed(5)}, ${incident.longitude.toStringAsFixed(5)}',
              ),
              // Selector de estado solo para referentes y admin [T-REP-06]
              if (user?.role.canVerify == true) ...[
                const Divider(height: 32),
                Text(
                  'Actualizar estado',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                // TODO(T-REP-06): implementar selector de estado con historial
                const Text('(Próximamente: selector de estados con historial)'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
