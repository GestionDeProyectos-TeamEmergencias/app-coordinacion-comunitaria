import '../entities/app_user.dart';

abstract interface class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  Future<AppUser> register(
      {required String email,
      required String password,
      required String displayName});
  Future<AppUser> login({required String email, required String password});
  Future<void> logout();
  Future<AppUser?> getCurrentUser();

  // ── Gestión de usuarios pendientes (T-AUTH-01) ────────────────────────────

  /// Stream en tiempo real de usuarios con status "pending".
  Stream<List<AppUser>> get pendingUsersStream;

  /// Aprueba una cuenta: status → "active".
  Future<void> approveUser(String uid);

  /// Rechaza una cuenta: status → "rejected".
  Future<void> rejectUser(String uid);
}
