import '../entities/coverage_config.dart';

/// Contrato del repositorio de configuracion de cobertura.
abstract class CoverageConfigRepository {
  /// Stream en tiempo real de la configuracion de cobertura.
  Stream<CoverageConfig> watchCoverageConfig();

  /// Actualiza la configuracion de cobertura en Firestore.
  Future<void> updateCoverageConfig(CoverageConfig config);
}
