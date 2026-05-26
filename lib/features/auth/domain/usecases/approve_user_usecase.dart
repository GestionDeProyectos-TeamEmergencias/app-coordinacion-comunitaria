import '../repositories/auth_repository.dart';

/// Aprueba la cuenta de un usuario pendiente: cambia su status a "active".
/// Solo el Administrador Vecinal puede invocar esta acción. [T-AUTH-01]
class ApproveUserUseCase {
  const ApproveUserUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call(String uid) => _repository.approveUser(uid);
}
