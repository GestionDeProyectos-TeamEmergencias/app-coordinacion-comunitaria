import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/incident_event.dart';
import '../../domain/referent_verification_aggregate.dart';

class IncidentStatusBadge extends StatelessWidget {
  const IncidentStatusBadge({super.key, required this.status});

  final IncidentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      IncidentStatus.recibido => AppColors.statusReceived,
      IncidentStatus.programado => AppColors.statusScheduled,
      IncidentStatus.enReparacion => AppColors.statusInProgress,
      IncidentStatus.solucionado => AppColors.statusSolved,
      IncidentStatus.rechazadoFueraDeCobertura => AppColors.priorityUrgent,
      IncidentStatus.falso => AppColors.priorityUrgent,
      // Riesgo vital: rojo crítico, igual que prioridad urgente. [D-03]
      IncidentStatus.vitalRiskDetected => AppColors.priorityUrgent,
      IncidentStatus.rechazadoAutorInactivo => AppColors.priorityUrgent,
    };

    return Chip(
      label: Text(status.displayName),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      padding: EdgeInsets.zero,
    );
  }
}

class IncidentPriorityBadge extends StatelessWidget {
  const IncidentPriorityBadge({super.key, required this.priority});

  final IncidentPriority priority;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      IncidentPriority.urgente => AppColors.priorityUrgent,
      IncidentPriority.alta => AppColors.priorityHigh,
      IncidentPriority.media => AppColors.priorityMedium,
      IncidentPriority.baja => AppColors.priorityLow,
    };

    return Chip(
      label: Text(priority.displayName),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      padding: EdgeInsets.zero,
    );
  }
}

/// Indicador de **veracidad**: refleja la verificación in-situ de los referentes
/// barriales sobre el incidente. Es ortogonal a la prioridad (no la modifica).
///
/// No se renderiza cuando ningún referente intervino todavía
/// (`ReferentAggregateState.none`) para no ensuciar la lista.
class ReferentVerificationBadge extends StatelessWidget {
  const ReferentVerificationBadge({super.key, required this.aggregate});

  final ReferentVerificationAggregate aggregate;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (aggregate.state) {
      ReferentAggregateState.confirmed => (
          AppColors.statusSolved,
          Icons.verified,
          aggregate.confirms > 1
              ? 'Avalado · ${aggregate.confirms}'
              : 'Avalado',
        ),
      ReferentAggregateState.disputed => (
          AppColors.priorityHigh,
          Icons.warning_amber_rounded,
          'En disputa ${aggregate.confirms}✓·${aggregate.dismisses}✗',
        ),
      ReferentAggregateState.dismissed => (
          AppColors.statusReceived,
          Icons.cancel_outlined,
          'Descartado por referente',
        ),
      // Sin intervención de referentes: no se muestra badge.
      ReferentAggregateState.none => (null, null, null),
    };

    if (color == null || icon == null || label == null) {
      return const SizedBox.shrink();
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      padding: EdgeInsets.zero,
    );
  }
}
