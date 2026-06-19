import 'package:equatable/equatable.dart';

/// Modalidad activa de verificación de identidad del vecino. [T-AUTH-09]
///
/// - [manual]: el administrador aprueba/rechaza la cuenta sin documentación
///   adicional. Es el flujo histórico de T-AUTH-01.
/// - [proofUpload]: el vecino debe adjuntar un comprobante de servicio (foto)
///   antes de que el administrador pueda aprobar la cuenta. La foto se almacena
///   en Firebase Storage y su URL queda en el documento `users/{uid}`.
///
/// La modalidad 3 (integración Truora/IDenfy) está documentada como extensión
/// futura — la `firestoreValue` `external` queda reservada pero no implementada.
enum IdentityVerificationMode {
  manual,
  proofUpload;

  static IdentityVerificationMode fromString(String value) => switch (value) {
        'manual' => IdentityVerificationMode.manual,
        'proof_upload' => IdentityVerificationMode.proofUpload,
        _ => IdentityVerificationMode.manual,
      };

  String get firestoreValue => switch (this) {
        IdentityVerificationMode.manual => 'manual',
        IdentityVerificationMode.proofUpload => 'proof_upload',
      };

  String get displayName => switch (this) {
        IdentityVerificationMode.manual =>
          'Aprobación manual sin documentación',
        IdentityVerificationMode.proofUpload =>
          'Comprobante de servicio (foto)',
      };

  bool get requiresProof => this == IdentityVerificationMode.proofUpload;
}

class IdentityVerificationConfig extends Equatable {
  const IdentityVerificationConfig({required this.mode});

  final IdentityVerificationMode mode;

  /// Valor por defecto: modalidad manual (compatibilidad con T-AUTH-01).
  static const IdentityVerificationConfig defaults =
      IdentityVerificationConfig(mode: IdentityVerificationMode.manual);

  IdentityVerificationConfig copyWith({IdentityVerificationMode? mode}) =>
      IdentityVerificationConfig(mode: mode ?? this.mode);

  @override
  List<Object?> get props => [mode];
}
