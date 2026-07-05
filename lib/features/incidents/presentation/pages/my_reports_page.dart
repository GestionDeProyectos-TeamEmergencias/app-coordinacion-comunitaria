import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../domain/entities/incident_event.dart';
import '../providers/my_incidents_provider.dart';
import '../widgets/incident_status_badge.dart';

/// Listado de reportes del usuario actual, ordenados por fecha desc.
/// Acceso desde Perfil. Tocar un item abre el editor (modo edición si el
/// status es `recibido`, modo solo lectura en caso contrario). [F-01]
class MyReportsPage extends ConsumerWidget {
  const MyReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentsAsync = ref.watch(myIncidentsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis reportes')),
      body: incidentsAsync.when(
        loading: () => const AppLoading(message: 'Cargando tus reportes...'),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (incidents) {
          if (incidents.isEmpty) return const _Empty();
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: incidents.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) => _MyReportTile(incident: incidents[i]),
          );
        },
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'Todavía no enviaste reportes.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MyReportTile extends StatelessWidget {
  const _MyReportTile({required this.incident});

  final IncidentEvent incident;

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final title = incident.description ??
        incident.category?.displayName ??
        'Reporte rápido';
    final canEdit = incident.status == IncidentStatus.recibido;
    return ListTile(
      leading: Icon(
        canEdit ? Icons.edit_note : Icons.lock_outline,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            IncidentStatusBadge(status: incident.status),
            if (incident.priority != null)
              IncidentPriorityBadge(priority: incident.priority!),
            Text(_formatDate(incident.timestamp)),
          ],
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: incident.eventId == null
          ? null
          : () => context.push(AppRoutes.myReportEditPath(incident.eventId!)),
    );
  }
}
