import 'dart:async';

import 'package:app_coordinacion_comunitaria/core/constants/app_strings.dart';
import 'package:app_coordinacion_comunitaria/core/widgets/app_loading.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/domain/entities/incident_event.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/presentation/providers/incidents_provider.dart';
import 'package:app_coordinacion_comunitaria/features/map/presentation/pages/incident_location_map_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _incidentId = 'event-1';

void main() {
  group('buildDirectionsUri', () {
    test('arma una URL de direcciones de Google Maps a la coordenada', () {
      final uri = buildDirectionsUri(-34.5895, -60.9442);
      expect(uri.toString(), contains('google.com/maps/dir/'));
      expect(uri.toString(), contains('destination=-34.5895,-60.9442'));
    });
  });

  group('IncidentLocationMapPage', () {
    testWidgets('muestra el título y el loading mientras carga el incidente',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          // Stream sin emitir → estado loading (evita renderizar el platform
          // view de GoogleMap, igual que map_page_test).
          overrides: [
            incidentByIdProvider(_incidentId).overrideWith(
              (ref) => StreamController<IncidentEvent>().stream,
            ),
          ],
          child: const MaterialApp(
            home: IncidentLocationMapPage(incidentId: _incidentId),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(AppStrings.incidentLocationTitle), findsOneWidget);
      expect(find.byType(AppLoading), findsOneWidget);
    });
  });
}
