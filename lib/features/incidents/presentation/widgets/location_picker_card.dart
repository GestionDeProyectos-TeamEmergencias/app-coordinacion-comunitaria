import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/config/coverage_area.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../admin/presentation/providers/coverage_config_provider.dart';
import '../providers/location_picker_provider.dart';

/// Mini-mapa para fijar la ubicación de un reporte. [F-03 / RF-REP-01]
///
/// Comportamiento:
/// - Al montar, pide al GPS la ubicación actual y centra el mapa en ella.
/// - El marker es **arrastrable** (long-press + drag).
/// - **Tap** en cualquier punto del mapa mueve el marker a ese punto.
/// - Botón "Mi ubicación" centra y resetea el marker al último GPS conocido.
/// - Badge "Fuera de cobertura" si la ubicación elegida cae afuera.
///
/// **Notas Web:** `google_maps_flutter` en Flutter Web tiene drag-and-drop
/// algo flaky en algunas combinaciones de browser/touch device. Como fallback
/// universal, el tap-to-place siempre funciona.
class LocationPickerCard extends ConsumerStatefulWidget {
  const LocationPickerCard({super.key});

  /// Hook para widget tests: cuando es `true`, el `GoogleMap` se reemplaza
  /// por un placeholder vacío. Necesario porque platform views no rendaerizan
  /// en `flutter test`. Solo se setea desde `setUpAll` de los tests. [F-03]
  @visibleForTesting
  static bool disableMapForTests = false;

  @override
  ConsumerState<LocationPickerCard> createState() => _LocationPickerCardState();
}

class _LocationPickerCardState extends ConsumerState<LocationPickerCard> {
  GoogleMapController? _controller;
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    // Disparamos la carga de GPS al construir. Si falla, el badge de error
    // queda visible pero el usuario puede fijar manualmente.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationPickerProvider.notifier).loadGps();
    });
  }

  Future<void> _animateTo(LatLng target) async {
    await _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: CoverageArea.initialZoom),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(locationPickerProvider);
    final coverage = ref.watch(coverageConfigProvider).valueOrNull;
    final isWithin = ref.watch(selectedLocationIsWithinCoverageProvider);

    // Cuando llega la primera lectura de GPS, centramos el mapa. Sólo la
    // primera vez para no pisar el pan del usuario.
    if (!_bootstrapped && state.selected != null) {
      _bootstrapped = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animateTo(state.selected!);
      });
    }

    final initialTarget = state.selected ?? CoverageArea.center;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 220,
            child: Stack(
              children: [
                if (LocationPickerCard.disableMapForTests)
                  const ColoredBox(color: Color(0xFFEEEEEE))
                else
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: initialTarget,
                      zoom: CoverageArea.initialZoom,
                    ),
                    onMapCreated: (c) => _controller = c,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    markers: state.selected == null
                        ? const {}
                        : {
                            Marker(
                              markerId: const MarkerId('report-location'),
                              position: state.selected!,
                              draggable: true,
                              onDragEnd: (newPos) => ref
                                  .read(locationPickerProvider.notifier)
                                  .setManual(newPos),
                            ),
                          },
                    // Con polígono configurado se dibuja el polígono; si no,
                    // el círculo. Coincide con lo que valida la cobertura. [F-07]
                    circles: (coverage == null || coverage.usesPolygon)
                        ? const {}
                        : {
                            Circle(
                              circleId: const CircleId('coverage-preview'),
                              center: LatLng(
                                coverage.centerLat,
                                coverage.centerLng,
                              ),
                              radius: coverage.radiusMeters,
                              strokeColor: AppColors.primary,
                              strokeWidth: 1,
                              fillColor:
                                  AppColors.primary.withValues(alpha: 0.05),
                            ),
                          },
                    polygons: (coverage != null && coverage.usesPolygon)
                        ? {
                            Polygon(
                              polygonId: const PolygonId('coverage-preview'),
                              points: coverage.polygonPoints!
                                  .map((p) => LatLng(p.lat, p.lng))
                                  .toList(),
                              strokeColor: AppColors.primary,
                              strokeWidth: 1,
                              fillColor:
                                  AppColors.primary.withValues(alpha: 0.05),
                            ),
                          }
                        : const {},
                    onTap: (latLng) => ref
                        .read(locationPickerProvider.notifier)
                        .setManual(latLng),
                  ),
                if (state.isLoadingGps)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x33000000),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.selected == null
                            ? 'Esperando GPS…'
                            : 'Ubicación elegida: '
                                '${state.selected!.latitude.toStringAsFixed(5)}, '
                                '${state.selected!.longitude.toStringAsFixed(5)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    if (isWithin == false)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: _OutOfCoverageChip(),
                      ),
                  ],
                ),
                if (state.gpsError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    state.gpsError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.my_location),
                        onPressed: state.isLoadingGps
                            ? null
                            : () async {
                                await ref
                                    .read(locationPickerProvider.notifier)
                                    .loadGps();
                                final newGps =
                                    ref.read(locationPickerProvider).gpsCurrent;
                                if (newGps != null) await _animateTo(newGps);
                              },
                        label: const Text('Mi ubicación'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.restart_alt),
                        onPressed: state.gpsCurrent == null
                            ? null
                            : () {
                                ref
                                    .read(locationPickerProvider.notifier)
                                    .resetToGps();
                                _animateTo(state.gpsCurrent!);
                              },
                        label: const Text('Volver al GPS'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutOfCoverageChip extends StatelessWidget {
  const _OutOfCoverageChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 14,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 4),
          Text(
            'Fuera de cobertura',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
