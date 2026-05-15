import '../entities/incident_event.dart';
import '../repositories/incidents_repository.dart';

// RF-REP-03: reporte con formulario — descripción, categoría, foto opcional.
class SubmitFormReportUseCase {
  const SubmitFormReportUseCase(this._repository);

  final IncidentsRepository _repository;

  Future<String> call({
    required String userId,
    required double latitude,
    required double longitude,
    required String description,
    required IncidentCategory category,
    String? photoUrl,
  }) {
    final event = IncidentEvent(
      userId: userId,
      timestamp: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
      description: description,
      category: category,
      sourceType: SourceType.form,
      photoUrl: photoUrl,
    );
    return _repository.submitIncident(event);
  }
}
