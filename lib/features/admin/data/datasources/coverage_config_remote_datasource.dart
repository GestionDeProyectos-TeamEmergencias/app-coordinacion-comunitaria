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
      );
    });
  }

  Future<void> updateCoverageConfig(CoverageConfig config) async {
    await _docRef.set({
      'centerLat': config.centerLat,
      'centerLng': config.centerLng,
      'radiusMeters': config.radiusMeters,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
