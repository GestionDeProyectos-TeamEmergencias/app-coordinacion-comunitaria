import '../entities/app_user.dart';

abstract interface class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  Future<AppUser> register({required String email, required String password, required String displayName});
  Future<AppUser> login({required String email, required String password});
  Future<void> logout();
  Future<AppUser?> getCurrentUser();
}
