import '../repositories/auth_repository.dart';

/// Bloquea la cuenta de un usuario: cambia su status a "blocked".
/// Solo el Administrador Vecinal puede invocar esta acción. [T-AUTH-08]
class BlockUserUseCase {
  const BlockUserUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call(String uid) => _repository.blockUser(uid);
}
