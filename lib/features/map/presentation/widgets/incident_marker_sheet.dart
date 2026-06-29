import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../incidents/domain/entities/incident_event.dart';
import '../../../incidents/presentation/widgets/incident_status_badge.dart';

/// Hoja inferior que aparece al tocar un marcador del mapa. Muestra un resumen
/// del incidente y un botón explícito "Ir al detalle". Se mantiene como widget
/// aislado y sin dependencia de navegación (recibe `onOpenDetail`) para poder
/// testearlo sin el platform view de Google Maps.
class IncidentMarkerSheet extends StatelessWidget {
  const IncidentMarkerSheet({
    super.key,
    required this.incident,
    this.onOpenDetail,
  });

  final IncidentEvent incident;

  /// Acción del botón "Ir al detalle". Si es `null` (p. ej. incidente sin
  /// `eventId`), el botón no se muestra.
  final VoidCallback? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final categoryLabel = incident.category != null
        ? '${incident.category!.emoji} ${incident.category!.displayName}'
        : AppStrings.mapDefaultCategory;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              categoryLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IncidentStatusBadge(status: incident.status),
                if (incident.priority != null) ...[
                  const SizedBox(width: 8),
                  IncidentPriorityBadge(priority: incident.priority!),
                ],
              ],
            ),
            if (incident.description != null) ...[
              const SizedBox(height: 12),
              Text(incident.description!),
            ],
            const SizedBox(height: 16),
            if (onOpenDetail != null)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onOpenDetail,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text(AppStrings.goToDetail),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
