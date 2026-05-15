import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/incident_event.dart';
import '../providers/incidents_provider.dart';
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
  File? _photo;
  bool _useVoice = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      context.showSnackBar('Seleccioná una categoría.', isError: true);
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null || !mounted) return;

    await ref.read(reportNotifierProvider.notifier).submitForm(
      userId: user.userId,
      latitude: position.latitude,
      longitude: position.longitude,
      description: _descCtrl.text.trim(),
      category: _category!,
      photoFile: _photo,
    );

    if (!mounted) return;
    final error = ref.read(reportNotifierProvider).error;
    if (error != null) {
      context.showSnackBar(error.toString(), isError: true);
    } else {
      context.showSnackBar(AppStrings.reportSentSuccess);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(reportNotifierProvider).isLoading;

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
                  ButtonSegment(value: false, label: Text('Texto'), icon: Icon(Icons.edit)),
                  ButtonSegment(value: true, label: Text('Voz'), icon: Icon(Icons.mic)),
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
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Describí el incidente' : null,
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<IncidentCategory>(
                decoration: const InputDecoration(
                  labelText: AppStrings.selectCategory,
                  border: OutlineInputBorder(),
                ),
                value: _category,
                items: IncidentCategory.values
                    .map(
                      (c) => DropdownMenuItem(value: c, child: Text(c.displayName)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _category = v),
              ),
              const SizedBox(height: 16),
              // Foto opcional (RF-REP-03)
              OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: Text(_photo == null ? AppStrings.addPhoto : 'Foto seleccionada ✓'),
                onPressed: _pickPhoto,
              ),
              if (_photo != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_photo!, height: 180, fit: BoxFit.cover),
                ),
              ],
              const SizedBox(height: 24),
              AppButton(
                label: AppStrings.sendReport,
                onPressed: _submit,
                isLoading: isLoading,
                icon: Icons.send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
