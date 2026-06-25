import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/incident_event.dart';
import '../providers/incidents_provider.dart';
import '../providers/vital_risk_provider.dart';
import '../widgets/vital_risk_dialog.dart';
import '../widgets/voice_report_widget.dart';

class ReportFormPage extends ConsumerStatefulWidget {
  const ReportFormPage({super.key});

  @override
  ConsumerState<ReportFormPage> createState() => _ReportFormPageState();
}

class _ReportFormPageState extends ConsumerState<ReportFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  IncidentCategory? _category;
  // Bytes + nombre del archivo: representación universal que funciona tanto en
  // mobile como en Flutter Web (donde `dart:io.File` no está disponible).
  Uint8List? _photoBytes;
  String? _photoName;
  bool _useVoice = false;
  // Persiste mientras la descripción provenga de transcripción por voz —
  // sobrevive a la edición manual posterior. Decisión D-10: corregir la
  // transcripción no convierte el reporte en `form`. Se resetea al cancelar
  // el modo voz explícitamente o al enviar con éxito.
  bool _originatedFromVoice = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      // En Web `ImageSource.camera` no está disponible; el picker abre el
      // selector de archivos por defecto. Usar `gallery` mantiene la misma
      // UX en mobile (galería) y en web (file picker).
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

  Future<Position?> _getPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        context.showSnackBar(AppStrings.locationUnavailable, isError: true);
      }
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        context.showSnackBar(AppStrings.locationUnavailable, isError: true);
      }
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } on TimeoutException catch (_) {
      if (mounted) {
        context.showSnackBar(AppStrings.locationTimeout, isError: true);
      }
      return null;
    } catch (_) {
      if (mounted) {
        context.showSnackBar(AppStrings.locationUnavailable, isError: true);
      }
      return null;
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    // Voice (D-10): no exigimos categoría — el caso de uso `submitVoice` la
    // deja nula y el pipeline NLP la enriquece (semanticExtraction).
    if (!_originatedFromVoice && _category == null) {
      context.showSnackBar(AppStrings.selectCategoryError, isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text(AppStrings.sendingReport),
        duration: Duration(minutes: 1),
      ),
    );
    try {
      // Chequeo de riesgo vital antes de pedir GPS / enviar. Si la descripción
      // tiene términos críticos (911/107), derivamos al usuario y NO creamos
      // el incident. [D-03 / RF-PRI-05]
      final description = _descCtrl.text.trim();
      final vitalRisk =
          await ref.read(vitalRiskCheckServiceProvider).check(description);
      if (!mounted) return;
      if (vitalRisk.isVitalRisk) {
        messenger.hideCurrentSnackBar();
        await VitalRiskDialog.show(context, vitalRisk);
        return;
      }

      final position = await _getPosition();
      if (position == null || !mounted) return;

      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null || !mounted) return;

      final notifier = ref.read(reportNotifierProvider.notifier);
      if (_originatedFromVoice) {
        // Reporte abreviado por voz (RF-REP-02 / T-INF-04). `sourceType: voice`
        // se setea en el use case dedicado. No mandamos categoría ni foto:
        // el use case voice no las soporta y el SRS define voice como modo
        // abreviado. [D-10]
        await notifier.submitVoice(
          userId: user.userId,
          latitude: position.latitude,
          longitude: position.longitude,
          transcribedText: description,
        );
      } else {
        await notifier.submitForm(
          userId: user.userId,
          latitude: position.latitude,
          longitude: position.longitude,
          description: description,
          category: _category!,
          photoBytes: _photoBytes,
          photoName: _photoName,
        );
      }

      if (!mounted) return;
      final error = ref.read(reportNotifierProvider).error;
      if (error != null) {
        context.showSnackBar(error.toString(), isError: true);
      } else {
        context.showSnackBar(AppStrings.reportSentSuccess);
        context.go(AppRoutes.home);
      }
    } finally {
      messenger.hideCurrentSnackBar();
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifierIsLoading = ref.watch(reportNotifierProvider).isLoading;
    final isBusy = _isSubmitting || notifierIsLoading;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.formReport)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Toggle voz / texto
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                      value: false,
                      label: Text(AppStrings.reportModeText),
                      icon: Icon(Icons.edit)),
                  ButtonSegment(
                      value: true,
                      label: Text(AppStrings.reportModeVoice),
                      icon: Icon(Icons.mic)),
                ],
                selected: {_useVoice},
                onSelectionChanged: (s) => setState(() => _useVoice = s.first),
              ),
              const SizedBox(height: 16),
              if (_useVoice)
                VoiceReportWidget(
                  onTranscription: (text) => setState(() {
                    _descCtrl.text = text;
                    _useVoice = false;
                    // D-10: marcar el origen como voz. Sobrevive a la edición
                    // manual posterior — solo se limpia si el usuario cancela
                    // explícitamente con el chip o si el envío fue exitoso.
                    _originatedFromVoice = true;
                  }),
                )
              else
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: AppStrings.reportDescription,
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? AppStrings.descriptionError
                      : null,
                ),
              if (_originatedFromVoice) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: InputChip(
                    avatar: const Icon(Icons.mic, size: 18),
                    label: const Text('Reporte por voz'),
                    onDeleted: () => setState(() {
                      _originatedFromVoice = false;
                      _descCtrl.clear();
                    }),
                    deleteIcon: const Icon(Icons.close, size: 18),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Categoría y foto: solo en modo formulario. El reporte por voz
              // es deliberadamente abreviado (T-INF-04 / RF-REP-02); el NLP
              // enriquece la categoría desde la descripción transcripta. [D-10]
              if (!_originatedFromVoice) ...[
                DropdownButtonFormField<IncidentCategory>(
                  decoration: const InputDecoration(
                    labelText: AppStrings.selectCategory,
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _category,
                  items: IncidentCategory.values
                      .map(
                        (c) => DropdownMenuItem(
                            value: c, child: Text(c.displayName)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _category = v),
                ),
                const SizedBox(height: 16),
                // Foto opcional (RF-REP-03)
                OutlinedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: Text(_photoBytes == null
                      ? AppStrings.addPhoto
                      : AppStrings.photoSelected),
                  onPressed: _pickPhoto,
                ),
                if (_photoBytes != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _photoBytes!,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 24),
              AppButton(
                label:
                    isBusy ? AppStrings.sendingReport : AppStrings.sendReport,
                onPressed: isBusy ? null : _submit,
                isLoading: isBusy,
                icon: Icons.send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
