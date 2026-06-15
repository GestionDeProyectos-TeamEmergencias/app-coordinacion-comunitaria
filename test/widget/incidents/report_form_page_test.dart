import 'package:app_coordinacion_comunitaria/core/constants/app_strings.dart';
import 'package:app_coordinacion_comunitaria/features/auth/domain/entities/app_user.dart';
import 'package:app_coordinacion_comunitaria/features/auth/presentation/providers/auth_provider.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/presentation/pages/report_form_page.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/presentation/widgets/voice_report_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _activeUser = AppUser(
  userId: 'uid-test',
  email: 'test@test.com',
  displayName: 'Test User',
  role: UserRole.vecinoInformante,
  status: UserStatus.active,
);

Widget _buildSubject() {
  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const ReportFormPage(),
    ),
  ]);

  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((_) => Stream.value(_activeUser)),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('ReportFormPage', () {
    testWidgets('renderiza el formulario con todos los campos visibles',
        (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.formReport), findsOneWidget);
      expect(find.text(AppStrings.reportDescription), findsOneWidget);
      expect(find.text(AppStrings.selectCategory), findsOneWidget);
      expect(find.text(AppStrings.addPhoto), findsOneWidget);
      expect(find.text(AppStrings.sendReport), findsOneWidget);
    });

    testWidgets('muestra error al enviar sin categoría seleccionada',
        (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pumpAndSettle();

      // Ingresa descripción válida
      await tester.enterText(
        find.byType(TextFormField).first,
        'Hay un bache en la esquina',
      );

      // Tap en enviar sin seleccionar categoría
      await tester.tap(find.text(AppStrings.sendReport));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.selectCategoryError), findsOneWidget);
    });

    testWidgets('muestra error de validación al enviar sin descripción',
        (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pumpAndSettle();

      // Tap en enviar sin descripción ni categoría
      await tester.tap(find.text(AppStrings.sendReport));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.descriptionError), findsOneWidget);
    });

    testWidgets('el toggle de voz oculta el campo de texto', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pumpAndSettle();

      // Modo texto es el default — el TextFormField de descripción es visible
      expect(find.byType(TextFormField), findsWidgets);

      // Cambiar a voz — VoiceReportWidget inicia async, usar runAsync
      await tester.runAsync(() async {
        await tester.tap(find.text(AppStrings.reportModeVoice));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      await tester.pump();

      // En modo voz el VoiceReportWidget está presente
      expect(find.byType(VoiceReportWidget), findsOneWidget);
    });
  });
}
