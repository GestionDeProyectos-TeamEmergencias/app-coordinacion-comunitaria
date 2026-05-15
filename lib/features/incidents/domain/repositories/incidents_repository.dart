import '../entities/incident_event.dart';

abstract interface class IncidentsRepository {
  Future<String> submitIncident(IncidentEvent event);
  Stream<List<IncidentEvent>> watchIncidents();
  Future<IncidentEvent> getIncidentById(String eventId);
  Future<void> updateStatus(String eventId, IncidentStatus status);
}
