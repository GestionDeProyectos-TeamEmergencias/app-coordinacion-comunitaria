import 'dart:typed_data';

import 'package:app_coordinacion_comunitaria/core/errors/app_exception.dart';
import 'package:app_coordinacion_comunitaria/features/auth/data/services/identity_proof_uploader.dart';
import 'package:app_coordinacion_comunitaria/features/auth/presentation/providers/identity_proof_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeUploader implements IdentityProofUploader {
  String? lastUserId;
  Uint8List? lastBytes;
  String? lastFileName;
  String returnedUrl = 'https://example.com/proof.jpg';
  Object? error;

  @override
  Future<String> uploadProof({
    required String userId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (error != null) throw error!;
    lastUserId = userId;
    lastBytes = bytes;
    lastFileName = fileName;
    return returnedUrl;
  }
}

void main() {
  group('IdentityProofNotifier', () {
    test('reenvía userId, bytes y fileName al uploader y guarda la URL',
        () async {
      final fake = _FakeUploader()..returnedUrl = 'https://cdn/proof.png';
      final container = ProviderContainer(overrides: [
        identityProofUploaderProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      await container.read(identityProofNotifierProvider.notifier).upload(
            userId: 'uid-1',
            bytes: bytes,
            fileName: 'comprobante.jpg',
          );

      expect(fake.lastUserId, 'uid-1');
      expect(fake.lastBytes, bytes);
      expect(fake.lastFileName, 'comprobante.jpg');
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

      await container.read(identityProofNotifierProvider.notifier).upload(
            userId: 'uid-2',
            bytes: Uint8List.fromList([0]),
            fileName: 'foo.png',
          );

      final state = container.read(identityProofNotifierProvider);
      expect(state.hasError, isTrue);
      expect(state.error.toString(), contains('storage caído'));
    });
  });
}
