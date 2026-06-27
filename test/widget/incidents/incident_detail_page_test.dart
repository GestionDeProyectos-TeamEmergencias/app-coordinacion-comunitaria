import 'package:app_coordinacion_comunitaria/core/constants/app_strings.dart';
import 'package:app_coordinacion_comunitaria/features/auth/domain/entities/app_user.dart';
import 'package:app_coordinacion_comunitaria/features/auth/presentation/providers/auth_provider.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/domain/entities/incident_event.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/presentation/pages/incident_detail_page.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/presentation/providers/incidents_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _incidentId = 'event-1';

IncidentEvent _buildIncident({
  IncidentStatus status = IncidentStatus.recibido,
  List<IncidentStatusChange> history = const [],
}) {
  return IncidentEvent(
    eventId: _incidentId,
    userId: 'uid-reporter',
    timestamp: DateTime(2026, 6, 17, 10, 30),
    latitude: -34.5895,
    longitude: -60.9442,
    description: 'Bache grande en la esquina',
    category: IncidentCategory.vial,
    sourceType: SourceType.form,
    status: status,
    statusHistory: history,
  );
}

AppUser _buildUser(UserRole role) => AppUser(
      userId: 'uid-current',
      email: 'user@test.com',
      displayName: 'Test User',
      role: role,
      status: UserStatus.active,
    );

Widget _wrap({
  required IncidentEvent incident,
  required UserRole currentUserRole,
}) {
  return ProviderScope(
    overrides: [
      incidentByIdProvider(_incidentId)
          .overrideWith((ref) => Stream.value(incident)),
      authStateProvider.overrideWith(
        (ref) => Stream.value(_buildUser(currentUserRole)),
      ),
    ],
    child: const MaterialApp(
      home: IncidentDetailPage(incidentId: _incidentId),
    ),
  );
}

void main() {
  group('IncidentDetailPage', () {
    testWidgets('muestra el estado actual del incidente', (tester) async {
      await tester.pumpWidget(_wrap(
        incident: _buildIncident(status: IncidentStatus.programado),
        currentUserRole: UserRole.vecinoInformante,
      ));
      await tester.pump();

      expect(find.text(IncidentStatus.programado.displayName), findsWidgets);
    });

    testWidgets(
        'muestra el histórico de cambios con timestamps cuando hay historial',
        (tester) async {
      final history = [
        IncidentStatusChange(
          status: IncidentStatus.recibido,
          timestamp: DateTime(2026, 6, 17, 9, 0),
        ),
        IncidentStatusChange(
          status: IncidentStatus.programado,
          timestamp: DateTime(2026, 6, 17, 10, 15),
          changedBy: 'admin-uid',
        ),
      ];
      await tester.pumpWidget(_wrap(
        incident: _buildIncident(
          status: IncidentStatus.programado,
          history: history,
        ),
        currentUserRole: UserRole.vecinoInformante,
      ));
      await tester.pump();

      expect(find.text(AppStrings.statusHistoryTitle), findsOneWidget);
      expect(find.text('17/06/2026 09:00'), findsOneWidget);
      expect(find.text('17/06/2026 10:15'), findsOneWidget);
    });

    testWidgets('muestra mensaje cuando el historial está vacío',
        (tester) async {
      await tester.pumpWidget(_wrap(
        incident: _buildIncident(),
        currentUserRole: UserRole.vecinoInformante,
      ));
      await tester.pump();

      expect(find.text(AppStrings.statusHistoryEmpty), findsOneWidget);
    });

    testWidgets(
        'oculta el selector de estado para vecinos informantes sin permisos',
        (tester) async {
      await tester.pumpWidget(_wrap(
        incident: _buildIncident(),
        currentUserRole: UserRole.vecinoInformante,
      ));
      await tester.pump();

      expect(find.text(AppStrings.updateStatusTitle), findsNothing);
    });

    // El admin gestiona todas las transiciones del ciclo de vida.
    testWidgets('muestra el selector de estado para administradores',
        (tester) async {
      await tester.pumpWidget(_wrap(
        incident: _buildIncident(),
        currentUserRole: UserRole.administrador,
      ));
      await tester.pump();

      expect(find.text(AppStrings.updateStatusTitle), findsOneWidget);
      expect(
          find.byType(DropdownButtonFormField<IncidentStatus>), findsOneWidget);
    });

    // F-06: el referente ahora también puede cerrar con evidencia, así que ve
    // el selector de estado (limitado a "Solucionado"), además de su bloque de
    // verificación de campo.
    testWidgets('muestra el selector de estado para referentes barriales',
        (tester) async {
      await tester.pumpWidget(_wrap(
        incident: _buildIncident(),
        currentUserRole: UserRole.referenteBarrial,
      ));
      await tester.pump();

      expect(find.text(AppStrings.updateStatusTitle), findsOneWidget);
      expect(
          find.byType(DropdownButtonFormField<IncidentStatus>), findsOneWidget);
    });
  });
}
