import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/moderation_remote_service.dart';

/// Provider del servicio de moderación. Exposed para overrides en tests.
final moderationServiceProvider = Provider<ModerationRemoteService>(
  (ref) => ModerationRemoteService(),
);

/// Notifier de moderación: marca falso y desbloquea usuarios. [T-AUTH-07]
class ModerationNotifier extends StateNotifier<AsyncValue<void>> {
  ModerationNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;
  ModerationResult? _lastResult;

  ModerationResult? get lastResult => _lastResult;

  Future<void> markAsFalse({
    required String incidentId,
    required String userId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await _ref
          .read(moderationServiceProvider)
          .marcarReporteComoFalso(incidentId: incidentId, userId: userId);
      _lastResult = result;
    });
  }

  Future<void> unblock({required String userId}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _ref.read(moderationServiceProvider).desbloquearUsuario(userId: userId),
    );
  }
}

final moderationNotifierProvider =
    StateNotifierProvider<ModerationNotifier, AsyncValue<void>>(
  (ref) => ModerationNotifier(ref),
);
