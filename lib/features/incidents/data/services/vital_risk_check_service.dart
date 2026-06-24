import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/errors/app_exception.dart';

/// Resultado del chequeo de riesgo vital antes de crear el incident. [D-03]
class VitalRiskCheckResult {
  const VitalRiskCheckResult({
    required this.isVitalRisk,
    required this.matchedTerms,
    required this.riskCategory,
    required this.emergencyNumbers,
    required this.reason,
  });

  final bool isVitalRisk;
  final List<String> matchedTerms;
  final String riskCategory; // 'medico' | 'seguridad' | 'desastre' | 'none'
  final List<String> emergencyNumbers;
  final String reason;
}

/// Llama al callable `checkVitalRiskCallable` para evaluar si la descripción
/// de un reporte dispara la derivación a servicios de emergencia. [D-03]
///
/// Si el servicio falla (red, función no disponible), el flujo NO debe bloquear
/// el envío del reporte — devolvemos `isVitalRisk: false` y dejamos que el
/// pipeline backend haga su check defensivo. Es una decisión de UX: preferimos
/// dejar pasar un falso negativo (el incident se crea y el detalle muestra el
/// aviso) antes que bloquear reportes legítimos por un problema de red.
class VitalRiskCheckService {
  VitalRiskCheckService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<VitalRiskCheckResult> check(String description) async {
    try {
      final callable = _functions.httpsCallable('checkVitalRiskCallable');
      final response = await callable.call<Map<String, dynamic>>({
        'description': description,
      });
      final data = response.data;
      return VitalRiskCheckResult(
        isVitalRisk: data['isVitalRisk'] as bool? ?? false,
        matchedTerms: (data['matchedTerms'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(),
        riskCategory: data['riskCategory'] as String? ?? 'none',
        emergencyNumbers:
            (data['emergencyNumbers'] as List<dynamic>? ?? const [])
                .whereType<String>()
                .toList(),
        reason: data['reason'] as String? ?? '',
      );
    } on FirebaseFunctionsException catch (e) {
      // Errores de auth o argumento son bugs del cliente: propagar para que se
      // vean en logs. La red caída se trata como "sin riesgo" para no bloquear.
      if (e.code == 'unauthenticated' || e.code == 'invalid-argument') {
        throw NetworkException('checkVitalRisk: ${e.message ?? e.code}');
      }
      return const VitalRiskCheckResult(
        isVitalRisk: false,
        matchedTerms: [],
        riskCategory: 'none',
        emergencyNumbers: [],
        reason: 'check skipped due to network error',
      );
    }
  }
}
