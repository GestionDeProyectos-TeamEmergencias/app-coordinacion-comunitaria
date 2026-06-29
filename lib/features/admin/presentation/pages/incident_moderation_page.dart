import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../incidents/domain/entities/incident_event.dart';
import '../../../incidents/domain/referent_verification_aggregate.dart';
import '../../../incidents/presentation/providers/incidents_provider.dart';
import '../../../incidents/presentation/widgets/incident_status_badge.dart';

/// Panel de moderación de incidentes activos. RF-MOD-03 + RF-ADM-02.
///
/// El admin/referente ve la lista de incidentes activos (no solucionados ni
/// rechazados) y entra al detalle para marcar como falso (T-AUTH-07) o
/// actualizar el estado de resolución (T-REP-06).
class IncidentModerationPage extends ConsumerStatefulWidget {
  const IncidentModerationPage({super.key});

  @override
  ConsumerState<IncidentModerationPage> createState() =>
      _IncidentModerationPageState();
}

class _IncidentModerationPageState
    extends ConsumerState<IncidentModerationPage> {
  IncidentPriority? _priorityFilter;

  @override
  Widget build(BuildContext context) {
    final incidentsAsync = ref.watch(activeIncidentsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.incidentModeration)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _PriorityFilterChip(
                    label: 'Todas',
                    selected: _priorityFilter == null,
                    onSelected: () => setState(() => _priorityFilter = null),
                  ),
                  for (final p in IncidentPriority.values) ...[
                    const SizedBox(width: 8),
                    _PriorityFilterChip(
                      label: p.displayName,
                      selected: _priorityFilter == p,
                      onSelected: () => setState(() => _priorityFilter = p),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: incidentsAsync.when(
              loading: () =>
                  const AppLoading(message: 'Cargando incidentes...'),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Error: $e',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ),
              data: (incidents) {
                final filtered = _priorityFilter == null
                    ? incidents
                    : incidents
                        .where((i) => i.priority == _priorityFilter)
                        .toList();
                final sorted = [...filtered]
                  ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

                if (sorted.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 56,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No hay incidentes activos.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: sorted.length,
                  itemBuilder: (context, i) =>
                      _IncidentCard(incident: sorted[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityFilterChip extends StatelessWidget {
  const _PriorityFilterChip({
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

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({required this.incident});

  final IncidentEvent incident;

  @override
  Widget build(BuildContext context) {
    // Indicador de veracidad (ortogonal a la prioridad): refleja la verificación
    // in-situ de los referentes. No se muestra si ninguno intervino. [G-2]
    final referentAggregate =
        aggregateReferentVerification(incident.referentVerificationHistory);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(
          Icons.report_gmailerrorred,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          incident.description ??
              incident.category?.displayName ??
              AppStrings.mapDefaultCategory,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IncidentStatusBadge(status: incident.status),
                if (incident.priority != null) ...[
                  const SizedBox(width: 8),
                  IncidentPriorityBadge(priority: incident.priority!),
                ],
                if (referentAggregate.state != ReferentAggregateState.none) ...[
                  const SizedBox(width: 8),
                  ReferentVerificationBadge(aggregate: referentAggregate),
                ],
                const SizedBox(width: 8),
                Text(_formatDate(incident.timestamp)),
              ],
            ),
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: incident.eventId == null
            ? null
            : () => context.go(AppRoutes.incidentDetailPath(incident.eventId!)),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/${dt.year} $h:$min';
  }
}
