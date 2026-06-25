import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_user.dart';

// Colección Firestore: 'users'
// Campos: userId, email, displayName, role, status, reputationScore,
//         coverageLat?, coverageLng?, coverageRadiusKm?, fcmTokens, createdAt
class UserModel {
  const UserModel({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.role,
    required this.status,
    required this.reputationScore,
    required this.falseReportsCount,
    this.coverageLat,
    this.coverageLng,
    this.coverageRadiusKm,
    this.identityProofUrl,
    this.fcmTokens = const [],
    this.termsAcceptedVersion,
    this.termsAcceptedAt,
  });

  final String userId;
  final String email;
  final String displayName;
  final String role;
  final String status;
  final double reputationScore;
  final int falseReportsCount;
  final double? coverageLat;
  final double? coverageLng;
  final double? coverageRadiusKm;
  // URL de descarga del comprobante de servicio cuando la modalidad de
  // verificación es "proof_upload". El doc del usuario solo es leído por el
  // propio dueño y por administradores (reglas Firestore). Nota: la URL en sí
  // contiene un download token de Firebase Storage; cualquiera que la conozca
  // puede descargar el archivo, por eso es crítico que las reglas de Firestore
  // no expongan el campo a otros usuarios. [T-AUTH-09]
  final String? identityProofUrl;
  // Tokens FCM del usuario. Un usuario puede tener múltiples dispositivos
  // logueados (web + mobile, varios celulares). El backend (T-NLP-07 /
  // T-NLP-09) hace multicast a todos los tokens. [D-01]
  final List<String> fcmTokens;
  // Versión de los T&C aceptados (compara contra `TermsConfig.currentVersion`).
  // Null → nunca aceptó; el router redirige al gate. [D-04]
  final int? termsAcceptedVersion;
  final DateTime? termsAcceptedAt;

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      userId: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      role: data['role'] as String? ?? 'vecino_informante',
      status: data['status'] as String? ?? 'pending',
      reputationScore: (data['reputationScore'] as num?)?.toDouble() ?? 100.0,
      falseReportsCount: data['falseReportsCount'] as int? ?? 0,
      coverageLat: (data['coverageLat'] as num?)?.toDouble(),
      coverageLng: (data['coverageLng'] as num?)?.toDouble(),
      coverageRadiusKm: (data['coverageRadiusKm'] as num?)?.toDouble(),
      identityProofUrl: data['identityProofUrl'] as String?,
      fcmTokens: (data['fcmTokens'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      termsAcceptedVersion: (data['termsAcceptedVersion'] as num?)?.toInt(),
      termsAcceptedAt: (data['termsAcceptedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'displayName': displayName,
        'role': role,
        'status': status,
        'reputationScore': reputationScore,
        'falseReportsCount': falseReportsCount,
        if (coverageLat != null) 'coverageLat': coverageLat,
        if (coverageLng != null) 'coverageLng': coverageLng,
        if (coverageRadiusKm != null) 'coverageRadiusKm': coverageRadiusKm,
        if (identityProofUrl != null) 'identityProofUrl': identityProofUrl,
        'fcmTokens': fcmTokens,
      };

  AppUser toDomain() => AppUser(
        userId: userId,
        email: email,
        displayName: displayName,
        role: UserRole.fromString(role),
        status: UserStatus.fromString(status),
        reputationScore: reputationScore,
        falseReportsCount: falseReportsCount,
        coverageAreaCenter: (coverageLat != null && coverageLng != null)
            ? (latitude: coverageLat!, longitude: coverageLng!)
            : null,
        coverageRadiusKm: coverageRadiusKm,
        identityProofUrl: identityProofUrl,
        fcmTokens: fcmTokens,
        termsAcceptedVersion: termsAcceptedVersion,
        termsAcceptedAt: termsAcceptedAt,
      );
}
