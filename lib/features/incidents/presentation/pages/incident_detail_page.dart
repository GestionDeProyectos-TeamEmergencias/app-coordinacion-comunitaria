import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/moderation_provider.dart';
import '../../domain/entities/incident_event.dart';
import '../providers/incident_admin_provider.dart';
import '../providers/incidents_provider.dart';
import '../providers/reactions_provider.dart';
import '../providers/referent_verification_provider.dart';
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
              // Categoría: solo lectura para todos, editable para admin. [D-06]
              if (user?.role == UserRole.administrador)
                _CategoryEditor(
                  incidentId: incidentId,
                  current: incident.category,
                  adminUid: user!.userId,
                )
              else if (incident.category != null)
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
              // Resumen de verificación del referente (visible a todos cuando
              // existe — es señal **autoritativa**). Por encima del bloque de
              // validación comunitaria por decisión de F-04 (jerarquía). [D-05]
              if (incident.referentVerification != null) ...[
                const Divider(height: 32),
                _ReferentVerificationSummary(
                  verification: incident.referentVerification!,
                ),
              ],
              // Validación comunitaria: señal social blanda. Visible a todos.
              // El dueño y los referentes/admin no votan, pero sí ven el score.
              // [F-04]
              const Divider(height: 32),
              _CommunityValidationSection(
                incidentId: incidentId,
                incident: incident,
                callerUser: user,
              ),
              // Avance de ciclo de vida (RF-ADM-02): solo el admin. El
              // referente verifica con su propio widget, sin tocar `status`.
              // [D-05 alinea esto con la jerarquía SRS]
              if (user?.role == UserRole.administrador) ...[
                const Divider(height: 32),
                _StatusUpdater(
                  incidentId: incidentId,
                  currentStatus: incident.status,
                  userId: user!.userId,
                ),
              ],
              // Acción del Referente Barrial: confirmar / descartar con foto
              // como evidencia. [D-05 / RF-ROL-02(b)]
              if (user?.role == UserRole.referenteBarrial) ...[
                const Divider(height: 32),
                _ReferentVerificationActions(
                  incidentId: incidentId,
                  user: user!,
                  current: incident.referentVerification,
                ),
              ],
              // Marcar como falso: disponible para admin y referente vía el
              // callable `moderateFalseReport` (T-AUTH-07). Único camino a
              // `falso` (D-07). Solo desde estados activos del ciclo: ya
              // resuelto / ya sancionado no se reabre por este camino.
              if (user?.role.canVerify == true &&
                  incident.status.canBeMarkedAsFalse) ...[
                const SizedBox(height: 12),
                _MarkAsFalseButton(
                  incidentId: incidentId,
                  reporterUserId: incident.userId,
                  alreadyFalse: incident.status == IncidentStatus.falso,
                ),
              ],
              const Divider(height: 32),
              _StatusHistoryTimeline(history: incident.statusHistory),
              // Acciones de resolución del admin (RF-ADM-03). Visible a todos
              // como rendición de cuentas; editable solo por el admin. [D-06]
              const Divider(height: 32),
              _ResolutionActionsSection(
                incidentId: incidentId,
                actions: incident.actions,
                isAdmin: user?.role == UserRole.administrador,
                adminUid: user?.userId,
                adminDisplayName: user?.displayName,
              ),
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

    // El dropdown solo expone transiciones válidas desde el estado actual.
    // Estados terminales (`solucionado` y marcadores) no permiten cambio
    // manual desde el cliente (la regla Firestore también lo bloquea). [D-07]
    final transitions = widget.currentStatus.allowedTransitions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.updateStatusTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (transitions.isEmpty)
          Text(
            'El ciclo de vida de este incidente ya está cerrado '
            '(${widget.currentStatus.displayName}). '
            'No hay transiciones válidas desde acá.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          DropdownButtonFormField<IncidentStatus>(
            // Key fuerza recrear el dropdown cuando otro usuario cambia el
            // estado remotamente, así la selección refleja el valor del stream.
            key: ValueKey(widget.currentStatus),
            initialValue: widget.currentStatus,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              // El estado actual aparece como opción "seleccionada" pero
              // deshabilitada para que el usuario vea de dónde parte.
              DropdownMenuItem(
                value: widget.currentStatus,
                child: Text(widget.currentStatus.displayName),
              ),
              ...transitions.map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(s.displayName),
                ),
              ),
            ],
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

/// Sección de validación comunitaria: contador de "Confirmo"/"No es así" +
/// badge "Validado por la comunidad" cuando el score supera el umbral. [F-04]
///
/// Comportamiento:
/// - Cualquier vecino activo distinto del dueño puede votar.
/// - El dueño, admins y referentes solo ven el conteo (no pueden votar).
/// - Tap en el botón ya elegido retira el voto.
/// - Las reglas Firestore son la última palabra: si por alguna razón se
///   intenta votarse a sí mismo, el server lo rechaza.
class _CommunityValidationSection extends ConsumerWidget {
  const _CommunityValidationSection({
    required this.incidentId,
    required this.incident,
    required this.callerUser,
  });

  final String incidentId;
  final IncidentEvent incident;
  final AppUser? callerUser;

  bool get _isOwner =>
      callerUser != null && callerUser!.userId == incident.userId;

  bool get _canVote {
    if (callerUser == null) return false;
    if (_isOwner) return false;
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myReactionAsync = _canVote
        ? ref.watch(myReactionForIncidentProvider(incidentId))
        : const AsyncValue<ReactionType?>.data(null);
    final current = myReactionAsync.valueOrNull;
    final isLoading = ref.watch(reactionsNotifierProvider).isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Validación comunitaria',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (incident.communityValidated) const _CommunityValidatedBadge(),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${incident.confirmsCount} confirmaciones · '
          '${incident.disputesCount} disputas '
          '(${(incident.confirmationScore * 100).toStringAsFixed(0)}% de '
          'acuerdo)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        if (_isOwner)
          Text(
            'Es tu reporte: no podés votarlo.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          )
        else if (!_canVote)
          Text(
            'Iniciá sesión para votar.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          )
        else
          Row(
            children: [
              Expanded(
                child: _ReactionButton(
                  label: 'Confirmo',
                  icon: Icons.thumb_up_alt_outlined,
                  iconActive: Icons.thumb_up_alt,
                  active: current == ReactionType.confirm,
                  loading: isLoading,
                  onPressed: () =>
                      ref.read(reactionsNotifierProvider.notifier).toggle(
                            incidentId: incidentId,
                            target: ReactionType.confirm,
                            current: current,
                          ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ReactionButton(
                  label: 'No es así',
                  icon: Icons.thumb_down_alt_outlined,
                  iconActive: Icons.thumb_down_alt,
                  active: current == ReactionType.dispute,
                  loading: isLoading,
                  onPressed: () =>
                      ref.read(reactionsNotifierProvider.notifier).toggle(
                            incidentId: incidentId,
                            target: ReactionType.dispute,
                            current: current,
                          ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    required this.label,
    required this.icon,
    required this.iconActive,
    required this.active,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final IconData iconActive;
  final bool active;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final style = active
        ? FilledButton.styleFrom(minimumSize: const Size.fromHeight(40))
        : OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(40));
    final iconWidget = Icon(active ? iconActive : icon, size: 18);
    final labelText = Text(label);
    return active
        ? FilledButton.icon(
            onPressed: loading ? null : onPressed,
            icon: iconWidget,
            label: labelText,
            style: style,
          )
        : OutlinedButton.icon(
            onPressed: loading ? null : onPressed,
            icon: iconWidget,
            label: labelText,
            style: style,
          );
  }
}

class _CommunityValidatedBadge extends StatelessWidget {
  const _CommunityValidatedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade700),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user, size: 14, color: Colors.green.shade700),
          const SizedBox(width: 4),
          Text(
            'Validado por la comunidad',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Resumen de la última verificación de campo del referente. Visible a todos
/// los usuarios cuando existe — es señal pública del estado del incident.
/// [D-05]
class _ReferentVerificationSummary extends StatelessWidget {
  const _ReferentVerificationSummary({required this.verification});

  final ReferentVerification verification;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isConfirmed =
        verification.state == ReferentVerificationState.confirmed;
    final color = isConfirmed ? Colors.green.shade700 : scheme.error;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isConfirmed ? Icons.verified : Icons.gpp_bad_outlined,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  verification.state.displayName,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Por ${verification.byDisplayName ?? verification.by} · '
            '${_formatDate(verification.at)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (verification.note != null && verification.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(verification.note!),
          ],
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              verification.photoUrl,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const SizedBox(height: 160, child: Icon(Icons.broken_image)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bloque interactivo para que el Referente Barrial confirme o descarte el
/// incidente con foto como evidencia. [D-05 / RF-ROL-02(b)]
class _ReferentVerificationActions extends ConsumerStatefulWidget {
  const _ReferentVerificationActions({
    required this.incidentId,
    required this.user,
    required this.current,
  });

  final String incidentId;
  final AppUser user;
  final ReferentVerification? current;

  @override
  ConsumerState<_ReferentVerificationActions> createState() =>
      _ReferentVerificationActionsState();
}

class _ReferentVerificationActionsState
    extends ConsumerState<_ReferentVerificationActions> {
  final _noteCtrl = TextEditingController();
  Uint8List? _photoBytes;
  String? _photoName;
  ReferentVerificationState? _pendingState;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _photoBytes = bytes;
      _photoName = picked.name;
    });
  }

  Future<void> _submit(ReferentVerificationState state) async {
    if (_photoBytes == null) {
      context.showSnackBar(
        'Adjuntá una foto como evidencia antes de enviar.',
        isError: true,
      );
      return;
    }
    setState(() => _pendingState = state);
    await ref.read(referentVerificationNotifierProvider.notifier).verify(
          incidentId: widget.incidentId,
          verificationState: state,
          photoBytes: _photoBytes!,
          photoName: _photoName ?? 'verification.jpg',
          referentUid: widget.user.userId,
          referentDisplayName: widget.user.displayName,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _pendingState = null);
    final result = ref.read(referentVerificationNotifierProvider);
    if (result.hasError) {
      context.showSnackBar(result.error.toString(), isError: true);
      return;
    }
    context.showSnackBar(
      state == ReferentVerificationState.confirmed
          ? 'Incidente confirmado por el referente.'
          : 'Incidente descartado por el referente.',
    );
    // Reset para una re-verificación posterior si hace falta.
    setState(() {
      _photoBytes = null;
      _photoName = null;
      _noteCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(referentVerificationNotifierProvider).isLoading;
    final hasPhoto = _photoBytes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.current == null
              ? 'Verificación de campo'
              : 'Re-verificar (sobrescribe el último estado)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _noteCtrl,
          decoration: const InputDecoration(
            labelText: 'Nota (opcional)',
            border: OutlineInputBorder(),
            hintText: 'Detalles de lo que viste en terreno',
          ),
          maxLines: 2,
          enabled: !isLoading,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.camera_alt),
          label: Text(hasPhoto ? 'Foto cargada ✓' : 'Adjuntar evidencia'),
          onPressed: isLoading ? null : _pickPhoto,
        ),
        if (hasPhoto) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              _photoBytes!,
              height: 140,
              fit: BoxFit.cover,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Confirmar',
                icon: Icons.verified,
                isLoading: _pendingState == ReferentVerificationState.confirmed,
                onPressed: isLoading
                    ? null
                    : () => _submit(ReferentVerificationState.confirmed),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.gpp_bad_outlined),
                label: const Text('Descartar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: isLoading
                    ? null
                    : () => _submit(ReferentVerificationState.dismissed),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Editor de categoría para el Administrador. Reemplaza el `_InfoRow` de
/// solo lectura cuando el caller es admin. [D-06 / RF-ADM-03]
class _CategoryEditor extends ConsumerWidget {
  const _CategoryEditor({
    required this.incidentId,
    required this.current,
    required this.adminUid,
  });

  final String incidentId;
  final IncidentCategory? current;
  final String adminUid;

  void _onChanged(BuildContext context, WidgetRef ref, IncidentCategory? next) {
    if (next == null || next == current) return;
    ref.read(incidentAdminNotifierProvider.notifier).reassignCategory(
          incidentId: incidentId,
          category: next,
          adminUid: adminUid,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(incidentAdminNotifierProvider).isLoading;
    ref.listen(incidentAdminNotifierProvider, (_, next) {
      if (next.isLoading) return;
      if (next.hasError) {
        context.showSnackBar(next.error.toString(), isError: true);
      }
    });

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 110,
            child: Text(
              'Categoría:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: DropdownButtonFormField<IncidentCategory>(
              key: ValueKey(current),
              initialValue: current,
              isDense: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: IncidentCategory.values
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text('${c.emoji} ${c.displayName}'),
                      ))
                  .toList(),
              onChanged: isLoading ? null : (v) => _onChanged(context, ref, v),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sección "Acciones tomadas": feed cronológico de notas que registra el
/// Administrador a lo largo del ciclo de resolución. Visible al vecino dueño
/// como rendición de cuentas. [D-06 / RF-ADM-03]
class _ResolutionActionsSection extends ConsumerStatefulWidget {
  const _ResolutionActionsSection({
    required this.incidentId,
    required this.actions,
    required this.isAdmin,
    required this.adminUid,
    required this.adminDisplayName,
  });

  final String incidentId;
  final List<ResolutionAction> actions;
  final bool isAdmin;
  final String? adminUid;
  final String? adminDisplayName;

  @override
  ConsumerState<_ResolutionActionsSection> createState() =>
      _ResolutionActionsSectionState();
}

class _ResolutionActionsSectionState
    extends ConsumerState<_ResolutionActionsSection> {
  final _noteCtrl = TextEditingController();
  bool _awaitingFeedback = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _addAction() async {
    final note = _noteCtrl.text.trim();
    if (note.isEmpty || widget.adminUid == null) return;
    setState(() => _awaitingFeedback = true);
    await ref.read(incidentAdminNotifierProvider.notifier).addAction(
          incidentId: widget.incidentId,
          note: note,
          adminUid: widget.adminUid!,
          adminDisplayName: widget.adminDisplayName,
        );
    if (!mounted) return;
    final result = ref.read(incidentAdminNotifierProvider);
    setState(() => _awaitingFeedback = false);
    if (result.hasError) {
      context.showSnackBar(result.error.toString(), isError: true);
      return;
    }
    _noteCtrl.clear();
    context.showSnackBar('Acción registrada.');
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        _awaitingFeedback && ref.watch(incidentAdminNotifierProvider).isLoading;
    final sorted = [...widget.actions]..sort((a, b) => b.at.compareTo(a.at));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones tomadas',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (sorted.isEmpty)
          Text(
            widget.isAdmin
                ? 'Todavía no se registraron acciones.'
                : 'El administrador aún no registró acciones sobre tu reporte.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          ...sorted.map(
            (a) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.task_alt, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.note),
                        const SizedBox(height: 2),
                        Text(
                          '${a.byDisplayName ?? a.by} · ${_formatDate(a.at)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (widget.isAdmin) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            enabled: !isLoading,
            decoration: const InputDecoration(
              labelText: 'Nueva acción',
              hintText: 'Ej.: derivado a Obras Públicas',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: Text(isLoading ? 'Registrando…' : 'Registrar acción'),
            onPressed: isLoading ? null : _addAction,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
          ),
        ],
      ],
    );
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
