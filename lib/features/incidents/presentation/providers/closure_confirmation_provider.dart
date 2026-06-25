import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'incidents_provider.dart';

/// Notifier que persiste la decisión del reportero sobre el cierre. [F-05]
class ClosureConfirmationNotifier extends StateNotifier<AsyncValue<void>> {
  ClosureConfirmationNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> confirm({
    required String incidentId,
    required String ownerUid,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _ref.read(incidentsRepositoryProvider).confirmOwnClosure(
            eventId: incidentId,
            ownerUid: ownerUid,
          ),
    );
  }

  Future<void> dispute({
    required String incidentId,
    required String ownerUid,
    required String note,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _ref.read(incidentsRepositoryProvider).disputeOwnClosure(
            eventId: incidentId,
            ownerUid: ownerUid,
            note: note,
          ),
    );
  }
}

final closureConfirmationNotifierProvider =
    StateNotifierProvider<ClosureConfirmationNotifier, AsyncValue<void>>(
  (ref) => ClosureConfirmationNotifier(ref),
);
