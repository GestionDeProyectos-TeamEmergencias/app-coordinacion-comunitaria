import 'dart:async';

import 'package:app_coordinacion_comunitaria/features/admin/domain/entities/identity_verification_config.dart';
import 'package:app_coordinacion_comunitaria/features/admin/domain/repositories/identity_verification_config_repository.dart';
import 'package:app_coordinacion_comunitaria/features/admin/presentation/providers/identity_verification_config_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements IdentityVerificationConfigRepository {
  IdentityVerificationConfig? lastUpdated;
  Object? error;
  final _controller = StreamController<IdentityVerificationConfig>.broadcast();

  void emit(IdentityVerificationConfig config) => _controller.add(config);

  @override
  Stream<IdentityVerificationConfig> watchConfig() => _controller.stream;

  @override
  Future<void> updateConfig(IdentityVerificationConfig config) async {
    if (error != null) throw error!;
    lastUpdated = config;
  }
}

void main() {
  group('IdentityVerificationMode', () {
    test('fromString respeta los valores válidos y default a manual', () {
      expect(IdentityVerificationMode.fromString('manual'),
          IdentityVerificationMode.manual);
      expect(IdentityVerificationMode.fromString('proof_upload'),
          IdentityVerificationMode.proofUpload);
      // Valores inválidos caen al modo manual (más conservador).
      expect(IdentityVerificationMode.fromString('truora'),
          IdentityVerificationMode.manual);
      expect(IdentityVerificationMode.fromString(''),
          IdentityVerificationMode.manual);
    });

    test('firestoreValue es estable para round-trip', () {
      for (final mode in IdentityVerificationMode.values) {
        expect(
          IdentityVerificationMode.fromString(mode.firestoreValue),
          mode,
        );
      }
    });

    test('requiresProof solo es true para proofUpload', () {
      expect(IdentityVerificationMode.manual.requiresProof, isFalse);
      expect(IdentityVerificationMode.proofUpload.requiresProof, isTrue);
    });
  });

  group('UpdateIdentityVerificationConfigNotifier', () {
    test('persiste la config en el repositorio en caso de éxito', () async {
      final fake = _FakeRepo();
      final container = ProviderContainer(overrides: [
        identityVerificationConfigRepositoryProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      const config = IdentityVerificationConfig(
        mode: IdentityVerificationMode.proofUpload,
      );

      await container
          .read(updateIdentityVerificationConfigNotifierProvider.notifier)
          .updateConfig(config);

      expect(fake.lastUpdated, equals(config));
      expect(
        container
            .read(updateIdentityVerificationConfigNotifierProvider)
            .hasError,
        isFalse,
      );
    });

    test('expone error cuando falla el repositorio', () async {
      final fake = _FakeRepo()..error = Exception('boom');
      final container = ProviderContainer(overrides: [
        identityVerificationConfigRepositoryProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      await container
          .read(updateIdentityVerificationConfigNotifierProvider.notifier)
          .updateConfig(IdentityVerificationConfig.defaults);

      final state =
          container.read(updateIdentityVerificationConfigNotifierProvider);
      expect(state.hasError, isTrue);
      expect(state.error.toString(), contains('boom'));
    });
  });
}
