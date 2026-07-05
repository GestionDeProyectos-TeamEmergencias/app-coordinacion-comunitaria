import 'dart:typed_data';

import 'package:app_coordinacion_comunitaria/features/incidents/domain/entities/incident_event.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/domain/repositories/incidents_repository.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/presentation/providers/incidents_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements IncidentsRepository {
  IncidentStatus? lastStatus;
  String? lastChangedBy;
  String? lastEventId;
  String? lastResolutionEvidenceUrl;
  Uint8List? lastEvidenceBytes;
  String? lastEvidenceName;
  String? lastEvidenceIncidentId;
  int uploadEvidenceCount = 0;
  Object? error;

  @override
  Future<void> updateStatus(
    String eventId,
    IncidentStatus status, {
    String? changedBy,
    String? resolutionEvidenceUrl,
  }) async {
    if (error != null) throw error!;
    lastEventId = eventId;
    lastStatus = status;
    lastChangedBy = changedBy;
    lastResolutionEvidenceUrl = resolutionEvidenceUrl;
  }

  @override
  Future<String> uploadResolutionEvidence(
    Uint8List bytes,
    String fileName,
    String incidentId,
  ) async {
    uploadEvidenceCount++;
    lastEvidenceBytes = bytes;
    lastEvidenceName = fileName;
    lastEvidenceIncidentId = incidentId;
    return 'https://example.com/resolution-$uploadEvidenceCount.jpg';
  }

  @override
  Future<IncidentEvent> getIncidentById(String eventId) =>
      throw UnimplementedError();
  @override
  Future<String> submitIncident(IncidentEvent event) =>
      throw UnimplementedError();
  @override
  Stream<List<IncidentEvent>> watchActiveIncidents() =>
      throw UnimplementedError();
  @override
  Stream<IncidentEvent> watchIncidentById(String eventId) =>
      throw UnimplementedError();
  @override
  Stream<List<IncidentEvent>> watchIncidents() => throw UnimplementedError();
  @override
  Stream<List<IncidentEvent>> watchMyIncidents(String userId) =>
      throw UnimplementedError();
  @override
  Future<void> updateOwnIncidentDraft(
    String eventId, {
    String? description,
    IncidentCategory? category,
    String? photoUrl,
  }) =>
      throw UnimplementedError();
  @override
  Future<String> uploadPhoto(_, __, ___) => throw UnimplementedError();
  @override
  Future<void> confirmOwnClosure({
    required String eventId,
    required String ownerUid,
  }) =>
      throw UnimplementedError();
  @override
  Future<void> disputeOwnClosure({
    required String eventId,
    required String ownerUid,
    required String note,
  }) =>
      throw UnimplementedError();
}

void main() {
  group('UpdateStatusNotifier', () {
    test('actualiza el estado y propaga changedBy al repositorio', () async {
      final fakeRepo = _FakeRepo();
      final container = ProviderContainer(overrides: [
        incidentsRepositoryProvider.overrideWithValue(fakeRepo),
      ]);
      addTearDown(container.dispose);

      await container.read(updateStatusNotifierProvider.notifier).update(
            eventId: 'event-1',
            status: IncidentStatus.programado,
            changedBy: 'admin-uid',
          );

      expect(fakeRepo.lastEventId, 'event-1');
      expect(fakeRepo.lastStatus, IncidentStatus.programado);
      expect(fakeRepo.lastChangedBy, 'admin-uid');
      expect(container.read(updateStatusNotifierProvider).hasError, isFalse);
    });

    test('expone error cuando el repositorio falla', () async {
      final fakeRepo = _FakeRepo()..error = Exception('boom');
      final container = ProviderContainer(overrides: [
        incidentsRepositoryProvider.overrideWithValue(fakeRepo),
      ]);
      addTearDown(container.dispose);

      await container.read(updateStatusNotifierProvider.notifier).update(
            eventId: 'event-1',
            status: IncidentStatus.solucionado,
          );

      final state = container.read(updateStatusNotifierProvider);
      expect(state.hasError, isTrue);
      expect(state.error.toString(), contains('boom'));
    });

    // F-06: cierre con evidencia opcional.
    test('cierre sin foto: no sube evidencia y resolutionEvidenceUrl es null',
        () async {
      final fakeRepo = _FakeRepo();
      final container = ProviderContainer(overrides: [
        incidentsRepositoryProvider.overrideWithValue(fakeRepo),
      ]);
      addTearDown(container.dispose);

      await container.read(updateStatusNotifierProvider.notifier).update(
            eventId: 'event-9',
            status: IncidentStatus.solucionado,
            changedBy: 'ref-uid',
          );

      expect(fakeRepo.uploadEvidenceCount, 0);
      expect(fakeRepo.lastStatus, IncidentStatus.solucionado);
      expect(fakeRepo.lastResolutionEvidenceUrl, isNull);
    });

    test('cierre con foto: sube primero y propaga la URL al updateStatus',
        () async {
      final fakeRepo = _FakeRepo();
      final container = ProviderContainer(overrides: [
        incidentsRepositoryProvider.overrideWithValue(fakeRepo),
      ]);
      addTearDown(container.dispose);

      final bytes = Uint8List.fromList([9, 8, 7]);
      await container.read(updateStatusNotifierProvider.notifier).update(
            eventId: 'event-10',
            status: IncidentStatus.solucionado,
            changedBy: 'admin-uid',
            resolutionEvidenceBytes: bytes,
            resolutionEvidenceName: 'reparado.jpg',
          );

      expect(fakeRepo.uploadEvidenceCount, 1);
      expect(fakeRepo.lastEvidenceBytes, bytes);
      expect(fakeRepo.lastEvidenceName, 'reparado.jpg');
      // La evidencia se sube bajo el path del propio incident.
      expect(fakeRepo.lastEvidenceIncidentId, 'event-10');
      expect(
        fakeRepo.lastResolutionEvidenceUrl,
        'https://example.com/resolution-1.jpg',
      );
    });

    test('evidencia adjunta en transición que NO es cierre se ignora',
        () async {
      final fakeRepo = _FakeRepo();
      final container = ProviderContainer(overrides: [
        incidentsRepositoryProvider.overrideWithValue(fakeRepo),
      ]);
      addTearDown(container.dispose);

      await container.read(updateStatusNotifierProvider.notifier).update(
            eventId: 'event-11',
            status: IncidentStatus.enReparacion,
            changedBy: 'admin-uid',
            resolutionEvidenceBytes: Uint8List.fromList([1, 2]),
          );

      expect(fakeRepo.uploadEvidenceCount, 0);
      expect(fakeRepo.lastResolutionEvidenceUrl, isNull);
    });
  });
}
