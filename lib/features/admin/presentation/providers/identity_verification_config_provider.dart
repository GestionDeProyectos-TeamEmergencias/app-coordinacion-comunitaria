import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/identity_verification_config_remote_datasource.dart';
import '../../data/repositories/identity_verification_config_repository_impl.dart';
import '../../domain/entities/identity_verification_config.dart';
import '../../domain/repositories/identity_verification_config_repository.dart';

final _identityVerificationConfigDataSourceProvider =
    Provider<IdentityVerificationConfigRemoteDataSource>((ref) {
  return IdentityVerificationConfigRemoteDataSource(FirebaseFirestore.instance);
});

final identityVerificationConfigRepositoryProvider =
    Provider<IdentityVerificationConfigRepository>((ref) {
  return IdentityVerificationConfigRepositoryImpl(
    ref.watch(_identityVerificationConfigDataSourceProvider),
  );
});

final identityVerificationConfigProvider =
    StreamProvider<IdentityVerificationConfig>((ref) {
  return ref
      .watch(identityVerificationConfigRepositoryProvider)
      .watchConfig();
});

class UpdateIdentityVerificationConfigNotifier
    extends StateNotifier<AsyncValue<void>> {
  UpdateIdentityVerificationConfigNotifier(this._ref)
      : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> updateConfig(IdentityVerificationConfig config) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _ref
          .read(identityVerificationConfigRepositoryProvider)
          .updateConfig(config),
    );
  }
}

final updateIdentityVerificationConfigNotifierProvider = StateNotifierProvider<
    UpdateIdentityVerificationConfigNotifier, AsyncValue<void>>(
  (ref) => UpdateIdentityVerificationConfigNotifier(ref),
);
