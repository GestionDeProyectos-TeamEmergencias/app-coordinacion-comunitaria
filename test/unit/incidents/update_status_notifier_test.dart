import 'package:app_coordinacion_comunitaria/features/incidents/domain/entities/incident_event.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/domain/repositories/incidents_repository.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/presentation/providers/incidents_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements IncidentsRepository {
  IncidentStatus? lastStatus;
  String? lastChangedBy;
  String? lastEventId;
  Object? error;

  @override
  Future<void> updateStatus(
    String eventId,
    IncidentStatus status, {
    String? changedBy,
  }) async {
    if (error != null) throw error!;
    lastEventId = eventId;
    lastStatus = status;
    lastChangedBy = changedBy;
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
  });
}
