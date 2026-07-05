import 'package:app_coordinacion_comunitaria/core/errors/app_exception.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/data/services/vital_risk_check_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFunctions extends Mock implements FirebaseFunctions {}

class _MockCallable extends Mock implements HttpsCallable {}

class _MockResult extends Mock
    implements HttpsCallableResult<Map<String, dynamic>> {}

void main() {
  late _MockFunctions functions;
  late _MockCallable callable;
  late VitalRiskCheckService service;

  setUp(() {
    functions = _MockFunctions();
    callable = _MockCallable();
    when(() => functions.httpsCallable('checkVitalRiskCallable'))
        .thenReturn(callable);
    service = VitalRiskCheckService(functions: functions);
  });

  test('parsea respuesta positiva del callable', () async {
    final result = _MockResult();
    when(() => result.data).thenReturn(<String, dynamic>{
      'isVitalRisk': true,
      'matchedTerms': ['electrocutado'],
      'riskCategory': 'medico',
      'emergencyNumbers': ['911', '107'],
      'reason': 'Riesgo vital detectado (medico).',
    });
    when(() => callable.call<Map<String, dynamic>>(any<Map<String, dynamic>>()))
        .thenAnswer((_) async => result);

    final parsed = await service.check('hay una persona electrocutada');

    expect(parsed.isVitalRisk, isTrue);
    expect(parsed.matchedTerms, ['electrocutado']);
    expect(parsed.riskCategory, 'medico');
    expect(parsed.emergencyNumbers, ['911', '107']);
  });

  test('parsea respuesta negativa', () async {
    final result = _MockResult();
    when(() => result.data).thenReturn(<String, dynamic>{
      'isVitalRisk': false,
      'matchedTerms': <String>[],
      'riskCategory': 'none',
      'emergencyNumbers': <String>[],
      'reason': 'No se detectaron términos.',
    });
    when(() => callable.call<Map<String, dynamic>>(any<Map<String, dynamic>>()))
        .thenAnswer((_) async => result);

    final parsed = await service.check('un bache en la calle');

    expect(parsed.isVitalRisk, isFalse);
    expect(parsed.matchedTerms, isEmpty);
  });

  // Decisión de UX (D-03): si la red falla, NO bloqueamos el envío del reporte.
  // El check de vital risk se trata como "best-effort": si no podemos
  // evaluarlo, dejamos al pipeline backend hacer el check defensivo.
  test('errores de red devuelven isVitalRisk: false (no bloquea el envío)',
      () async {
    when(() => callable.call<Map<String, dynamic>>(any<Map<String, dynamic>>()))
        .thenThrow(FirebaseFunctionsException(
      code: 'unavailable',
      message: 'Network error',
    ));

    final parsed = await service.check('descripción cualquiera');

    expect(parsed.isVitalRisk, isFalse);
  });

  test('errores de unauthenticated se propagan como NetworkException', () {
    when(() => callable.call<Map<String, dynamic>>(any<Map<String, dynamic>>()))
        .thenThrow(FirebaseFunctionsException(
      code: 'unauthenticated',
      message: 'Auth required',
    ));

    expect(
      () => service.check('descripción'),
      throwsA(isA<NetworkException>()),
    );
  });

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });
}
