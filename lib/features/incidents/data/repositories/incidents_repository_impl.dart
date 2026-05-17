import '../../domain/entities/incident_event.dart';
import '../../domain/repositories/incidents_repository.dart';
import '../datasources/incidents_remote_datasource.dart';

class IncidentsRepositoryImpl implements IncidentsRepository {
  const IncidentsRepositoryImpl(this._dataSource);

  final IncidentsRemoteDataSource _dataSource;

  @override
  Future<String> submitIncident(IncidentEvent event) =>
      _dataSource.submitIncident(event);

  @override
  Stream<List<IncidentEvent>> watchIncidents() =>
      _dataSource.watchIncidents().map(
            (models) => models.map((m) => m.toDomain()).toList(),
          );

  @override
  Future<IncidentEvent> getIncidentById(String eventId) async {
    final model = await _dataSource.getIncidentById(eventId);
    return model.toDomain();
  }

  @override
  Future<void> updateStatus(String eventId, IncidentStatus status) =>
      _dataSource.updateStatus(eventId, status.firestoreValue);
}
