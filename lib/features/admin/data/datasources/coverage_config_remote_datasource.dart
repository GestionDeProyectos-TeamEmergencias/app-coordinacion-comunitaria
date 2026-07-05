import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/coverage_config.dart';

class CoverageConfigRemoteDataSource {
  CoverageConfigRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  // Documento centralizado de configuracion de cobertura.
  DocumentReference<Map<String, dynamic>> get _docRef =>
      _firestore.collection('config').doc('coverage');

  Stream<CoverageConfig> watchCoverageConfig() {
    return _docRef.snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return CoverageConfig.defaults;
      }
      final data = snapshot.data()!;
      return CoverageConfig(
        centerLat: (data['centerLat'] as num?)?.toDouble() ??
            CoverageConfig.defaults.centerLat,
        centerLng: (data['centerLng'] as num?)?.toDouble() ??
            CoverageConfig.defaults.centerLng,
        radiusMeters: (data['radiusMeters'] as num?)?.toDouble() ??
            CoverageConfig.defaults.radiusMeters,
        polygonPoints: _polygonFromData(data['polygonPoints']),
      );
    });
  }

  Future<void> updateCoverageConfig(CoverageConfig config) async {
    final polygon = config.polygonPoints;
    final hasPolygon = polygon != null && polygon.length >= 3;
    await _docRef.set({
      'centerLat': config.centerLat,
      'centerLng': config.centerLng,
      'radiusMeters': config.radiusMeters,
      // Persistimos el polígono solo si es válido; si se "limpió" (vuelta a
      // círculo) lo borramos del doc para que la lectura caiga a círculo. [F-07]
      if (hasPolygon)
        'polygonPoints':
            polygon.map((p) => {'lat': p.lat, 'lng': p.lng}).toList()
      else
        'polygonPoints': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Parsea `polygonPoints` de Firestore a la lista de vértices del dominio.
  /// Tolerante: ignora entradas inválidas y devuelve null si quedan <3 puntos
  /// (cae a círculo, retrocompatibilidad). [F-07]
  static List<CoverageVertex>? _polygonFromData(dynamic raw) {
    if (raw is! List) return null;
    final points = <CoverageVertex>[];
    for (final item in raw) {
      if (item is Map) {
        final lat = (item['lat'] as num?)?.toDouble();
        final lng = (item['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          points.add((lat: lat, lng: lng));
        }
      }
    }
    return points.length >= 3 ? points : null;
  }
}
