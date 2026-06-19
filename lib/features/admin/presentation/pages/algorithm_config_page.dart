import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loading.dart';

/// Panel del administrador para calibrar el algoritmo de priorización NLP.
/// Edita los thresholds que definen cuándo un incidente es Urgente / Alta /
/// Media / Baja, llamando a los callables `getAlgorithmConfig` y
/// `updateAlgorithmConfig` ya implementados en `functions/src/index.ts`. [T-NLP-06]
class AlgorithmConfigPage extends ConsumerStatefulWidget {
  const AlgorithmConfigPage({super.key});

  @override
  ConsumerState<AlgorithmConfigPage> createState() =>
      _AlgorithmConfigPageState();
}

class _AlgorithmConfigPageState extends ConsumerState<AlgorithmConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final _urgenteCtrl = TextEditingController();
  final _altaCtrl = TextEditingController();
  final _mediaCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _urgenteCtrl.dispose();
    _altaCtrl.dispose();
    _mediaCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('getAlgorithmConfig');
      final result = await callable.call<Map<Object?, Object?>>();
      final config = (result.data['config'] ?? {}) as Map<Object?, Object?>;
      final thresholds =
          (config['priorityThresholds'] ?? {}) as Map<Object?, Object?>;
      _urgenteCtrl.text = '${thresholds['urgente'] ?? 80}';
      _altaCtrl.text = '${thresholds['alta'] ?? 60}';
      _mediaCtrl.text = '${thresholds['media'] ?? 30}';
    } on FirebaseFunctionsException catch (e) {
      _loadError = '${e.code}: ${e.message ?? "Error al cargar la config."}';
    } catch (e) {
      _loadError = 'Error inesperado: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('updateAlgorithmConfig');
      await callable.call<Map<Object?, Object?>>({
        'patch': {
          'priorityThresholds': {
            'urgente': int.parse(_urgenteCtrl.text),
            'alta': int.parse(_altaCtrl.text),
            'media': int.parse(_mediaCtrl.text),
          },
        },
      });
      if (!mounted) return;
      context.showSnackBar(AppStrings.algorithmConfigUpdated);
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      context.showSnackBar(
        '${e.code}: ${e.message ?? "Error al guardar."}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _validateThreshold(String? v) {
    if (v == null || v.trim().isEmpty) return AppStrings.fieldRequired;
    final n = int.tryParse(v);
    if (n == null) return AppStrings.invalidNumber;
    if (n < 0 || n > 100) return 'Debe estar entre 0 y 100.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.algorithmConfig)),
      body: _loading
          ? const AppLoading()
          : _loadError != null
              ? _ErrorRetry(error: _loadError!, onRetry: _fetch)
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          AppStrings.algorithmConfigSubtitle,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Umbrales de prioridad',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _urgenteCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Umbral Urgente (≥)',
                            helperText: 'Score mínimo para marcar como Urgente.',
                          ),
                          keyboardType: TextInputType.number,
                          validator: _validateThreshold,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _altaCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Umbral Alta (≥)',
                            helperText: 'Score mínimo para marcar como Alta.',
                          ),
                          keyboardType: TextInputType.number,
                          validator: _validateThreshold,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _mediaCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Umbral Media (≥)',
                            helperText: 'Score mínimo para marcar como Media.',
                          ),
                          keyboardType: TextInputType.number,
                          validator: _validateThreshold,
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          label: 'Guardar calibración',
                          icon: Icons.save,
                          isLoading: _saving,
                          onPressed: _saving ? null : _save,
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
