import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/terms_config.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../data/services/terms_acceptance_service.dart';

/// Servicio singleton para aceptar T&C. Sobrecargable en tests. [D-04]
final termsAcceptanceServiceProvider = Provider<TermsAcceptanceService>((ref) {
  return TermsAcceptanceService();
});

/// True si el usuario tiene una versión aceptada >= a la actual. False si
/// nunca aceptó o si su versión quedó atrás de la actual (re-pedir). [D-04]
bool hasAcceptedCurrentTerms(AppUser user) {
  final v = user.termsAcceptedVersion;
  return v != null && v >= TermsConfig.currentVersion;
}

/// Estado del notifier de aceptación: `null` (idle), `loading`, `data` (ok)
/// o `error`. Lo consume la pantalla del gate para mostrar feedback.
class TermsAcceptanceNotifier extends StateNotifier<AsyncValue<void>> {
  TermsAcceptanceNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> accept(String userId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return _ref.read(termsAcceptanceServiceProvider).accept(
            userId: userId,
            version: TermsConfig.currentVersion,
          );
    });
  }
}

final termsAcceptanceNotifierProvider =
    StateNotifierProvider<TermsAcceptanceNotifier, AsyncValue<void>>(
  (ref) => TermsAcceptanceNotifier(ref),
);
