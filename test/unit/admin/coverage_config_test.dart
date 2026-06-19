import 'dart:async';

import 'package:app_coordinacion_comunitaria/features/admin/domain/entities/coverage_config.dart';
import 'package:app_coordinacion_comunitaria/features/admin/domain/repositories/coverage_config_repository.dart';
import 'package:app_coordinacion_comunitaria/features/admin/presentation/providers/coverage_config_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements CoverageConfigRepository {
  CoverageConfig? lastUpdated;
  Object? error;
  final _controller = StreamController<CoverageConfig>.broadcast();

  void emit(CoverageConfig config) => _controller.add(config);

  @override
  Stream<CoverageConfig> watchCoverageConfig() => _controller.stream;

  @override
  Future<void> updateCoverageConfig(CoverageConfig config) async {
    if (error != null) throw error!;
    lastUpdated = config;
  }
}

void main() {
  group('CoverageConfig entity', () {
    test('isWithinCoverage inclusivo en el borde y exterior fuera', () {
      const center = CoverageConfig(
        centerLat: -34.5895,
        centerLng: -60.9442,
        radiusMeters: 5000,
      );

      // Centro exacto → dentro
      expect(center.isWithinCoverage(-34.5895, -60.9442), isTrue);

      // ~10 km al norte → fuera
      expect(center.isWithinCoverage(-34.4995, -60.9442), isFalse);
    });
  });

  group('UpdateCoverageNotifier', () {
    test('persiste la config en el repositorio en caso de éxito', () async {
      final fake = _FakeRepo();
      final container = ProviderContainer(overrides: [
        coverageConfigRepositoryProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      const config = CoverageConfig(
        centerLat: -34.5,
        centerLng: -60.9,
        radiusMeters: 7500,
      );

      await container
          .read(updateCoverageNotifierProvider.notifier)
          .updateConfig(config);

      expect(fake.lastUpdated, equals(config));
      expect(container.read(updateCoverageNotifierProvider).hasError, isFalse);
    });

    test('expone error cuando falla el repositorio', () async {
      final fake = _FakeRepo()..error = Exception('boom');
      final container = ProviderContainer(overrides: [
        coverageConfigRepositoryProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      await container
          .read(updateCoverageNotifierProvider.notifier)
          .updateConfig(CoverageConfig.defaults);

      final state = container.read(updateCoverageNotifierProvider);
      expect(state.hasError, isTrue);
      expect(state.error.toString(), contains('boom'));
    });
  });
}
