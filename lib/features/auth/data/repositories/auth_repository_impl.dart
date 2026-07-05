import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._dataSource);

  final AuthRemoteDataSource _dataSource;

  @override
  Stream<AppUser?> get authStateChanges =>
      _dataSource.authStateChanges.map((model) => model?.toDomain());

  @override
  Future<AppUser> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final model = await _dataSource.register(
      email: email,
      password: password,
      displayName: displayName,
    );
    return model.toDomain();
  }

  @override
  Future<AppUser> login(
      {required String email, required String password}) async {
    final model = await _dataSource.login(email: email, password: password);
    return model.toDomain();
  }

  @override
  Future<void> logout() => _dataSource.logout();

  @override
  Future<AppUser?> getCurrentUser() async {
    final model = await _dataSource.getCurrentUser();
    return model?.toDomain();
  }

  @override
  Future<void> resetPassword({required String email}) =>
      _dataSource.resetPassword(email: email);
  // ── Gestión de usuarios pendientes (T-AUTH-01) ────────────────────────────

  @override
  Stream<List<AppUser>> get pendingUsersStream => _dataSource.pendingUsersStream
      .map((models) => models.map((m) => m.toDomain()).toList());

  @override
  Future<void> approveUser(String uid) => _dataSource.approveUser(uid);

  @override
  Future<void> rejectUser(String uid) => _dataSource.rejectUser(uid);

  // ── Gestión de roles (T-AUTH-04) ──────────────────────────────────────────

  @override
  Stream<List<AppUser>> activeUsersStream({UserRole? role}) => _dataSource
      .activeUsersStream(role: role?.firestoreValue)
      .map((models) => models.map((m) => m.toDomain()).toList());

  @override
  Future<void> promoteToReferent(String uid) =>
      _dataSource.promoteToReferent(uid);

  @override
  Future<void> demoteToVecino(String uid) => _dataSource.demoteToVecino(uid);

  @override
  Stream<List<AppUser>> get blockedUsersStream => _dataSource
      .blockedUsersStream()
      .map((models) => models.map((m) => m.toDomain()).toList());

  @override
  Future<void> blockUser(String uid) => _dataSource.blockUser(uid);
}
