import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({
    required String email,
    required String password,
    required String displayName,
  }) =>
      _repository.register(
        email: email,
        password: password,
        displayName: displayName,
      );
}
