import 'package:equatable/equatable.dart';

enum UserRole {
  vecinoInformante,
  referenteBarrial,
  administrador;

  static UserRole fromString(String value) => switch (value) {
        'vecino_informante' => UserRole.vecinoInformante,
        'referente_barrial' => UserRole.referenteBarrial,
        'administrador' => UserRole.administrador,
        _ => UserRole.vecinoInformante,
      };

  String get firestoreValue => switch (this) {
        UserRole.vecinoInformante => 'vecino_informante',
        UserRole.referenteBarrial => 'referente_barrial',
        UserRole.administrador => 'administrador',
      };

  bool get canReport => true;
  bool get canVerify => this == referenteBarrial || this == administrador;
  bool get canAdminister => this == administrador;
}

enum UserStatus {
  pending,
  active,
  blocked,
  // Cuenta rechazada por el Administrador Vecinal. [T-AUTH-01]
  rejected;

  static UserStatus fromString(String value) => switch (value) {
        'active' => UserStatus.active,
        'blocked' => UserStatus.blocked,
        'rejected' => UserStatus.rejected,
        _ => UserStatus.pending,
      };
}

class AppUser extends Equatable {
  const AppUser({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.role,
    required this.status,
    this.reputationScore = 100.0,
    this.falseReportsCount = 0,
    this.coverageAreaCenter,
    this.coverageRadiusKm,
    this.identityProofUrl,
    this.fcmTokens = const [],
  });

  final String userId;
  final String email;
  final String displayName;
  final UserRole role;
  final UserStatus status;
  final double reputationScore;
  final int falseReportsCount;
  // Posición central del área de cobertura (Firestore GeoPoint se mapea a lat/lng)
  final ({double latitude, double longitude})? coverageAreaCenter;
  final double? coverageRadiusKm;
  // URL del comprobante de servicio para verificación de identidad. [T-AUTH-09]
  final String? identityProofUrl;
  // Tokens FCM registrados por este usuario. Múltiples dispositivos posibles. [D-01]
  final List<String> fcmTokens;

  bool get isActive => status == UserStatus.active;
  bool get isPending => status == UserStatus.pending;
  bool get isBlocked => status == UserStatus.blocked;
  bool get isRejected => status == UserStatus.rejected;

  AppUser copyWith({
    String? userId,
    String? email,
    String? displayName,
    UserRole? role,
    UserStatus? status,
    double? reputationScore,
    int? falseReportsCount,
    ({double latitude, double longitude})? coverageAreaCenter,
    double? coverageRadiusKm,
    String? identityProofUrl,
    List<String>? fcmTokens,
  }) {
    return AppUser(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      status: status ?? this.status,
      reputationScore: reputationScore ?? this.reputationScore,
      falseReportsCount: falseReportsCount ?? this.falseReportsCount,
      coverageAreaCenter: coverageAreaCenter ?? this.coverageAreaCenter,
      coverageRadiusKm: coverageRadiusKm ?? this.coverageRadiusKm,
      identityProofUrl: identityProofUrl ?? this.identityProofUrl,
      fcmTokens: fcmTokens ?? this.fcmTokens,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        email,
        displayName,
        role,
        status,
        reputationScore,
        falseReportsCount,
        coverageAreaCenter,
        coverageRadiusKm,
        identityProofUrl,
        fcmTokens,
      ];
}
