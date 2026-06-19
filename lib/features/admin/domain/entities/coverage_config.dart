import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// Configuracion del area de cobertura del sistema.
/// Leida desde Firestore (config/coverage) con fallback a defaults.
class CoverageConfig extends Equatable {
  const CoverageConfig({
    required this.centerLat,
    required this.centerLng,
    required this.radiusMeters,
  });

  final double centerLat;
  final double centerLng;
  final double radiusMeters;

  /// Valores por defecto: Junin, BA (UNNOBA), 5000m.
  static const CoverageConfig defaults = CoverageConfig(
    centerLat: -34.5895,
    centerLng: -60.9442,
    radiusMeters: 5000,
  );

  /// Determina si las coordenadas dadas estan dentro del area de cobertura
  /// usando la formula de Haversine para calcular la distancia geodesica.
  bool isWithinCoverage(double latitude, double longitude) {
    final distance = haversineDistance(
      centerLat,
      centerLng,
      latitude,
      longitude,
    );
    return distance <= radiusMeters;
  }

  /// Calcula la distancia geodesica en metros entre dos coordenadas
  /// usando la formula de Haversine.
  static double haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusMeters = 6371e3;
    final phi1 = _toRadians(lat1);
    final phi2 = _toRadians(lat2);
    final deltaPhi = _toRadians(lat2 - lat1);
    final deltaLambda = _toRadians(lon2 - lon1);

    final a = math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
        math.cos(phi1) *
            math.cos(phi2) *
            math.sin(deltaLambda / 2) *
            math.sin(deltaLambda / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusMeters * c;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;

  @override
  List<Object?> get props => [centerLat, centerLng, radiusMeters];
}
