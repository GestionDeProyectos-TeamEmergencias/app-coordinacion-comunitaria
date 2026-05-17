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
}
