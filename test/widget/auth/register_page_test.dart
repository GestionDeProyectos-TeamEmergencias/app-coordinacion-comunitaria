import 'package:app_coordinacion_comunitaria/features/auth/presentation/pages/register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget _buildUnderTest() => ProviderScope(
      child: MaterialApp.router(
        routerConfig: GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, __) => const RegisterPage()),
          ],
        ),
      ),
    );

/// Dispara la validación directamente en el FormState — más confiable
/// que simular un tap cuando hay SingleChildScrollView.
void _validateForm(WidgetTester tester) {
  tester.state<FormState>(find.byType(Form)).validate();
}

void main() {
  testWidgets('RegisterPage muestra campos de nombre, email y contraseña',
      (tester) async {
    await tester.pumpWidget(_buildUnderTest());
    await tester.pump();

    expect(find.text('Nombre completo'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsWidgets);
  });

  testWidgets('muestra error cuando nombre está vacío y se valida el form',
      (tester) async {
    await tester.pumpWidget(_buildUnderTest());
    await tester.pump();

    _validateForm(tester);
    await tester.pump();

    expect(find.text('Ingresá tu nombre'), findsOneWidget);
  });

  testWidgets('muestra error cuando email es inválido', (tester) async {
    await tester.pumpWidget(_buildUnderTest());
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), 'Mi Nombre');
    await tester.enterText(find.byType(TextFormField).at(1), 'no-es-un-email');
    _validateForm(tester);
    await tester.pump();

    expect(find.text('Email inválido'), findsOneWidget);
  });

  testWidgets('muestra error cuando contraseña tiene menos de 6 caracteres',
      (tester) async {
    await tester.pumpWidget(_buildUnderTest());
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), 'Mi Nombre');
    await tester.enterText(
        find.byType(TextFormField).at(1), 'test@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), '123');
    _validateForm(tester);
    await tester.pump();

    expect(find.text('Mínimo 6 caracteres'), findsOneWidget);
  });

  testWidgets('tiene botón para ir a la pantalla de login', (tester) async {
    await tester.pumpWidget(_buildUnderTest());
    await tester.pump();

    expect(find.text('¿Ya tenés cuenta? Iniciá sesión'), findsOneWidget);
  });

  testWidgets('toggle de visibilidad de contraseña funciona', (tester) async {
    await tester.pumpWidget(_buildUnderTest());
    await tester.pump();

    expect(find.byIcon(Icons.visibility), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pump();

    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
  });
}
