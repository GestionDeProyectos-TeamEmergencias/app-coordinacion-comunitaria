import 'package:app_coordinacion_comunitaria/core/errors/app_exception.dart';
import 'package:app_coordinacion_comunitaria/features/auth/data/services/moderation_remote_service.dart';
import 'package:app_coordinacion_comunitaria/features/auth/presentation/providers/moderation_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeService implements ModerationRemoteService {
  String? lastIncidentId;
  String? lastUserId;
  String? lastUnblockedUid;
  ModerationResult nextResult = const ModerationResult(
    blocked: false,
    alreadyModerated: false,
  );
  Object? error;

  @override
  Future<ModerationResult> marcarReporteComoFalso({
    required String incidentId,
    required String userId,
  }) async {
    if (error != null) throw error!;
    lastIncidentId = incidentId;
    lastUserId = userId;
    return nextResult;
  }

  @override
  Future<void> desbloquearUsuario({required String userId}) async {
    if (error != null) throw error!;
    lastUnblockedUid = userId;
  }
}

void main() {
  group('ModerationNotifier.markAsFalse', () {
    test('reenvía los ids al servicio y guarda el resultado en lastResult',
        () async {
      final fake = _FakeService()
        ..nextResult = const ModerationResult(
          blocked: false,
          alreadyModerated: false,
        );
      final container = ProviderContainer(overrides: [
        moderationServiceProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      await container.read(moderationNotifierProvider.notifier).markAsFalse(
            incidentId: 'inc-1',
            userId: 'usr-1',
          );

      expect(fake.lastIncidentId, 'inc-1');
      expect(fake.lastUserId, 'usr-1');
      final result =
          container.read(moderationNotifierProvider.notifier).lastResult;
      expect(result?.blocked, isFalse);
      expect(container.read(moderationNotifierProvider).hasError, isFalse);
    });

    test('expone blocked=true cuando el callable lo indica', () async {
      final fake = _FakeService()
        ..nextResult = const ModerationResult(
          blocked: true,
          alreadyModerated: false,
        );
      final container = ProviderContainer(overrides: [
        moderationServiceProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      await container.read(moderationNotifierProvider.notifier).markAsFalse(
            incidentId: 'inc-2',
            userId: 'usr-2',
          );

      final result =
          container.read(moderationNotifierProvider.notifier).lastResult;
      expect(result?.blocked, isTrue);
    });

    test('propaga errores del servicio en el estado', () async {
      final fake = _FakeService()..error = const FirestoreException('boom');
      final container = ProviderContainer(overrides: [
        moderationServiceProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      await container.read(moderationNotifierProvider.notifier).markAsFalse(
            incidentId: 'inc-3',
            userId: 'usr-3',
          );

      final state = container.read(moderationNotifierProvider);
      expect(state.hasError, isTrue);
      expect(state.error.toString(), contains('boom'));
    });
  });

  group('ModerationNotifier.unblock', () {
    test('llama al servicio con el uid correcto', () async {
      final fake = _FakeService();
      final container = ProviderContainer(overrides: [
        moderationServiceProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      await container
          .read(moderationNotifierProvider.notifier)
          .unblock(userId: 'usr-blocked');

      expect(fake.lastUnblockedUid, 'usr-blocked');
      expect(container.read(moderationNotifierProvider).hasError, isFalse);
    });

    test('propaga errores del servicio', () async {
      final fake = _FakeService()..error = Exception('no permissions');
      final container = ProviderContainer(overrides: [
        moderationServiceProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      await container
          .read(moderationNotifierProvider.notifier)
          .unblock(userId: 'usr-x');

      expect(container.read(moderationNotifierProvider).hasError, isTrue);
    });
  });
}
