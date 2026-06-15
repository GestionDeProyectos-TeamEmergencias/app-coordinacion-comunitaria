import 'package:app_coordinacion_comunitaria/features/incidents/domain/entities/incident_event.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/domain/repositories/incidents_repository.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/domain/usecases/submit_form_report_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockIncidentsRepository extends Mock implements IncidentsRepository {}

void main() {
  late SubmitFormReportUseCase sut;
  late MockIncidentsRepository mockRepo;

  setUp(() {
    mockRepo = MockIncidentsRepository();
    sut = SubmitFormReportUseCase(mockRepo);
    registerFallbackValue(
      IncidentEvent(
        userId: 'uid',
        timestamp: DateTime.now(),
        latitude: 0,
        longitude: 0,
        sourceType: SourceType.form,
      ),
    );
  });

  test(
    'crea un IncidentEvent con sourceType=form, descripción, categoría y '
    'photoUrl, y lo envía al repositorio',
    () async {
      when(() => mockRepo.submitIncident(any()))
          .thenAnswer((_) async => 'event-id-form-1');

      final result = await sut(
        userId: 'uid-1',
        latitude: -34.6037,
        longitude: -58.3816,
        description: 'Bache profundo en la calzada',
        category: IncidentCategory.vial,
        photoUrl: 'https://storage.example.com/photo.jpg',
      );

      expect(result, 'event-id-form-1');
      final captured = verify(() => mockRepo.submitIncident(captureAny()))
          .captured
          .first as IncidentEvent;
      expect(captured.sourceType, SourceType.form);
      expect(captured.userId, 'uid-1');
      expect(captured.description, 'Bache profundo en la calzada');
      expect(captured.category, IncidentCategory.vial);
      expect(captured.photoUrl, 'https://storage.example.com/photo.jpg');
    },
  );

  test('crea un IncidentEvent sin foto cuando photoUrl es null', () async {
    when(() => mockRepo.submitIncident(any()))
        .thenAnswer((_) async => 'event-id-form-2');

    final result = await sut(
      userId: 'uid-1',
      latitude: -34.6037,
      longitude: -58.3816,
      description: 'Luminaria apagada',
      category: IncidentCategory.electrico,
    );

    expect(result, 'event-id-form-2');
    final captured = verify(() => mockRepo.submitIncident(captureAny()))
        .captured
        .first as IncidentEvent;
    expect(captured.photoUrl, isNull);
    expect(captured.category, IncidentCategory.electrico);
  });

  test('propaga excepción cuando el repositorio falla', () async {
    when(() => mockRepo.submitIncident(any()))
        .thenThrow(Exception('Error de red'));

    expect(
      () => sut(
        userId: 'uid-1',
        latitude: -34.6037,
        longitude: -58.3816,
        description: 'Test',
        category: IncidentCategory.sanitario,
      ),
      throwsA(isA<Exception>()),
    );
  });
}
