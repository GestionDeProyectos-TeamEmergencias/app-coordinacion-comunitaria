import 'package:app_coordinacion_comunitaria/features/auth/presentation/pages/pending_approval_page.dart';
import 'package:app_coordinacion_comunitaria/features/auth/presentation/pages/rejected_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget _buildPage(Widget page) => ProviderScope(
      child: MaterialApp.router(
        routerConfig: GoRouter(
          routes: [GoRoute(path: '/', builder: (_, __) => page)],
        ),
      ),
    );

void main() {
  group('PendingApprovalPage', () {
    testWidgets('muestra título y mensaje de cuenta en revisión',
        (tester) async {
      await tester.pumpWidget(_buildPage(const PendingApprovalPage()));
      await tester.pump();

      expect(find.text('Cuenta en revisión'), findsOneWidget);
      expect(
          find.textContaining('revisada por el administrador'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
    });

    testWidgets('muestra botón de cerrar sesión', (tester) async {
      await tester.pumpWidget(_buildPage(const PendingApprovalPage()));
      await tester.pump();

      expect(find.text('Cerrar sesión'), findsOneWidget);
    });
  });

  group('RejectedPage', () {
    testWidgets('muestra título y mensaje de cuenta rechazada', (tester) async {
      await tester.pumpWidget(_buildPage(const RejectedPage()));
      await tester.pump();

      expect(find.text('Solicitud rechazada'), findsOneWidget);
      expect(
        find.textContaining('rechazada por el administrador'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    });

    testWidgets('muestra botón de cerrar sesión', (tester) async {
      await tester.pumpWidget(_buildPage(const RejectedPage()));
      await tester.pump();

      expect(find.text('Cerrar sesión'), findsOneWidget);
    });
  });
}
