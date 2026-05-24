import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Retorna un stream en tiempo real de los usuarios con estado "pendiente".
/// Usado por el Administrador Vecinal para monitorear nuevas solicitudes. [T-AUTH-01]
class GetPendingUsersUseCase {
  const GetPendingUsersUseCase(this._repository);

  final AuthRepository _repository;

  Stream<List<AppUser>> call() => _repository.pendingUsersStream;
}
