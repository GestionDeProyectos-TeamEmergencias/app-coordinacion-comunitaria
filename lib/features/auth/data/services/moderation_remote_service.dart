import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/errors/app_exception.dart';

/// Cliente del Cloud Function de moderación. [T-AUTH-07]
class ModerationRemoteService {
  ModerationRemoteService([FirebaseFunctions? functions])
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Marca un incidente como reporte falso. Devuelve true si el usuario quedó
  /// bloqueado al superar el umbral.
  Future<ModerationResult> marcarReporteComoFalso({
    required String incidentId,
    required String userId,
  }) async {
    try {
      final callable = _functions.httpsCallable('moderateFalseReport');
      final result = await callable.call<Map<Object?, Object?>>({
        'incidentId': incidentId,
        'userId': userId,
      });
      final data = result.data;
      return ModerationResult(
        blocked: data['blocked'] == true,
        alreadyModerated: data['alreadyModerated'] == true,
      );
    } on FirebaseFunctionsException catch (e) {
      throw FirestoreException(_friendlyMessage(e));
    }
  }

  /// Desbloquea manualmente a un usuario. Solo invocable por administrador activo.
  Future<void> desbloquearUsuario({required String userId}) async {
    try {
      final callable = _functions.httpsCallable('unblockUser');
      await callable.call<Map<Object?, Object?>>({'userId': userId});
    } on FirebaseFunctionsException catch (e) {
      throw FirestoreException(_friendlyMessage(e));
    }
  }

  String _friendlyMessage(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'No tenés permisos para realizar esta acción.';
      case 'unauthenticated':
        return 'Tu sesión expiró. Volvé a iniciar sesión.';
      case 'not-found':
        return e.message ?? 'Recurso no encontrado.';
      case 'invalid-argument':
        return e.message ?? 'Datos inválidos.';
      default:
        return e.message ?? 'Error de moderación.';
    }
  }
}

/// Resultado de la moderación de un reporte como falso.
class ModerationResult {
  const ModerationResult({
    required this.blocked,
    required this.alreadyModerated,
  });

  final bool blocked;
  final bool alreadyModerated;
}
