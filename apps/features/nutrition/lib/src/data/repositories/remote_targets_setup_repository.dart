import '../../domain/domain.dart';
import '../datasources/targets_setup_remote_data_source.dart';
import '../mappers/targets_setup_dto_mapper.dart';

/// Real remote implementation of [TargetsSetupRepository] using the backend onboarding API.
class RemoteTargetsSetupRepository implements TargetsSetupRepository {
  const RemoteTargetsSetupRepository({
    required TargetsSetupRemoteDataSource remoteDataSource,
    TargetsSetupDtoMapper mapper = const TargetsSetupDtoMapper(),
    this.targetWeightResolver,
  })  : _remoteDataSource = remoteDataSource,
        _mapper = mapper;

  final TargetsSetupRemoteDataSource _remoteDataSource;
  final TargetsSetupDtoMapper _mapper;
  final double? Function()? targetWeightResolver;

  @override
  Future<void> saveTargetsSetup(TargetsSetupData data) async {
    final targetWeight = targetWeightResolver?.call();
    final payload = _mapper.toRequestPayload(
      data,
      fallbackTargetWeightKg: targetWeight,
    );
    await _remoteDataSource.saveTargetsSetup(payload);
  }

  @override
  Future<TargetsSetupData?> getTargetsSetup() async {
    // Onboarding draft endpoint is write-only in current product contracts.
    return null;
  }
}
