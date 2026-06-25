import 'package:app_coordinacion_comunitaria/features/incidents/domain/entities/incident_event.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/presentation/pages/my_reports_page.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/presentation/providers/my_incidents_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

IncidentEvent _incident({
  required String id,
  required IncidentStatus status,
  String? description,
}) =>
    IncidentEvent(
      eventId: id,
      userId: 'me',
      timestamp: DateTime(2026, 6, 24),
      latitude: -34.6,
      longitude: -58.3,
      sourceType: SourceType.form,
      description: description,
      status: status,
    );

Widget _wrap({required List<IncidentEvent> incidents}) {
  return ProviderScope(
    overrides: [
      myIncidentsStreamProvider.overrideWith((_) => Stream.value(incidents)),
    ],
    child: const MaterialApp(home: MyReportsPage()),
  );
}

void main() {
  testWidgets('estado vacío muestra mensaje', (tester) async {
    await tester.pumpWidget(_wrap(incidents: const []));
    await tester.pump();
    expect(find.text('Todavía no enviaste reportes.'), findsOneWidget);
  });

  testWidgets('reporte en recibido se muestra con ícono editable',
      (tester) async {
    await tester.pumpWidget(_wrap(incidents: [
      _incident(
        id: 'r-1',
        status: IncidentStatus.recibido,
        description: 'Bache en Belgrano',
      ),
    ]));
    await tester.pump();

    expect(find.text('Bache en Belgrano'), findsOneWidget);
    expect(find.byIcon(Icons.edit_note), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
  });

  testWidgets('reporte ya procesado se muestra con ícono lock', (tester) async {
    await tester.pumpWidget(_wrap(incidents: [
      _incident(
        id: 'r-2',
        status: IncidentStatus.solucionado,
        description: 'Bache reparado',
      ),
    ]));
    await tester.pump();

    expect(find.text('Bache reparado'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.byIcon(Icons.edit_note), findsNothing);
  });

  testWidgets('lista ordena items independientes en filas separadas',
      (tester) async {
    await tester.pumpWidget(_wrap(incidents: [
      _incident(id: 'a', status: IncidentStatus.recibido, description: 'A'),
      _incident(id: 'b', status: IncidentStatus.programado, description: 'B'),
      _incident(id: 'c', status: IncidentStatus.solucionado, description: 'C'),
    ]));
    await tester.pump();

    expect(find.byType(ListTile), findsNWidgets(3));
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
  });
}
