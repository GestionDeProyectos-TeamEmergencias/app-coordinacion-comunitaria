import 'package:app_coordinacion_comunitaria/core/constants/app_strings.dart';
import 'package:app_coordinacion_comunitaria/features/auth/domain/entities/app_user.dart';
import 'package:app_coordinacion_comunitaria/features/auth/presentation/providers/auth_provider.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/presentation/providers/incidents_provider.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/presentation/widgets/quick_report_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _activeUser = AppUser(
  userId: 'uid-test',
  email: 'test@test.com',
  displayName: 'Test User',
  role: UserRole.vecinoInformante,
  status: UserStatus.active,
);

// Notifier stub que arranca en estado loading para el test del spinner.
class _StubLoadingNotifier extends ReportNotifier {
  _StubLoadingNotifier(super.ref) {
    state = const AsyncValue.loading();
  }
}

Widget _buildSubject({AppUser? user}) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((_) => Stream.value(user)),
    ],
    child: const MaterialApp(
      home: Scaffold(body: QuickReportButton()),
    ),
  );
}

void main() {
  group('QuickReportButton', () {
    testWidgets('muestra el botón habilitado cuando hay usuario activo',
        (tester) async {
      await tester.pumpWidget(_buildSubject(user: _activeUser));
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
      expect(find.text(AppStrings.quickReport), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('muestra el botón deshabilitado cuando no hay usuario',
        (tester) async {
      await tester.pumpWidget(_buildSubject(user: null));
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('muestra spinner y deshabilita el botón durante el loading',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((_) => Stream.value(_activeUser)),
            reportNotifierProvider.overrideWith(
              (ref) => _StubLoadingNotifier(ref),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: QuickReportButton()),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });
  });
}
