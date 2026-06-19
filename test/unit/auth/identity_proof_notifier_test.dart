import 'dart:io';

import 'package:app_coordinacion_comunitaria/core/errors/app_exception.dart';
import 'package:app_coordinacion_comunitaria/features/auth/data/services/identity_proof_uploader.dart';
import 'package:app_coordinacion_comunitaria/features/auth/presentation/providers/identity_proof_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeUploader implements IdentityProofUploader {
  String? lastUserId;
  File? lastPhoto;
  String returnedUrl = 'https://example.com/proof.jpg';
  Object? error;

  @override
  Future<String> uploadProof({
    required String userId,
    required File photo,
  }) async {
    if (error != null) throw error!;
    lastUserId = userId;
    lastPhoto = photo;
    return returnedUrl;
  }
}

void main() {
  group('IdentityProofNotifier', () {
    test('reenvía userId y archivo al uploader y guarda la URL en el estado',
        () async {
      final fake = _FakeUploader()..returnedUrl = 'https://cdn/proof.png';
      final container = ProviderContainer(overrides: [
        identityProofUploaderProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      final photo = File('dummy.jpg');
      await container
          .read(identityProofNotifierProvider.notifier)
          .upload(userId: 'uid-1', photo: photo);

      expect(fake.lastUserId, 'uid-1');
      expect(fake.lastPhoto?.path, photo.path);
      expect(
        container.read(identityProofNotifierProvider).valueOrNull,
        'https://cdn/proof.png',
      );
    });

    test('propaga StorageException al estado de error', () async {
      final fake = _FakeUploader()
        ..error = const StorageException('storage caído');
      final container = ProviderContainer(overrides: [
        identityProofUploaderProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      await container
          .read(identityProofNotifierProvider.notifier)
          .upload(userId: 'uid-2', photo: File('foo.png'));

      final state = container.read(identityProofNotifierProvider);
      expect(state.hasError, isTrue);
      expect(state.error.toString(), contains('storage caído'));
    });
  });
}
