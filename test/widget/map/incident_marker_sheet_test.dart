import 'package:app_coordinacion_comunitaria/core/constants/app_strings.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/domain/entities/incident_event.dart';
import 'package:app_coordinacion_comunitaria/features/map/presentation/widgets/incident_marker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

IncidentEvent _incident({String? eventId = 'e1'}) {
  return IncidentEvent(
    eventId: eventId,
    userId: 'u1',
    timestamp: DateTime(2026, 1, 1),
    latitude: -34.6,
    longitude: -60.9,
    description: 'Bache profundo en la esquina',
    category: IncidentCategory.vial,
    sourceType: SourceType.quick,
    status: IncidentStatus.recibido,
    priority: IncidentPriority.alta,
  );
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('muestra resumen y botón "Ir al detalle" que dispara el callback',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(IncidentMarkerSheet(
      incident: _incident(),
      onOpenDetail: () => tapped = true,
    )));

    // Resumen: categoría, descripción, prioridad.
    expect(
        find.textContaining(IncidentCategory.vial.displayName), findsOneWidget);
    expect(find.text('Bache profundo en la esquina'), findsOneWidget);
    expect(
        find.textContaining(IncidentPriority.alta.displayName), findsWidgets);

    // Botón presente con el label correcto.
    final button = find.widgetWithText(FilledButton, AppStrings.goToDetail);
    expect(button, findsOneWidget);

    await tester.tap(button);
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('sin onOpenDetail (incidente sin id) no muestra el botón',
      (tester) async {
    await tester.pumpWidget(_wrap(IncidentMarkerSheet(
      incident: _incident(eventId: null),
      onOpenDetail: null,
    )));

    expect(find.text(AppStrings.goToDetail), findsNothing);
  });
}
