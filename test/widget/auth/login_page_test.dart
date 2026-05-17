import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app_coordinacion_comunitaria/features/auth/presentation/pages/login_page.dart';

void main() {
  testWidgets('LoginPage muestra campos de email y contraseña', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [GoRoute(path: '/', builder: (_, __) => const LoginPage())],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('muestra error de validación cuando el email es inválido',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [GoRoute(path: '/', builder: (_, __) => const LoginPage())],
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).first, 'no-es-un-email');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();

    expect(find.text('Email inválido'), findsOneWidget);
  });
}
