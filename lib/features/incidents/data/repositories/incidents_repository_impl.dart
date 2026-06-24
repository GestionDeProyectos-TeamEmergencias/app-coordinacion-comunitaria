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
  Stream<List<IncidentEvent>> watchActiveIncidents() => watchIncidents().map(
        (all) => all
            .where((i) =>
                i.status != IncidentStatus.solucionado &&
                i.status != IncidentStatus.rechazadoFueraDeCobertura &&
                i.status != IncidentStatus.falso &&
                // Riesgo vital y autor inactivo no son incidentes activos del
                // barrio: el pipeline ya los descartó. [D-03]
                i.status != IncidentStatus.vitalRiskDetected &&
                i.status != IncidentStatus.rechazadoAutorInactivo)
            .toList(),
      );

  @override
  Future<IncidentEvent> getIncidentById(String eventId) async {
    final model = await _dataSource.getIncidentById(eventId);
    return model.toDomain();
  }

  @override
  Stream<IncidentEvent> watchIncidentById(String eventId) =>
      _dataSource.watchIncidentById(eventId).map((m) => m.toDomain());

  @override
  Future<void> updateStatus(
    String eventId,
    IncidentStatus status, {
    String? changedBy,
  }) =>
      _dataSource.updateStatus(
        eventId,
        status.firestoreValue,
        changedBy: changedBy,
      );
}
