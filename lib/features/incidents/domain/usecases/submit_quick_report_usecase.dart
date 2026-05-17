import '../entities/incident_event.dart';
import '../repositories/incidents_repository.dart';

// RF-REP-01: reporte rápido — captura GPS + user + timestamp, sin descripción.
class SubmitQuickReportUseCase {
  const SubmitQuickReportUseCase(this._repository);

  final IncidentsRepository _repository;

  Future<String> call({
    required String userId,
    required double latitude,
    required double longitude,
  }) {
    final event = IncidentEvent(
      userId: userId,
      timestamp: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
      sourceType: SourceType.quick,
    );
    return _repository.submitIncident(event);
  }
}
