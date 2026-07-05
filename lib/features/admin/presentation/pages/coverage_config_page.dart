import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
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

  // Edición de polígono de cobertura. [F-07]
  bool _polygonMode = false;
  final List<LatLng> _polygonPoints = [];

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

  // ── Edición de polígono [F-07] ──────────────────────────────────────────

  void _togglePolygonMode() {
    setState(() => _polygonMode = !_polygonMode);
  }

  void _clearPolygon() {
    setState(() {
      _polygonPoints.clear();
      _polygonMode = false;
    });
  }

  void _addVertex(LatLng point) {
    setState(() => _polygonPoints.add(point));
  }

  void _moveVertex(int index, LatLng point) {
    setState(() => _polygonPoints[index] = point);
  }

  /// Borra el vértice más cercano al punto donde se mantuvo presionado el mapa.
  /// Distancia euclídea en grados: suficiente para áreas barriales. [F-07]
  void _removeNearestVertex(LatLng point) {
    if (_polygonPoints.isEmpty) return;
    var nearest = 0;
    var best = double.infinity;
    for (var i = 0; i < _polygonPoints.length; i++) {
      final dLat = _polygonPoints[i].latitude - point.latitude;
      final dLng = _polygonPoints[i].longitude - point.longitude;
      final d = dLat * dLat + dLng * dLng;
      if (d < best) {
        best = d;
        nearest = i;
      }
    }
    setState(() => _polygonPoints.removeAt(nearest));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Si está en modo polígono pero no hay suficientes vértices, no aplica.
    if (_polygonMode && _polygonPoints.length < 3) {
      context.showSnackBar(AppStrings.coveragePolygonTooFew, isError: true);
      return;
    }

    // En modo polígono los campos del círculo no están en el árbol (no se
    // validan), así que parseamos de forma tolerante con respaldo al estado
    // actual / defaults para no romper el guardado. [F-07]
    final lat = double.tryParse(_latCtrl.text) ??
        _currentCenter?.latitude ??
        CoverageConfig.defaults.centerLat;
    final lng = double.tryParse(_lngCtrl.text) ??
        _currentCenter?.longitude ??
        CoverageConfig.defaults.centerLng;
    final radius = double.tryParse(_radiusCtrl.text) ??
        _currentRadius ??
        CoverageConfig.defaults.radiusMeters;

    final config = CoverageConfig(
      centerLat: lat,
      centerLng: lng,
      radiusMeters: radius,
      polygonPoints: (_polygonMode && _polygonPoints.length >= 3)
          ? _polygonPoints
              .map((p) => (lat: p.latitude, lng: p.longitude))
              .toList()
          : null,
    );

    await ref
        .read(updateCoverageNotifierProvider.notifier)
        .updateConfig(config);

    if (!mounted) return;
    final error = ref.read(updateCoverageNotifierProvider).error;
    if (error != null) {
      // Usa el mensaje user-friendly de AppException si está disponible.
      context.showSnackBar(error.toString(), isError: true);
    } else {
      context.showSnackBar(AppStrings.coverageConfigUpdated);
    }
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
    if (n > 1000000) return AppStrings.radiusTooLarge;
    return null;
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
            // Cargar polígono persistido (si existe) y entrar en modo polígono.
            // [F-07]
            if (config.usesPolygon) {
              _polygonMode = true;
              _polygonPoints
                ..clear()
                ..addAll(
                  config.polygonPoints!.map((p) => LatLng(p.lat, p.lng)),
                );
            }
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
                  // Parámetros del círculo: solo visibles en modo círculo. En
                  // modo polígono se ocultan (no se usan para validar; quedan
                  // como respaldo). Los controllers conservan sus valores. [F-07]
                  if (!_polygonMode) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Latitud'),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true, signed: true),
                            onChanged: (_) => _updateMapFromFields(),
                            validator: _validateLat,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _lngCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Longitud'),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true, signed: true),
                            onChanged: (_) => _updateMapFromFields(),
                            validator: _validateLng,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _radiusCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Radio (metros)'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _updateMapFromFields(),
                      validator: _validateRadius,
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Controles de modo polígono. [F-07]
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(_polygonMode
                              ? Icons.radio_button_unchecked
                              : Icons.pentagon_outlined),
                          label: Text(_polygonMode
                              ? AppStrings.coveragePolygonCircleMode
                              : AppStrings.coveragePolygonEdit),
                          onPressed: isSubmitting ? null : _togglePolygonMode,
                        ),
                      ),
                      if (_polygonMode) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.delete_outline),
                            label: const Text(AppStrings.coveragePolygonClear),
                            onPressed: isSubmitting ? null : _clearPolygon,
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_polygonMode) ...[
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.coveragePolygonTapHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            AppStrings.coveragePolygonFallbackNote,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
                          // En modo círculo se dibuja el círculo; en modo
                          // polígono, el polígono cuando hay >=3 vértices.
                          circles: _polygonMode
                              ? const {}
                              : {
                                  Circle(
                                    circleId: const CircleId('coverage'),
                                    center: _currentCenter!,
                                    radius: _currentRadius!,
                                    fillColor: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.1),
                                    strokeColor:
                                        Theme.of(context).colorScheme.primary,
                                    strokeWidth: 2,
                                  ),
                                },
                          polygons: (_polygonMode && _polygonPoints.length >= 3)
                              ? {
                                  Polygon(
                                    polygonId: const PolygonId('coverage'),
                                    points: _polygonPoints,
                                    fillColor: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.1),
                                    strokeColor:
                                        Theme.of(context).colorScheme.primary,
                                    strokeWidth: 2,
                                  ),
                                }
                              : const {},
                          markers: _polygonMode
                              ? {
                                  for (var i = 0;
                                      i < _polygonPoints.length;
                                      i++)
                                    Marker(
                                      markerId: MarkerId('vertex-$i'),
                                      position: _polygonPoints[i],
                                      draggable: true,
                                      onDragEnd: (pos) => _moveVertex(i, pos),
                                    ),
                                }
                              : const {},
                          onTap: (latLng) {
                            if (_polygonMode) {
                              _addVertex(latLng);
                              return;
                            }
                            _latCtrl.text = latLng.latitude.toString();
                            _lngCtrl.text = latLng.longitude.toString();
                            _updateMapFromFields();
                          },
                          onLongPress: (latLng) {
                            if (_polygonMode) _removeNearestVertex(latLng);
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
