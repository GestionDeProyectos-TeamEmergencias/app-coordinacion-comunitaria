import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../admin/domain/entities/coverage_config.dart';
import '../providers/coverage_config_provider.dart';

class CoverageConfigPage extends ConsumerStatefulWidget {
  const CoverageConfigPage({super.key});

  @override
  ConsumerState<CoverageConfigPage> createState() => _CoverageConfigPageState();
}

class _CoverageConfigPageState extends ConsumerState<CoverageConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _radiusCtrl = TextEditingController();

  GoogleMapController? _mapController;
  LatLng? _currentCenter;
  double? _currentRadius;

  @override
  void dispose() {
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _radiusCtrl.dispose();
    super.dispose();
  }

  void _updateMapFromFields() {
    final lat = double.tryParse(_latCtrl.text);
    final lng = double.tryParse(_lngCtrl.text);
    final radius = double.tryParse(_radiusCtrl.text);
    if (lat != null && lng != null && radius != null) {
      setState(() {
        _currentCenter = LatLng(lat, lng);
        _currentRadius = radius;
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_currentCenter!),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final lat = double.parse(_latCtrl.text);
    final lng = double.parse(_lngCtrl.text);
    final radius = double.parse(_radiusCtrl.text);

    final config = CoverageConfig(
      centerLat: lat,
      centerLng: lng,
      radiusMeters: radius,
    );

    await ref.read(updateCoverageNotifierProvider.notifier).updateConfig(config);
    
    if (!mounted) return;
    final error = ref.read(updateCoverageNotifierProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración actualizada exitosamente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(coverageConfigProvider);
    final isSubmitting = ref.watch(updateCoverageNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.coverageConfig)),
      body: configAsync.when(
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (config) {
          // Initialize controllers only once
          if (_latCtrl.text.isEmpty) {
            _latCtrl.text = config.centerLat.toString();
            _lngCtrl.text = config.centerLng.toString();
            _radiusCtrl.text = config.radiusMeters.toString();
            _currentCenter = LatLng(config.centerLat, config.centerLng);
            _currentRadius = config.radiusMeters;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    AppStrings.coverageConfigSubtitle,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latCtrl,
                          decoration: const InputDecoration(labelText: 'Latitud'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          onChanged: (_) => _updateMapFromFields(),
                          validator: (v) => (v == null || double.tryParse(v) == null) ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _lngCtrl,
                          decoration: const InputDecoration(labelText: 'Longitud'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          onChanged: (_) => _updateMapFromFields(),
                          validator: (v) => (v == null || double.tryParse(v) == null) ? 'Requerido' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _radiusCtrl,
                    decoration: const InputDecoration(labelText: 'Radio (metros)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _updateMapFromFields(),
                    validator: (v) => (v == null || double.tryParse(v) == null) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  if (_currentCenter != null && _currentRadius != null)
                    SizedBox(
                      height: 300,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _currentCenter!,
                            zoom: 12,
                          ),
                          onMapCreated: (c) => _mapController = c,
                          circles: {
                            Circle(
                              circleId: const CircleId('coverage'),
                              center: _currentCenter!,
                              radius: _currentRadius!,
                              fillColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              strokeColor: Theme.of(context).colorScheme.primary,
                              strokeWidth: 2,
                            ),
                          },
                          onTap: (latLng) {
                            _latCtrl.text = latLng.latitude.toString();
                            _lngCtrl.text = latLng.longitude.toString();
                            _updateMapFromFields();
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Guardar Configuración',
                    onPressed: isSubmitting ? null : _submit,
                    isLoading: isSubmitting,
                    icon: Icons.save,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
