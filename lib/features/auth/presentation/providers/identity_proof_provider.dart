import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/identity_proof_uploader.dart';

final identityProofUploaderProvider = Provider<IdentityProofUploader>(
  (ref) => IdentityProofUploader(),
);

class IdentityProofNotifier extends StateNotifier<AsyncValue<String?>> {
  IdentityProofNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> upload({required String userId, required File photo}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _ref
          .read(identityProofUploaderProvider)
          .uploadProof(userId: userId, photo: photo),
    );
  }
}

final identityProofNotifierProvider =
    StateNotifierProvider<IdentityProofNotifier, AsyncValue<String?>>(
  (ref) => IdentityProofNotifier(ref),
);
