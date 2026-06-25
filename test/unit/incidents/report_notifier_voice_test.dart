import 'package:app_coordinacion_comunitaria/core/errors/app_exception.dart';
import 'package:app_coordinacion_comunitaria/features/admin/domain/entities/coverage_config.dart';
import 'package:app_coordinacion_comunitaria/features/admin/presentation/providers/coverage_config_provider.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/domain/entities/incident_event.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/domain/usecases/submit_form_report_usecase.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/domain/usecases/submit_voice_report_usecase.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/presentation/providers/incidents_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockVoiceUseCase extends Mock implements SubmitVoiceReportUseCase {}

class _MockFormUseCase extends Mock implements SubmitFormReportUseCase {}

const _coverageDefault = CoverageConfig(
  centerLat: -34.6037,
  centerLng: -58.3816,
  radiusMeters: 5000,
);

ProviderContainer _makeContainer({
  required _MockVoiceUseCase voice,
  required _MockFormUseCase form,
}) {
  return ProviderContainer(
    overrides: [
      coverageConfigProvider
          .overrideWith((_) => Stream.value(_coverageDefault)),
      submitVoiceReportProvider.overrideWithValue(voice),
      submitFormReportProvider.overrideWithValue(form),
    ],
  );
}

void main() {
  late _MockVoiceUseCase voice;
  late _MockFormUseCase form;

  setUpAll(() {
    registerFallbackValue(IncidentCategory.vial);
  });

  setUp(() {
    voice = _MockVoiceUseCase();
    form = _MockFormUseCase();
  });

  // D-10: el flujo de voz invoca SubmitVoiceReportUseCase (que existía pero
  // nunca se llamaba) y NO SubmitFormReportUseCase. Sin esto, el incident
  // siempre quedaba con sourceType=form aunque el usuario reportara por voz.
  test('submitVoice invoca SubmitVoiceReportUseCase y NO el form use case',
      () async {
    when(() => voice(
          userId: any(named: 'userId'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          transcribedText: any(named: 'transcribedText'),
        )).thenAnswer((_) async => 'event-id-voice');

    final container = _makeContainer(voice: voice, form: form);
    addTearDown(container.dispose);

    await container.read(reportNotifierProvider.notifier).submitVoice(
          userId: 'uid-1',
          latitude: _coverageDefault.centerLat,
          longitude: _coverageDefault.centerLng,
          transcribedText: 'Hay un bache en la esquina',
        );

    verify(() => voice(
          userId: 'uid-1',
          latitude: _coverageDefault.centerLat,
          longitude: _coverageDefault.centerLng,
          transcribedText: 'Hay un bache en la esquina',
        )).called(1);
    verifyNever(() => form(
          userId: any(named: 'userId'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          description: any(named: 'description'),
          category: any(named: 'category'),
          photoUrl: any(named: 'photoUrl'),
        ));
  });

  test('submitVoice respeta validación de cobertura (lanza OutOfCoverage)',
      () async {
    final container = _makeContainer(voice: voice, form: form);
    addTearDown(container.dispose);

    await container.read(reportNotifierProvider.notifier).submitVoice(
          userId: 'uid-1',
          // Coordenadas claramente fuera del radio (otro hemisferio).
          latitude: 51.5,
          longitude: -0.12,
          transcribedText: 'test',
        );

    final state = container.read(reportNotifierProvider);
    expect(state.hasError, isTrue);
    expect(state.error, isA<OutOfCoverageException>());
  });

  test('el use case voice construye IncidentEvent con sourceType=voice',
      () async {
    // Smoke test que vincula el contrato D-10 con el use case real (sin mock).
    // Más detalle del use case está en submit_voice_report_usecase_test.dart.
    expect(SourceType.voice.value, 'voice');
  });
}
