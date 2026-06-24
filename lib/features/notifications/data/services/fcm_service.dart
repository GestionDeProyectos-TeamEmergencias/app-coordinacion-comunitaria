import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Servicio que registra el dispositivo en Firebase Cloud Messaging y persiste
/// el token en `users/{uid}.fcmTokens` para que el backend pueda enviar push.
/// [D-01 — cierre de deuda MVP de T-NLP-07 / T-NLP-09]
///
/// Diseño:
/// - El array `fcmTokens` soporta múltiples dispositivos por usuario (mobile +
///   web, varios celulares). Cada `register()` hace `arrayUnion`.
/// - `onTokenRefresh` rota el token: el viejo queda en el array hasta que el
///   backend lo detecte como `registration-token-not-registered` y lo limpie
///   (ya implementado en `pushNotifications.ts` y `adminBroadcast.ts`).
/// - `unregisterCurrent()` se llama en logout para sacar este dispositivo del
///   array y no enviar push a una sesión cerrada.
class FcmService {
  FcmService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  StreamSubscription<String>? _refreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  String? _currentToken;
  String? _registeredForUid;

  /// Pide permisos, obtiene el token y lo persiste en `users/{uid}.fcmTokens`.
  /// Idempotente: llamarla dos veces con el mismo uid no duplica el token.
  /// Si los permisos son denegados, retorna `false` y no persiste nada.
  Future<bool> registerForUser(String userId) async {
    if (_registeredForUid == userId && _currentToken != null) {
      // Ya está registrado para este user. Nada que hacer.
      return true;
    }

    // 1. Pedir permisos. En web, una notificación bloqueada por el browser
    //    aparece como denegada acá.
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return false;
    }

    // 2. Obtener el token. En web requiere el vapidKey (configurado en consola
    //    de Firebase). Si falta, `getToken` retorna null silenciosamente.
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    // 3. Persistir con arrayUnion para no duplicar entre dispositivos.
    await _firestore.collection('users').doc(userId).update({
      'fcmTokens': FieldValue.arrayUnion([token]),
    });

    _currentToken = token;
    _registeredForUid = userId;

    // 4. Suscribirse a la rotación del token (puede pasar por update del SO,
    //    reinstalación, expiración del vapidKey en web, etc.).
    await _refreshSub?.cancel();
    _refreshSub = _messaging.onTokenRefresh.listen((newToken) async {
      if (newToken == _currentToken) return;
      await _firestore.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([newToken]),
      });
      _currentToken = newToken;
    });

    // 5. Handler de notificaciones en foreground. En foreground, FCM no muestra
    //    la notif del sistema automáticamente; tenemos que loggear el evento
    //    para que el resto de la app reaccione (snackbar, navegación, etc.).
    //    `onMessage` es un static que toca el platform channel: en tests sin
    //    binding inicializado puede tirar — try/catch silencioso.
    await _foregroundSub?.cancel();
    try {
      _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
        debugPrint(
          'FCM foreground: ${message.notification?.title} / data=${message.data}',
        );
      });
    } catch (e) {
      debugPrint('FCM onMessage subscription skipped: $e');
    }

    return true;
  }

  /// Saca el token de este dispositivo del array del usuario al cerrar sesión.
  /// Best-effort: si falla, loggea y sigue. No bloquea el logout.
  Future<void> unregisterCurrent() async {
    final token = _currentToken;
    final uid = _registeredForUid;
    if (token == null || uid == null) return;

    try {
      await _firestore.collection('users').doc(uid).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
    } catch (e) {
      debugPrint('FCM unregister failed (best-effort): $e');
    } finally {
      await _refreshSub?.cancel();
      await _foregroundSub?.cancel();
      _refreshSub = null;
      _foregroundSub = null;
      _currentToken = null;
      _registeredForUid = null;
    }
  }
}
