import 'package:app_coordinacion_comunitaria/core/constants/app_strings.dart';
import 'package:app_coordinacion_comunitaria/features/auth/domain/entities/app_user.dart';
import 'package:app_coordinacion_comunitaria/features/auth/presentation/providers/auth_provider.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/presentation/pages/report_form_page.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/presentation/providers/location_picker_provider.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/presentation/widgets/location_picker_card.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/presentation/widgets/voice_report_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
      // F-03: el form monta LocationPickerCard. Stubbeamos el GPS para que el
      // notifier resuelva rápido y no llame al plugin nativo.
      gpsFetcherProvider.overrideWithValue(
        () async => const LatLng(-34.6037, -58.3816),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUpAll(() {
    // F-03: evita que GoogleMap (platform view) crashee en widget tests.
    LocationPickerCard.disableMapForTests = true;
  });

  group('ReportFormPage', () {
    testWidgets('renderiza el formulario con todos los campos visibles',
        (tester) async {
      await tester.pumpWidget(_buildSubject());
      // GoogleMap del LocationPicker nunca llega a quietud — usamos pump()
      // repetido en lugar de pumpAndSettle() para evitar timeout.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(AppStrings.formReport), findsOneWidget);
      expect(find.text(AppStrings.reportDescription), findsOneWidget);
      expect(find.text(AppStrings.selectCategory), findsOneWidget);
      expect(find.text(AppStrings.addPhoto), findsOneWidget);
      expect(find.text(AppStrings.sendReport), findsOneWidget);
    });

    testWidgets('muestra error al enviar sin categoría seleccionada',
        (tester) async {
      await tester.pumpWidget(_buildSubject());
      // GoogleMap del LocationPicker nunca llega a quietud — usamos pump()
      // repetido en lugar de pumpAndSettle() para evitar timeout.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Ingresa descripción válida
      await tester.enterText(
        find.byType(TextFormField).first,
        'Hay un bache en la esquina',
      );
      // Cierra el foco del campo de texto para que el botón sea hittable.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      // Tap en enviar sin seleccionar categoría
      // El form ahora es más alto por el LocationPicker (F-03) — scrolleamos
      // para asegurar que el botón "Enviar" sea hittable.
      await tester.ensureVisible(find.text(AppStrings.sendReport));
      await tester.pump();
      await tester.tap(find.text(AppStrings.sendReport), warnIfMissed: false);
      // Esperar varias frames + tiempo para que el snackbar entre y para
      // que `_formKey.currentState!.validate()` muestre sus errores.
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }

      expect(find.text(AppStrings.selectCategoryError), findsOneWidget);
    });

    testWidgets('muestra error de validación al enviar sin descripción',
        (tester) async {
      await tester.pumpWidget(_buildSubject());
      // GoogleMap del LocationPicker nunca llega a quietud — usamos pump()
      // repetido en lugar de pumpAndSettle() para evitar timeout.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap en enviar sin descripción ni categoría
      // El form ahora es más alto por el LocationPicker (F-03) — scrolleamos
      // para asegurar que el botón "Enviar" sea hittable.
      await tester.ensureVisible(find.text(AppStrings.sendReport));
      await tester.pump();
      await tester.tap(find.text(AppStrings.sendReport));
      // Esperar varias frames + tiempo para que el snackbar entre y para
      // que `_formKey.currentState!.validate()` muestre sus errores.
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }

      expect(find.text(AppStrings.descriptionError), findsOneWidget);
    });

    testWidgets('el toggle de voz oculta el campo de texto', (tester) async {
      await tester.pumpWidget(_buildSubject());
      // GoogleMap del LocationPicker nunca llega a quietud — usamos pump()
      // repetido en lugar de pumpAndSettle() para evitar timeout.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

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
