import '../repositories/auth_repository.dart';

/// Rechaza la solicitud de un usuario pendiente: cambia su status a "rejected".
/// Solo el Administrador Vecinal puede invocar esta acción. [T-AUTH-01]
class RejectUserUseCase {
  const RejectUserUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call(String uid) => _repository.rejectUser(uid);
}
