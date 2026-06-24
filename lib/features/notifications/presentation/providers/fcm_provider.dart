import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/services/fcm_service.dart';
import 'fcm_service_provider.dart';

export 'fcm_service_provider.dart' show fcmServiceProvider;

/// Mantiene el token FCM sincronizado con la sesión: registra al loguearse
/// como `active`, desregistra al cerrar sesión. Se debe `watch`ear desde la
/// raíz de la app para que viva tanto como el árbol de widgets autenticado.
///
/// Implementación: escucha `authStateProvider` con `ref.listen`. Cada transición
/// dispara `registerForUser` o `unregisterCurrent` según corresponda. El servicio
/// es idempotente (no duplica si se llama dos veces para el mismo uid), así que
/// re-builds del provider son seguros.
///
/// Nota: el `unregisterCurrent` también lo llama explícitamente
/// `AuthNotifier.logout()` ANTES del `signOut`, porque las reglas Firestore
/// niegan el update sobre el doc del user una vez deslogueado. El listener
/// queda como red de seguridad para casos como expiración de token o reload de
/// la app sin user activo. [D-01]
final fcmAuthSyncProvider = Provider<void>((ref) {
  final FcmService service = ref.watch(fcmServiceProvider);

  ref.listen<AsyncValue<AppUser?>>(authStateProvider, (previous, next) {
    final prevUser = previous?.valueOrNull;
    final nextUser = next.valueOrNull;

    if (prevUser != null && nextUser == null) {
      service.unregisterCurrent();
      return;
    }

    if (nextUser != null && nextUser.isActive) {
      service.registerForUser(nextUser.userId);
    }
  }, fireImmediately: true);
});
