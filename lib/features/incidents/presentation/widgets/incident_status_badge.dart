import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/incident_event.dart';

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
