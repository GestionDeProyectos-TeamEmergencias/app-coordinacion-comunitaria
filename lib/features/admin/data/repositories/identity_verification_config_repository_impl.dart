import '../../domain/entities/identity_verification_config.dart';
import '../../domain/repositories/identity_verification_config_repository.dart';
import '../datasources/identity_verification_config_remote_datasource.dart';

class IdentityVerificationConfigRepositoryImpl
    implements IdentityVerificationConfigRepository {
  const IdentityVerificationConfigRepositoryImpl(this._dataSource);

  final IdentityVerificationConfigRemoteDataSource _dataSource;

  @override
  Stream<IdentityVerificationConfig> watchConfig() => _dataSource.watchConfig();

  @override
  Future<void> updateConfig(IdentityVerificationConfig config) =>
      _dataSource.updateConfig(config);
}
