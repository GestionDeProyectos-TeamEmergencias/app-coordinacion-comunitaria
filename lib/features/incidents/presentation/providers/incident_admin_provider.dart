import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/incident_admin_service.dart';
import '../../domain/entities/incident_event.dart';

/// Provider del servicio admin de incidents. Sobrecargable en tests. [D-06]
final incidentAdminServiceProvider = Provider<IncidentAdminService>((ref) {
  return IncidentAdminService();
});

class IncidentAdminNotifier extends StateNotifier<AsyncValue<void>> {
  IncidentAdminNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> reassignCategory({
    required String incidentId,
    required IncidentCategory category,
    required String adminUid,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _ref.read(incidentAdminServiceProvider).reassignCategory(
            incidentId: incidentId,
            category: category,
            adminUid: adminUid,
          ),
    );
  }

  Future<void> addAction({
    required String incidentId,
    required String note,
    required String adminUid,
    String? adminDisplayName,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _ref.read(incidentAdminServiceProvider).addAction(
            incidentId: incidentId,
            note: note,
            adminUid: adminUid,
            adminDisplayName: adminDisplayName,
          ),
    );
  }
}

final incidentAdminNotifierProvider =
    StateNotifierProvider<IncidentAdminNotifier, AsyncValue<void>>(
  (ref) => IncidentAdminNotifier(ref),
);
