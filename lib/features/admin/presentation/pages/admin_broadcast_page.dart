import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/coverage_config_provider.dart';

/// Pantalla del admin para enviar notificaciones push masivas. [T-NLP-09]
///
/// Permite enviar a toda la cobertura o a una zona específica (lat/lng/radio).
/// Invoca el callable `broadcastNotification` del backend.
class AdminBroadcastPage extends ConsumerStatefulWidget {
  const AdminBroadcastPage({super.key});

  @override
  ConsumerState<AdminBroadcastPage> createState() => _AdminBroadcastPageState();
}

class _AdminBroadcastPageState extends ConsumerState<AdminBroadcastPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _radiusCtrl = TextEditingController();

  bool _useArea = false;
  bool _sending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _radiusCtrl.dispose();
    super.dispose();
  }

  void _prefillFromCoverage() {
    // Si la cobertura ya está configurada, prefilleamos los campos para
    // ahorrarle al admin tipear coordenadas.
    final coverage = ref.read(coverageConfigProvider).valueOrNull;
    if (coverage == null) return;
    _latCtrl.text = coverage.centerLat.toString();
    _lngCtrl.text = coverage.centerLng.toString();
    _radiusCtrl.text = coverage.radiusMeters.toString();
  }

  Future<bool> _confirmSend() async {
    final scope = _useArea
        ? AppStrings.broadcastConfirmZonal
        : AppStrings.broadcastConfirmGlobal;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(AppStrings.broadcastConfirmTitle),
        content: Text(scope),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.broadcastSendButton),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (!await _confirmSend()) return;

    setState(() => _sending = true);
    try {
      final payload = <String, Object?>{
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
      };
      if (_useArea) {
        payload['area'] = {
          'latitude': double.parse(_latCtrl.text),
          'longitude': double.parse(_lngCtrl.text),
          'radiusMeters': double.parse(_radiusCtrl.text),
        };
      }

      final callable =
          FirebaseFunctions.instance.httpsCallable('broadcastNotification');
      final result = await callable.call<Map<Object?, Object?>>(payload);
      final data = result.data;
      final successCount = (data['successCount'] as num?)?.toInt() ?? 0;
      final failureCount = (data['failureCount'] as num?)?.toInt() ?? 0;

      if (!mounted) return;
      context.showSnackBar(
        AppStrings.broadcastSentSummary(successCount, failureCount),
      );
      _titleCtrl.clear();
      _bodyCtrl.clear();
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      context.showSnackBar(
        '${e.code}: ${e.message ?? AppStrings.broadcastGenericError}',
        isError: true,
      );
    } catch (e) {
      if (!mounted) return;
      context.showSnackBar('Error inesperado: $e', isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String? _requiredField(String? v) {
    if (v == null || v.trim().isEmpty) return AppStrings.fieldRequired;
    return null;
  }

  String? _validateLat(String? v) {
    if (v == null || v.trim().isEmpty) return AppStrings.fieldRequired;
    final n = double.tryParse(v);
    if (n == null) return AppStrings.invalidNumber;
    if (n < -90 || n > 90) return AppStrings.latitudeOutOfRange;
    return null;
  }

  String? _validateLng(String? v) {
    if (v == null || v.trim().isEmpty) return AppStrings.fieldRequired;
    final n = double.tryParse(v);
    if (n == null) return AppStrings.invalidNumber;
    if (n < -180 || n > 180) return AppStrings.longitudeOutOfRange;
    return null;
  }

  String? _validateRadius(String? v) {
    if (v == null || v.trim().isEmpty) return AppStrings.fieldRequired;
    final n = double.tryParse(v);
    if (n == null) return AppStrings.invalidNumber;
    if (n <= 0) return AppStrings.radiusMustBePositive;
    if (n > 100000) return AppStrings.broadcastRadiusTooLarge;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.broadcastTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.broadcastSubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
                maxLength: 100,
                validator: _requiredField,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bodyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Mensaje',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                maxLength: 400,
                validator: _requiredField,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text(AppStrings.broadcastUseAreaToggle),
                subtitle: const Text(AppStrings.broadcastUseAreaSubtitle),
                value: _useArea,
                onChanged: (v) {
                  setState(() => _useArea = v);
                  if (v && _latCtrl.text.isEmpty) _prefillFromCoverage();
                },
              ),
              if (_useArea) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Latitud',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        validator: _validateLat,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _lngCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Longitud',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        validator: _validateLng,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _radiusCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Radio (metros)',
                    border: OutlineInputBorder(),
                    helperText: 'Máximo 100 000 m (100 km).',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: _validateRadius,
                ),
              ],
              const SizedBox(height: 24),
              AppButton(
                label: AppStrings.broadcastSendButton,
                icon: Icons.send,
                isLoading: _sending,
                onPressed: _sending ? null : _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
