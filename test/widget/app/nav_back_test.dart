import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// Regresión del bug "el back cierra la app": la navegación de avance debe usar
// `context.push` (apila sobre la pantalla previa) y no `context.go` (reemplaza
// el stack). Estos tests fijan esa semántica con un GoRouter mínimo.

GoRouter _router({required bool usePush}) {
  return GoRouter(
    initialLocation: '/a',
    routes: [
      GoRoute(
        path: '/a',
        builder: (context, __) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => usePush ? context.push('/b') : context.go('/b'),
              child: const Text('ir-a-b'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/b',
        builder: (_, __) => const Scaffold(body: Center(child: Text('pag-b'))),
      ),
    ],
  );
}

void main() {
  testWidgets('push: el back vuelve a la pantalla previa (no cierra)',
      (tester) async {
    final router = _router(usePush: true);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ir-a-b'));
    await tester.pumpAndSettle();
    expect(find.text('pag-b'), findsOneWidget);

    // Con push hay pantalla previa que popear → el back funciona.
    expect(router.canPop(), isTrue);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('ir-a-b'), findsOneWidget);
  });

  testWidgets('go: reemplaza el stack y deja sin a dónde volver (bug)',
      (tester) async {
    final router = _router(usePush: false);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ir-a-b'));
    await tester.pumpAndSettle();
    expect(find.text('pag-b'), findsOneWidget);

    // Con go a una ruta top-level no queda pantalla previa: el back saldría.
    expect(router.canPop(), isFalse);
  });
}
