import 'dart:typed_data';

import '../entities/incident_event.dart';

abstract interface class IncidentsRepository {
  Future<String> submitIncident(IncidentEvent event);
  Stream<List<IncidentEvent>> watchIncidents();
  Stream<List<IncidentEvent>> watchActiveIncidents();
  // Reportes del usuario actual, ordenados por fecha desc (más nuevo primero).
  // Sin filtro de status: el dueño ve todos los suyos en cualquier estado. [F-01]
  Stream<List<IncidentEvent>> watchMyIncidents(String userId);
  Future<IncidentEvent> getIncidentById(String eventId);
  Stream<IncidentEvent> watchIncidentById(String eventId);
  Future<void> updateStatus(
    String eventId,
    IncidentStatus status, {
    String? changedBy,
    String? resolutionEvidenceUrl,
  });

  /// Sube la foto de evidencia de resolución al cerrar un incident y devuelve
  /// la URL. Escritura restringida a admin/referente por reglas de Storage.
  /// [F-06]
  Future<String> uploadResolutionEvidence(
    Uint8List bytes,
    String fileName,
    String incidentId,
  );

  /// Edita un reporte propio mientras `status == recibido`. Solo los tres
  /// campos editables por el dueño (description, category, photoUrl). Las
  /// reglas Firestore validan el contrato. [F-01]
  Future<void> updateOwnIncidentDraft(
    String eventId, {
    String? description,
    IncidentCategory? category,
    String? photoUrl,
  });

  /// Sube una foto a Storage y devuelve la URL. Reutilizable por flujos de
  /// reporte y edición. [F-01]
  Future<String> uploadPhoto(
    Uint8List bytes,
    String fileName,
    String userId,
  );

  /// El reportero confirma el cierre del reporte. [F-05]
  Future<void> confirmOwnClosure({
    required String eventId,
    required String ownerUid,
  });

  /// El reportero disputa el cierre con nota obligatoria. Vuelve el status a
  /// `enReparacion`. [F-05]
  Future<void> disputeOwnClosure({
    required String eventId,
    required String ownerUid,
    required String note,
  });
}
