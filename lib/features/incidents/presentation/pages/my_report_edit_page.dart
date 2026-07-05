import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/incident_event.dart';
import '../providers/incidents_provider.dart';
import '../providers/my_incidents_provider.dart';
import '../widgets/incident_status_badge.dart';

/// Editor / visor de un reporte propio. Si el incident está en `recibido`,
/// permite editar descripción, categoría y foto. Si ya pasó a otro estado,
/// los campos son solo lectura con un badge "ya procesado". [F-01]
class MyReportEditPage extends ConsumerStatefulWidget {
  const MyReportEditPage({super.key, required this.incidentId});

  final String incidentId;

  @override
  ConsumerState<MyReportEditPage> createState() => _MyReportEditPageState();
}

class _MyReportEditPageState extends ConsumerState<MyReportEditPage> {
  final _descCtrl = TextEditingController();
  IncidentCategory? _category;
  Uint8List? _newPhotoBytes;
  String? _newPhotoName;
  bool _hydrated = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  /// Inicializa el form con los valores actuales del incident la primera vez
  /// que el stream emite. Evita pisar la edición del usuario en re-emits.
  void _hydrate(IncidentEvent incident) {
    if (_hydrated) return;
    _descCtrl.text = incident.description ?? '';
    _category = incident.category;
    _hydrated = true;
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
      _newPhotoBytes = bytes;
      _newPhotoName = picked.name;
    });
  }

  Future<void> _save(IncidentEvent incident) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    final description = _descCtrl.text.trim();
    if (description.isEmpty && (_category ?? incident.category) == null) {
      context.showSnackBar(
        'Agregá una descripción o una categoría antes de guardar.',
        isError: true,
      );
      return;
    }
    await ref.read(editOwnIncidentNotifierProvider.notifier).save(
          eventId: widget.incidentId,
          ownerUid: user.userId,
          description: description.isEmpty ? null : description,
          category: _category,
          newPhotoBytes: _newPhotoBytes,
          newPhotoName: _newPhotoName,
        );
    if (!mounted) return;
    final result = ref.read(editOwnIncidentNotifierProvider);
    if (result.hasError) {
      context.showSnackBar(result.error.toString(), isError: true);
      return;
    }
    context.showSnackBar('Cambios guardados.');
    setState(() {
      _newPhotoBytes = null;
      _newPhotoName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final incidentAsync = ref.watch(incidentByIdProvider(widget.incidentId));
    final isSaving = ref.watch(editOwnIncidentNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi reporte')),
      body: incidentAsync.when(
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (incident) {
          _hydrate(incident);
          final canEdit = incident.status == IncidentStatus.recibido;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IncidentStatusBadge(status: incident.status),
                    if (incident.priority != null) ...[
                      const SizedBox(width: 8),
                      IncidentPriorityBadge(priority: incident.priority!),
                    ],
                  ],
                ),
                if (!canEdit) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Este reporte ya fue procesado por el sistema. '
                            'No podés editarlo, pero podés consultar su estado.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  enabled: canEdit && !isSaving,
                  decoration: const InputDecoration(
                    labelText: AppStrings.reportDescription,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<IncidentCategory>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: AppStrings.selectCategory,
                    border: OutlineInputBorder(),
                  ),
                  items: IncidentCategory.values
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text('${c.emoji} ${c.displayName}'),
                        ),
                      )
                      .toList(),
                  onChanged: (canEdit && !isSaving)
                      ? (v) => setState(() => _category = v)
                      : null,
                ),
                const SizedBox(height: 16),
                _PhotoSection(
                  existingUrl: incident.photoUrl,
                  newBytes: _newPhotoBytes,
                  canEdit: canEdit,
                  onPick: isSaving ? null : _pickPhoto,
                ),
                const SizedBox(height: 24),
                if (canEdit)
                  AppButton(
                    label: isSaving ? 'Guardando…' : 'Guardar cambios',
                    icon: Icons.save,
                    isLoading: isSaving,
                    onPressed: isSaving ? null : () => _save(incident),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({
    required this.existingUrl,
    required this.newBytes,
    required this.canEdit,
    required this.onPick,
  });

  final String? existingUrl;
  final Uint8List? newBytes;
  final bool canEdit;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    Widget? preview;
    if (newBytes != null) {
      preview = Image.memory(newBytes!, height: 180, fit: BoxFit.cover);
    } else if (existingUrl != null) {
      preview = Image.network(
        existingUrl!,
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canEdit)
          OutlinedButton.icon(
            icon: const Icon(Icons.camera_alt),
            label: Text(
              existingUrl == null && newBytes == null
                  ? AppStrings.addPhoto
                  : 'Cambiar foto',
            ),
            onPressed: onPick,
          ),
        if (preview != null) ...[
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(8), child: preview),
        ],
      ],
    );
  }
}
