import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/referent_verification_service.dart';
import '../../domain/entities/incident_event.dart';

/// Provider del servicio de verificación del referente. Sobrecargable en
/// tests. [D-05]
final referentVerificationServiceProvider =
    Provider<ReferentVerificationService>((ref) {
  return ReferentVerificationService();
});

class ReferentVerificationNotifier extends StateNotifier<AsyncValue<void>> {
  ReferentVerificationNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> verify({
    required String incidentId,
    required ReferentVerificationState verificationState,
    required Uint8List photoBytes,
    required String photoName,
    required String referentUid,
    String? referentDisplayName,
    String? note,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _ref.read(referentVerificationServiceProvider).verify(
            incidentId: incidentId,
            state: verificationState,
            photoBytes: photoBytes,
            photoName: photoName,
            referentUid: referentUid,
            referentDisplayName: referentDisplayName,
            note: note,
          ),
    );
  }
}

final referentVerificationNotifierProvider =
    StateNotifierProvider<ReferentVerificationNotifier, AsyncValue<void>>(
  (ref) => ReferentVerificationNotifier(ref),
);
