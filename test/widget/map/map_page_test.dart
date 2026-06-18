import 'dart:async';

import 'package:app_coordinacion_comunitaria/core/constants/app_strings.dart';
import 'package:app_coordinacion_comunitaria/core/widgets/app_loading.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/domain/entities/incident_event.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/presentation/providers/incidents_provider.dart';
import 'package:app_coordinacion_comunitaria/features/map/presentation/pages/map_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: const MaterialApp(home: MapPage()),
    );

List<Override> _loadingOverride() => [
      activeIncidentsStreamProvider.overrideWith(
        (ref) => StreamController<List<IncidentEvent>>().stream,
      ),
    ];

void main() {
  group('MapPage', () {
    testWidgets('muestra AppLoading mientras se cargan los incidentes',
        (tester) async {
      await tester.pumpWidget(_wrap(_loadingOverride()));
      await tester.pump();

      expect(find.byType(AppLoading), findsOneWidget);
    });

    testWidgets('muestra mensaje de error cuando falla el stream',
        (tester) async {
      await tester.pumpWidget(
        _wrap([
          activeIncidentsStreamProvider.overrideWith(
            (ref) => Stream<List<IncidentEvent>>.error('Sin conexión'),
          ),
        ]),
      );
      await tester.pump();

      expect(find.textContaining('Error:'), findsOneWidget);
    });

    testWidgets('muestra el botón de leyenda con el texto correcto',
        (tester) async {
      await tester.pumpWidget(_wrap(_loadingOverride()));
      await tester.pump();

      expect(find.text(AppStrings.mapLegend), findsOneWidget);
    });

    testWidgets(
        'al tocar el botón de leyenda se muestra la hoja con prioridades y categorías',
        (tester) async {
      await tester.pumpWidget(_wrap(_loadingOverride()));
      await tester.pump();

      await tester.tap(find.text(AppStrings.mapLegend));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(AppStrings.mapLegendTitle), findsOneWidget);
      expect(find.text(AppStrings.priorityUrgent), findsOneWidget);
      expect(find.text(AppStrings.mapCategoryFilters), findsOneWidget);
    });

    testWidgets('expone botón para recentrar el mapa en el área de cobertura',
        (tester) async {
      await tester.pumpWidget(_wrap(_loadingOverride()));
      await tester.pump();

      expect(
        find.byTooltip(AppStrings.mapRecenter),
        findsOneWidget,
      );
    });
  });
}
