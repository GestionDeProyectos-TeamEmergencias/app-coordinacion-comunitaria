import '../entities/incident_event.dart';
import '../repositories/incidents_repository.dart';

// RF-REP-02: reporte por voz — texto transcripto on-device por speech_to_text.
class SubmitVoiceReportUseCase {
  const SubmitVoiceReportUseCase(this._repository);

  final IncidentsRepository _repository;

  Future<String> call({
    required String userId,
    required double latitude,
    required double longitude,
    required String transcribedText,
  }) {
    final event = IncidentEvent(
      userId: userId,
      timestamp: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
      description: transcribedText,
      sourceType: SourceType.voice,
    );
    return _repository.submitIncident(event);
  }
}
