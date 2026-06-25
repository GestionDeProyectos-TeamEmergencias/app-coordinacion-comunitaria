import 'package:app_coordinacion_comunitaria/features/admin/domain/entities/coverage_config.dart';
import 'package:app_coordinacion_comunitaria/features/admin/presentation/providers/coverage_config_provider.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/presentation/providers/location_picker_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const _coverage = CoverageConfig(
  centerLat: -34.6037,
  centerLng: -58.3816,
  radiusMeters: 5000,
);
const _inside = LatLng(-34.6037, -58.3816); // centro exacto
const _outside = LatLng(51.5, -0.12); // Londres

ProviderContainer _container({required GpsFetcher gps}) {
  return ProviderContainer(
    overrides: [
      gpsFetcherProvider.overrideWithValue(gps),
      coverageConfigProvider.overrideWith((_) => Stream.value(_coverage)),
    ],
  );
}

void main() {
  group('LocationPickerNotifier', () {
    test('loadGps setea selected y gpsCurrent al mismo valor', () async {
      final container = _container(gps: () async => _inside);
      addTearDown(container.dispose);

      await container.read(locationPickerProvider.notifier).loadGps();

      final state = container.read(locationPickerProvider);
      expect(state.selected, _inside);
      expect(state.gpsCurrent, _inside);
      expect(state.isLoadingGps, isFalse);
      expect(state.gpsError, isNull);
    });

    test('setManual cambia solo selected — gpsCurrent queda fijo', () async {
      final container = _container(gps: () async => _inside);
      addTearDown(container.dispose);

      await container.read(locationPickerProvider.notifier).loadGps();
      container.read(locationPickerProvider.notifier).setManual(_outside);

      final state = container.read(locationPickerProvider);
      expect(state.selected, _outside);
      expect(state.gpsCurrent, _inside);
    });

    test('resetToGps devuelve selected al último GPS conocido', () async {
      final container = _container(gps: () async => _inside);
      addTearDown(container.dispose);

      await container.read(locationPickerProvider.notifier).loadGps();
      container.read(locationPickerProvider.notifier).setManual(_outside);
      container.read(locationPickerProvider.notifier).resetToGps();

      expect(container.read(locationPickerProvider).selected, _inside);
    });

    test('resetToGps es no-op si nunca cargó el GPS', () {
      final container = _container(gps: () async => _inside);
      addTearDown(container.dispose);

      container.read(locationPickerProvider.notifier).resetToGps();

      expect(container.read(locationPickerProvider).selected, isNull);
    });

    test('error del GPS expone mensaje pero deja al user fijar manualmente',
        () async {
      final container = _container(gps: () async => throw Exception('boom'));
      addTearDown(container.dispose);

      await container.read(locationPickerProvider.notifier).loadGps();
      container.read(locationPickerProvider.notifier).setManual(_inside);

      final state = container.read(locationPickerProvider);
      expect(state.gpsError, isNotNull);
      expect(state.selected, _inside);
    });
  });

  group('selectedLocationIsWithinCoverageProvider', () {
    test('null cuando no hay selección', () {
      final container = _container(gps: () async => _inside);
      addTearDown(container.dispose);

      // Forzar lectura de coverageConfig antes de evaluar.
      container.read(coverageConfigProvider);
      expect(
        container.read(selectedLocationIsWithinCoverageProvider),
        isNull,
      );
    });

    test('true cuando la selección cae dentro del radio', () async {
      final container = _container(gps: () async => _inside);
      addTearDown(container.dispose);

      await container.read(coverageConfigProvider.future);
      await container.read(locationPickerProvider.notifier).loadGps();

      expect(
        container.read(selectedLocationIsWithinCoverageProvider),
        isTrue,
      );
    });

    test('false cuando la selección cae fuera', () async {
      final container = _container(gps: () async => _inside);
      addTearDown(container.dispose);

      await container.read(coverageConfigProvider.future);
      await container.read(locationPickerProvider.notifier).loadGps();
      container.read(locationPickerProvider.notifier).setManual(_outside);

      expect(
        container.read(selectedLocationIsWithinCoverageProvider),
        isFalse,
      );
    });
  });
}
