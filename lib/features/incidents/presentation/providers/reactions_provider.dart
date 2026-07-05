import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/services/reactions_service.dart';
import '../../domain/entities/incident_event.dart';

/// Provider del servicio de reacciones. Sobrecargable en tests. [F-04]
final reactionsServiceProvider = Provider<ReactionsService>((ref) {
  return ReactionsService();
});

/// Stream de la reacción del user actual sobre el incident. Emite `null` si
/// todavía no votó o si no hay user logueado. [F-04]
final myReactionForIncidentProvider =
    StreamProvider.autoDispose.family<ReactionType?, String>((ref, incidentId) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return ref
      .watch(reactionsServiceProvider)
      .watchMyReaction(incidentId: incidentId, userId: user.userId);
});

class ReactionsNotifier extends StateNotifier<AsyncValue<void>> {
  ReactionsNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> toggle({
    required String incidentId,
    required ReactionType target,
    required ReactionType? current,
  }) async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = _ref.read(reactionsServiceProvider);
      if (current == target) {
        // Tap en el mismo botón → retirar voto.
        await service.removeReaction(
          incidentId: incidentId,
          userId: user.userId,
        );
      } else {
        await service.setReaction(
          incidentId: incidentId,
          userId: user.userId,
          type: target,
        );
      }
    });
  }
}

final reactionsNotifierProvider =
    StateNotifierProvider<ReactionsNotifier, AsyncValue<void>>(
  (ref) => ReactionsNotifier(ref),
);
