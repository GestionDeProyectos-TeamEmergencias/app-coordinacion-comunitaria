import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Obtiene un stream en tiempo real de usuarios activos. [T-AUTH-04]
class GetActiveUsersUseCase {
  const GetActiveUsersUseCase(this._repository);

  final AuthRepository _repository;

  Stream<List<AppUser>> call({UserRole? role}) =>
      _repository.activeUsersStream(role: role);
}
