import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/coverage_config_remote_datasource.dart';
import '../../data/repositories/coverage_config_repository_impl.dart';
import '../../domain/entities/coverage_config.dart';
import '../../domain/repositories/coverage_config_repository.dart';

final _coverageConfigDataSourceProvider =
    Provider<CoverageConfigRemoteDataSource>((ref) {
  return CoverageConfigRemoteDataSource(FirebaseFirestore.instance);
});

final coverageConfigRepositoryProvider =
    Provider<CoverageConfigRepository>((ref) {
  return CoverageConfigRepositoryImpl(
      ref.watch(_coverageConfigDataSourceProvider));
});

final coverageConfigProvider = StreamProvider<CoverageConfig>((ref) {
  return ref.watch(coverageConfigRepositoryProvider).watchCoverageConfig();
});

class UpdateCoverageNotifier extends StateNotifier<AsyncValue<void>> {
  UpdateCoverageNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> updateConfig(CoverageConfig config) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _ref
          .read(coverageConfigRepositoryProvider)
          .updateCoverageConfig(config),
    );
  }
}

final updateCoverageNotifierProvider =
    StateNotifierProvider<UpdateCoverageNotifier, AsyncValue<void>>(
  (ref) => UpdateCoverageNotifier(ref),
);
