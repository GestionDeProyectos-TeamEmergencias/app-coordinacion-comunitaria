import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/moderation_provider.dart';
import '../../domain/entities/incident_event.dart';
import '../providers/incidents_provider.dart';
import '../widgets/incident_status_badge.dart';

String _formatDate(DateTime dt) {
  final d = dt.day.toString().padLeft(2, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final h = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  return '$d/$m/${dt.year} $h:$min';
}

// RF-ADM-02: visualización del estado de resolución con histórico. [T-REP-06]
class IncidentDetailPage extends ConsumerWidget {
  const IncidentDetailPage({super.key, required this.incidentId});

  final String incidentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentAsync = ref.watch(incidentByIdProvider(incidentId));
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.incidentDetailTitle)),
      body: incidentAsync.when(
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (incident) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Defense-in-depth: si el cliente no chequeó pre-envío (versión
              // vieja, race) y el incident quedó marcado, el reportero ve el
              // aviso al abrir el detalle. [D-03]
              if (incident.status == IncidentStatus.vitalRiskDetected) ...[
                const _VitalRiskBanner(),
                const SizedBox(height: 16),
              ],
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
              _InfoRow(label: 'Fecha', value: _formatDate(incident.timestamp)),
              _InfoRow(
                label: 'Ubicación',
                value:
                    '${incident.latitude.toStringAsFixed(5)}, ${incident.longitude.toStringAsFixed(5)}',
              ),
              if (user?.role.canVerify == true) ...[
                const Divider(height: 32),
                _StatusUpdater(
                  incidentId: incidentId,
                  currentStatus: incident.status,
                  userId: user!.userId,
                ),
                const SizedBox(height: 12),
                _MarkAsFalseButton(
                  incidentId: incidentId,
                  reporterUserId: incident.userId,
                  alreadyFalse: incident.status == IncidentStatus.falso,
                ),
              ],
              const Divider(height: 32),
              _StatusHistoryTimeline(history: incident.statusHistory),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusUpdater extends ConsumerStatefulWidget {
  const _StatusUpdater({
    required this.incidentId,
    required this.currentStatus,
    required this.userId,
  });

  final String incidentId;
  final IncidentStatus currentStatus;
  final String userId;

  @override
  ConsumerState<_StatusUpdater> createState() => _StatusUpdaterState();
}

class _StatusUpdaterState extends ConsumerState<_StatusUpdater> {
  // Marca si esta instancia del widget disparó una actualización pendiente
  // de feedback. Evita mostrar SnackBars heredados de operaciones previas.
  bool _awaitingFeedback = false;

  void _onChanged(IncidentStatus? newStatus) {
    if (newStatus == null || newStatus == widget.currentStatus) return;
    setState(() => _awaitingFeedback = true);
    ref.read(updateStatusNotifierProvider.notifier).update(
          eventId: widget.incidentId,
          status: newStatus,
          changedBy: widget.userId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(updateStatusNotifierProvider);
    final isLoading = updateState.isLoading;

    ref.listen(updateStatusNotifierProvider, (_, next) {
      if (!_awaitingFeedback || next.isLoading) return;
      if (next.hasError) {
        context.showSnackBar(next.error.toString(), isError: true);
      } else {
        context.showSnackBar(AppStrings.statusUpdatedSuccess);
      }
      setState(() => _awaitingFeedback = false);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.updateStatusTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        // Key fuerza recrear el dropdown cuando otro usuario cambia el estado
        // remotamente, así la selección refleja el valor del stream.
        DropdownButtonFormField<IncidentStatus>(
          key: ValueKey(widget.currentStatus),
          initialValue: widget.currentStatus,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: IncidentStatus.values
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.displayName),
                  ))
              .toList(),
          onChanged: isLoading ? null : _onChanged,
        ),
        if (isLoading) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }
}

class _StatusHistoryTimeline extends StatelessWidget {
  const _StatusHistoryTimeline({required this.history});

  final List<IncidentStatusChange> history;

  @override
  Widget build(BuildContext context) {
    final sorted = [...history]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.statusHistoryTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (sorted.isEmpty)
          const Text(AppStrings.statusHistoryEmpty)
        else
          ...sorted.map(
            (change) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.circle, size: 10, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IncidentStatusBadge(status: change.status),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(change.timestamp),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MarkAsFalseButton extends ConsumerWidget {
  const _MarkAsFalseButton({
    required this.incidentId,
    required this.reporterUserId,
    required this.alreadyFalse,
  });

  final String incidentId;
  final String reporterUserId;
  final bool alreadyFalse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(moderationNotifierProvider);
    final isLoading = state.isLoading;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.flag_outlined),
        label: Text(alreadyFalse
            ? AppStrings.reportAlreadyModerated
            : AppStrings.markAsFalseReport),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
          side: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        onPressed:
            (isLoading || alreadyFalse) ? null : () => _confirm(context, ref),
      ),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(AppStrings.markAsFalseConfirmTitle),
        content: const Text(AppStrings.markAsFalseConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.markAsFalseReport),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(moderationNotifierProvider.notifier).markAsFalse(
          incidentId: incidentId,
          userId: reporterUserId,
        );

    if (!context.mounted) return;
    final state = ref.read(moderationNotifierProvider);
    if (state.hasError) {
      context.showSnackBar(state.error.toString(), isError: true);
      return;
    }
    final result = ref.read(moderationNotifierProvider.notifier).lastResult;
    if (result?.alreadyModerated == true) {
      context.showSnackBar(AppStrings.reportAlreadyModerated);
    } else if (result?.blocked == true) {
      context.showSnackBar(AppStrings.userAutoBlocked);
    } else {
      context.showSnackBar(AppStrings.reportMarkedAsFalse);
    }
  }
}

class _VitalRiskBanner extends StatelessWidget {
  const _VitalRiskBanner();

  Future<void> _call(String number) async {
    try {
      await launchUrl(Uri(scheme: 'tel', path: number));
    } catch (_) {/* swallow */}
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.error, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: scheme.error, size: 32),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.vitalRiskTitle,
                  style: TextStyle(
                    color: scheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.vitalRiskBody,
            style: TextStyle(color: scheme.onErrorContainer),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.phone),
                  onPressed: () => _call('911'),
                  style: FilledButton.styleFrom(backgroundColor: scheme.error),
                  label: const Text(AppStrings.emergencyCall911),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.phone),
                  onPressed: () => _call('107'),
                  style: FilledButton.styleFrom(backgroundColor: scheme.error),
                  label: const Text(AppStrings.emergencyCall107),
                ),
              ),
            ],
          ),
        ],
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
