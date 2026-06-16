import 'package:cloud_functions/cloud_functions.dart';

class ModerationRemoteService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<void> marcarReporteComoFalso({
    required String incidentId,
    required String userId,
  }) async {
    try {
      final callable = _functions.httpsCallable('moderateFalseReport');
      await callable.call<dynamic>({
        'incidentId': incidentId,
        'userId': userId,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Error de moderación: ${e.message} [${e.code}]');
    } catch (e) {
      throw Exception('Error interno de moderación: $e');
    }
  }

  // TODO: Migrar desbloqueo manual a Cloud Functions en el futuro si es necesario.
}
