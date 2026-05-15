import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app_coordinacion_comunitaria/features/incidents/domain/entities/incident_event.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/domain/repositories/incidents_repository.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/domain/usecases/submit_quick_report_usecase.dart';

class MockIncidentsRepository extends Mock implements IncidentsRepository {}

void main() {
  late SubmitQuickReportUseCase sut;
  late MockIncidentsRepository mockRepo;

  setUp(() {
    mockRepo = MockIncidentsRepository();
    sut = SubmitQuickReportUseCase(mockRepo);
    registerFallbackValue(
      IncidentEvent(
        userId: 'uid',
        timestamp: DateTime.now(),
        latitude: 0,
        longitude: 0,
        sourceType: SourceType.quick,
      ),
    );
  });

  test('crea un IncidentEvent con sourceType=quick y lo envía al repositorio', () async {
    when(() => mockRepo.submitIncident(any())).thenAnswer((_) async => 'event-id-1');

    final result = await sut(
      userId: 'uid-1',
      latitude: -34.6037,
      longitude: -58.3816,
    );

    expect(result, 'event-id-1');
    final captured = verify(() => mockRepo.submitIncident(captureAny())).captured.first
        as IncidentEvent;
    expect(captured.sourceType, SourceType.quick);
    expect(captured.userId, 'uid-1');
  });
}
