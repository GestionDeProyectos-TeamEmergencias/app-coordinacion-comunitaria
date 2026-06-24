import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'firebase_options.dart';

/// Handler de notificaciones FCM cuando la app está en background o terminada.
/// Debe ser top-level y anotado `@pragma('vm:entry-point')` porque corre en un
/// isolate separado spawn-eado por el sistema. Solo loggeamos por ahora; el
/// sistema operativo se encarga de mostrar la notificación si trae el bloque
/// `notification`. [D-01]
@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('FCM background: ${message.messageId} data=${message.data}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);
  runApp(const ProviderScope(child: App()));
}
