import 'dart:typed_data';

import 'package:app_coordinacion_comunitaria/features/incidents/domain/entities/incident_event.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/domain/repositories/incidents_repository.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/presentation/providers/incidents_provider.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/presentation/providers/my_incidents_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingRepo implements IncidentsRepository {
  String? lastEventId;
  String? lastDescription;
  IncidentCategory? lastCategory;
  String? lastPhotoUrl;
  Uint8List? lastUploadedBytes;
  String? lastUploadedName;
  String? lastUploadedOwnerUid;
  int uploadCount = 0;
  int updateCount = 0;
  Object? error;

  @override
  Future<void> updateOwnIncidentDraft(
    String eventId, {
    String? description,
    IncidentCategory? category,
    String? photoUrl,
  }) async {
    if (error != null) throw error!;
    updateCount++;
    lastEventId = eventId;
    lastDescription = description;
    lastCategory = category;
    lastPhotoUrl = photoUrl;
  }

  @override
  Future<String> uploadPhoto(
    Uint8List bytes,
    String fileName,
    String userId,
  ) async {
    uploadCount++;
    lastUploadedBytes = bytes;
    lastUploadedName = fileName;
    lastUploadedOwnerUid = userId;
    return 'https://example.com/photo-$uploadCount.jpg';
  }

  @override
  Future<IncidentEvent> getIncidentById(String eventId) =>
      throw UnimplementedError();
  @override
  Future<String> submitIncident(IncidentEvent event) =>
      throw UnimplementedError();
  @override
  Future<void> updateStatus(
    String eventId,
    IncidentStatus status, {
    String? changedBy,
  }) =>
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
  late _RecordingRepo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _RecordingRepo();
    container = ProviderContainer(
      overrides: [incidentsRepositoryProvider.overrideWithValue(repo)],
    );
  });

  tearDown(() => container.dispose());

  test('save sin foto: solo invoca updateOwnIncidentDraft', () async {
    await container.read(editOwnIncidentNotifierProvider.notifier).save(
          eventId: 'evt-1',
          ownerUid: 'owner-1',
          description: 'descripción nueva',
          category: IncidentCategory.sanitario,
        );

    expect(repo.uploadCount, 0);
    expect(repo.updateCount, 1);
    expect(repo.lastEventId, 'evt-1');
    expect(repo.lastDescription, 'descripción nueva');
    expect(repo.lastCategory, IncidentCategory.sanitario);
    expect(repo.lastPhotoUrl, isNull);
  });

  test('save con foto: sube primero y luego propaga photoUrl', () async {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    await container.read(editOwnIncidentNotifierProvider.notifier).save(
          eventId: 'evt-2',
          ownerUid: 'owner-2',
          description: 'con foto',
          category: IncidentCategory.vial,
          newPhotoBytes: bytes,
          newPhotoName: 'foto.jpg',
        );

    expect(repo.uploadCount, 1);
    expect(repo.lastUploadedBytes, bytes);
    expect(repo.lastUploadedName, 'foto.jpg');
    expect(repo.lastUploadedOwnerUid, 'owner-2');
    expect(repo.updateCount, 1);
    expect(repo.lastPhotoUrl, 'https://example.com/photo-1.jpg');
  });

  test('error del repo se expone como AsyncError', () async {
    repo.error = Exception('regla Firestore rechazó la edición');
    await container.read(editOwnIncidentNotifierProvider.notifier).save(
          eventId: 'evt-3',
          ownerUid: 'owner-3',
          description: 'algo',
        );

    final state = container.read(editOwnIncidentNotifierProvider);
    expect(state.hasError, isTrue);
  });
}
