import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_user.dart';

// Colección Firestore: 'users'
// Campos: userId, email, displayName, role, status, reputationScore,
//         coverageLat?, coverageLng?, coverageRadiusKm?, createdAt
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

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      userId: doc.id,
      email: data['email'] as String,
      displayName: data['displayName'] as String,
      role: data['role'] as String? ?? 'vecino_informante',
      status: data['status'] as String? ?? 'pending',
      reputationScore: (data['reputationScore'] as num?)?.toDouble() ?? 100.0,
      falseReportsCount: data['falseReportsCount'] as int? ?? 0,
      coverageLat: (data['coverageLat'] as num?)?.toDouble(),
      coverageLng: (data['coverageLng'] as num?)?.toDouble(),
      coverageRadiusKm: (data['coverageRadiusKm'] as num?)?.toDouble(),
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
      );
}
