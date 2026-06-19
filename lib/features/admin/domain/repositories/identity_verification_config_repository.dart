import '../entities/identity_verification_config.dart';

/// Contrato del repositorio de configuración de verificación de identidad. [T-AUTH-09]
abstract class IdentityVerificationConfigRepository {
  Stream<IdentityVerificationConfig> watchConfig();
  Future<void> updateConfig(IdentityVerificationConfig config);
}
