import 'package:app_coordinacion_comunitaria/features/incidents/domain/entities/incident_event.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/domain/repositories/incidents_repository.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/domain/usecases/submit_voice_report_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockIncidentsRepository extends Mock implements IncidentsRepository {}

void main() {
  late SubmitVoiceReportUseCase sut;
  late MockIncidentsRepository mockRepo;

  setUp(() {
    mockRepo = MockIncidentsRepository();
    sut = SubmitVoiceReportUseCase(mockRepo);
    registerFallbackValue(
      IncidentEvent(
        userId: 'uid',
        timestamp: DateTime.now(),
        latitude: 0,
        longitude: 0,
        sourceType: SourceType.voice,
      ),
    );
  });

  test(
    'crea un IncidentEvent con sourceType=voice, description=transcribedText y '
    'lo envía al repositorio',
    () async {
      when(() => mockRepo.submitIncident(any()))
          .thenAnswer((_) async => 'event-id-voice-1');

      final result = await sut(
        userId: 'uid-1',
        latitude: -34.6037,
        longitude: -58.3816,
        transcribedText: 'Hay un bache en la esquina de la calle',
      );

      expect(result, 'event-id-voice-1');
      final captured = verify(() => mockRepo.submitIncident(captureAny()))
          .captured
          .first as IncidentEvent;
      expect(captured.sourceType, SourceType.voice);
      expect(captured.userId, 'uid-1');
      expect(
        captured.description,
        'Hay un bache en la esquina de la calle',
      );
    },
  );

  test('propaga excepción cuando el repositorio falla', () async {
    when(() => mockRepo.submitIncident(any()))
        .thenThrow(Exception('Error de red'));

    expect(
      () => sut(
        userId: 'uid-1',
        latitude: -34.6037,
        longitude: -58.3816,
        transcribedText: 'test',
      ),
      throwsA(isA<Exception>()),
    );
  });
}
