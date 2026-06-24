import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/notifications/presentation/providers/fcm_provider.dart';
import 'router.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Mantiene el token FCM sincronizado con la sesión (registra al loguearse,
    // desregistra al hacer logout). Debe estar a este nivel para sobrevivir
    // cualquier rebuild de pantallas. [D-01]
    ref.watch(fcmAuthSyncProvider);

    return MaterialApp.router(
      title: 'Coordinación Comunitaria',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      routerConfig: router,
    );
  }
}
