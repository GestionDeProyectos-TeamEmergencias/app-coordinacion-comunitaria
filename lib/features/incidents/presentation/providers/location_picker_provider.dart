import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../admin/presentation/providers/coverage_config_provider.dart';

/// Estado del selector de ubicación del reporte. [F-03 / RF-REP-01]
class LocationPickerState {
  const LocationPickerState({
    this.selected,
    this.gpsCurrent,
    this.isLoadingGps = false,
    this.gpsError,
  });

  /// Ubicación que el usuario eligió (default = GPS actual cuando carga).
  /// `null` mientras se está cargando el GPS por primera vez.
  final LatLng? selected;

  /// Última lectura del GPS — referencia para el botón "Volver a mi ubicación".
  final LatLng? gpsCurrent;

  final bool isLoadingGps;

  /// Mensaje de error si la carga del GPS falló. Solo informativo: el usuario
  /// puede igualmente fijar manualmente.
  final String? gpsError;

  LocationPickerState copyWith({
    LatLng? selected,
    LatLng? gpsCurrent,
    bool? isLoadingGps,
    Object? gpsError = _sentinel,
  }) {
    return LocationPickerState(
      selected: selected ?? this.selected,
      gpsCurrent: gpsCurrent ?? this.gpsCurrent,
      isLoadingGps: isLoadingGps ?? this.isLoadingGps,
      gpsError:
          identical(gpsError, _sentinel) ? this.gpsError : gpsError as String?,
    );
  }

  static const _sentinel = Object();
}

/// Adapter inyectable de GPS para que los tests no dependan del plugin real.
typedef GpsFetcher = Future<LatLng> Function();

Future<LatLng> _realGpsFetcher() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw const _LocationError('El GPS está desactivado.');
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw const _LocationError('Permiso de ubicación denegado.');
  }
  final pos = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.medium,
      timeLimit: Duration(seconds: 5),
    ),
  );
  return LatLng(pos.latitude, pos.longitude);
}

/// Provider del GPS — sobrecargable en tests con `overrideWithValue`. [F-03]
final gpsFetcherProvider = Provider<GpsFetcher>((_) => _realGpsFetcher);

class LocationPickerNotifier extends StateNotifier<LocationPickerState> {
  LocationPickerNotifier(this._ref) : super(const LocationPickerState());

  final Ref _ref;

  /// Pide al GPS la ubicación actual y la fija como `selected` + `gpsCurrent`.
  /// Si falla, marca `gpsError` pero deja al usuario fijar manualmente. [F-03]
  Future<void> loadGps() async {
    state = state.copyWith(isLoadingGps: true, gpsError: null);
    try {
      final pos = await _ref.read(gpsFetcherProvider)();
      state = LocationPickerState(
        selected: pos,
        gpsCurrent: pos,
        isLoadingGps: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingGps: false,
        gpsError: e is _LocationError
            ? e.message
            : 'No se pudo obtener tu ubicación.',
      );
    }
  }

  /// Fija manualmente la ubicación (tap o drag del marker). NO toca el GPS de
  /// referencia. [F-03]
  void setManual(LatLng position) {
    state = state.copyWith(selected: position);
  }

  /// Devuelve la selección al GPS de referencia. Si nunca cargó el GPS, no
  /// hace nada. [F-03]
  void resetToGps() {
    final gps = state.gpsCurrent;
    if (gps == null) return;
    state = state.copyWith(selected: gps);
  }
}

final locationPickerProvider = StateNotifierProvider.autoDispose<
    LocationPickerNotifier, LocationPickerState>(
  (ref) => LocationPickerNotifier(ref),
);

/// Estado derivado: ¿la ubicación seleccionada está dentro de cobertura?
/// Null si todavía no hay selección o si la config de cobertura no cargó. [F-03]
final selectedLocationIsWithinCoverageProvider =
    Provider.autoDispose<bool?>((ref) {
  final selected = ref.watch(locationPickerProvider).selected;
  final config = ref.watch(coverageConfigProvider).valueOrNull;
  if (selected == null || config == null) return null;
  return config.isWithinCoverage(selected.latitude, selected.longitude);
});

class _LocationError implements Exception {
  const _LocationError(this.message);
  final String message;
}
