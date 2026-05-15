sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

final class AuthException extends AppException {
  const AuthException(super.message);
}

final class PermissionDeniedException extends AppException {
  const PermissionDeniedException([super.message = 'Permiso denegado.']);
}

final class OutOfCoverageException extends AppException {
  const OutOfCoverageException()
      : super('Tu ubicación está fuera del área de cobertura.');
}

final class VitalRiskDetectedException extends AppException {
  const VitalRiskDetectedException()
      : super('Riesgo vital detectado. Contactá al 911 o 107.');
}

final class NetworkException extends AppException {
  const NetworkException([super.message = 'Error de red. Verificá tu conexión.']);
}

final class FirestoreException extends AppException {
  const FirestoreException(super.message);
}

final class StorageException extends AppException {
  const StorageException(super.message);
}
