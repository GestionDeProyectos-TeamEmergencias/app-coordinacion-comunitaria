import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// Vértice del polígono de cobertura. Record puro (lat/lng) para mantener la
/// entidad de dominio libre de dependencias del plugin de mapas. La conversión
/// desde/hacia `LatLng` ocurre en la capa de UI/datos. [F-07]
typedef CoverageVertex = ({double lat, double lng});

/// Configuracion del area de cobertura del sistema.
/// Leida desde Firestore (config/coverage) con fallback a defaults.
class CoverageConfig extends Equatable {
  const CoverageConfig({
    required this.centerLat,
    required this.centerLng,
    required this.radiusMeters,
    this.polygonPoints,
  });

  final double centerLat;
  final double centerLng;
  final double radiusMeters;

  /// Polígono de cobertura opcional (RF-REP-01/RF-ADM-01: "polígono o radio").
  /// Si está presente y tiene al menos 3 vértices, la validación usa
  /// point-in-polygon en lugar del círculo. Si es null o tiene <3 vértices,
  /// se cae al modo círculo (retrocompatibilidad total). [F-07]
  final List<CoverageVertex>? polygonPoints;

  /// `true` si la configuración debe validarse por polígono (>= 3 vértices).
  bool get usesPolygon =>
      polygonPoints != null && polygonPoints!.length >= 3;

  /// Valores por defecto: Junin, BA (UNNOBA), 5000m.
  static const CoverageConfig defaults = CoverageConfig(
    centerLat: -34.5895,
    centerLng: -60.9442,
    radiusMeters: 5000,
  );

  /// Determina si las coordenadas dadas estan dentro del area de cobertura.
  /// Si hay un polígono válido (>= 3 vértices), usa point-in-polygon (ray
  /// casting); si no, usa la fórmula de Haversine sobre el círculo. [F-07]
  bool isWithinCoverage(double latitude, double longitude) {
    final poly = polygonPoints;
    if (poly != null && poly.length >= 3) {
      return pointInPolygon(latitude, longitude, poly);
    }
    final distance = haversineDistance(
      centerLat,
      centerLng,
      latitude,
      longitude,
    );
    return distance <= radiusMeters;
  }

  /// Algoritmo de point-in-polygon por ray casting (paridad de cruces de una
  /// semirrecta horizontal). Trata el borde (lados y vértices) como **dentro**,
  /// consistente con el criterio inclusivo (`<=`) del círculo. Asume el plano
  /// lat/lng como euclídeo, válido para áreas barriales. [F-07]
  static bool pointInPolygon(
    double lat,
    double lng,
    List<CoverageVertex> polygon,
  ) {
    final n = polygon.length;
    // x = longitud, y = latitud.
    final x = lng;
    final y = lat;
    var inside = false;
    for (var i = 0, j = n - 1; i < n; j = i++) {
      final xi = polygon[i].lng;
      final yi = polygon[i].lat;
      final xj = polygon[j].lng;
      final yj = polygon[j].lat;

      // Punto exactamente sobre un vértice → dentro.
      if (yi == y && xi == x) return true;

      // Punto sobre el lado (i, j) → dentro.
      if (_isOnSegment(x, y, xj, yj, xi, yi)) return true;

      final intersects = ((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
      if (intersects) inside = !inside;
    }
    return inside;
  }

  /// `true` si el punto (px, py) está sobre el segmento (a → b): colineal
  /// (producto cruzado ≈ 0) y dentro del bounding box del segmento.
  static bool _isOnSegment(
    double px,
    double py,
    double ax,
    double ay,
    double bx,
    double by,
  ) {
    const eps = 1e-12;
    final cross = (px - ax) * (by - ay) - (py - ay) * (bx - ax);
    if (cross.abs() > eps) return false;
    final withinX =
        px >= math.min(ax, bx) - eps && px <= math.max(ax, bx) + eps;
    final withinY =
        py >= math.min(ay, by) - eps && py <= math.max(ay, by) + eps;
    return withinX && withinY;
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
  List<Object?> get props =>
      [centerLat, centerLng, radiusMeters, polygonPoints];
}
