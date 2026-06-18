import 'package:google_maps_flutter/google_maps_flutter.dart';

// Área de cobertura de la organización adoptante.
// Valores por defecto hasta que T-AUTH-06 los lea desde Firestore.
abstract final class CoverageArea {
  static const LatLng center = LatLng(-34.5895, -60.9442); // Junín, BA (UNNOBA)
  static const double radiusMeters = 5000;
  static const double initialZoom = 13;
}
