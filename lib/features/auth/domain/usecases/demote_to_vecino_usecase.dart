import '../repositories/auth_repository.dart';

/// Degrada un referente barrial al rol de vecino informante. [T-AUTH-04]
class DemoteToVecinoUseCase {
  const DemoteToVecinoUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call(String uid) => _repository.demoteToVecino(uid);
}
