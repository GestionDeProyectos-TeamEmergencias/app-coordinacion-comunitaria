import 'dart:typed_data';

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
  Stream<List<IncidentEvent>> watchMyIncidents(String userId) =>
      _dataSource.watchMyIncidents(userId).map(
            (models) => models.map((m) => m.toDomain()).toList(),
          );

  @override
  Future<void> updateOwnIncidentDraft(
    String eventId, {
    String? description,
    IncidentCategory? category,
    String? photoUrl,
  }) =>
      _dataSource.updateOwnIncidentDraft(
        eventId,
        description: description,
        category: category?.firestoreValue,
        photoUrl: photoUrl,
      );

  @override
  Future<void> confirmOwnClosure({
    required String eventId,
    required String ownerUid,
  }) =>
      _dataSource.confirmOwnClosure(eventId: eventId, ownerUid: ownerUid);

  @override
  Future<void> disputeOwnClosure({
    required String eventId,
    required String ownerUid,
    required String note,
  }) =>
      _dataSource.disputeOwnClosure(
        eventId: eventId,
        ownerUid: ownerUid,
        note: note,
      );

  @override
  Future<String> uploadPhoto(
    Uint8List bytes,
    String fileName,
    String userId,
  ) =>
      _dataSource.uploadPhoto(bytes, fileName, userId);

  @override
  Future<String> uploadResolutionEvidence(
    Uint8List bytes,
    String fileName,
    String incidentId,
  ) =>
      _dataSource.uploadResolutionEvidence(bytes, fileName, incidentId);

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
    String? resolutionEvidenceUrl,
  }) =>
      _dataSource.updateStatus(
        eventId,
        status.firestoreValue,
        changedBy: changedBy,
        resolutionEvidenceUrl: resolutionEvidenceUrl,
      );
}
