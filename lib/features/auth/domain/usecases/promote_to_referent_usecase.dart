import '../repositories/auth_repository.dart';

/// Promueve un vecino informante al rol de referente barrial. [T-AUTH-04]
/// RF-ROL-02: solo el Administrador Vecinal puede invocar esta acción.
class PromoteToReferentUseCase {
  const PromoteToReferentUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call(String uid) => _repository.promoteToReferent(uid);
}
