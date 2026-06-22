import '../../domain/entities/coverage_config.dart';
import '../../domain/repositories/coverage_config_repository.dart';
import '../datasources/coverage_config_remote_datasource.dart';

class CoverageConfigRepositoryImpl implements CoverageConfigRepository {
  CoverageConfigRepositoryImpl(this._dataSource);

  final CoverageConfigRemoteDataSource _dataSource;

  @override
  Stream<CoverageConfig> watchCoverageConfig() {
    return _dataSource.watchCoverageConfig();
  }

  @override
  Future<void> updateCoverageConfig(CoverageConfig config) {
    return _dataSource.updateCoverageConfig(config);
  }
}
