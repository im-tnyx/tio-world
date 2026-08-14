import '../../domain/domain.dart';
import '../datasources/profile_setup_remote_data_source.dart';
import '../mappers/profile_setup_dto_mapper.dart';

/// Real remote implementation of [ProfileSetupRepository] using the backend onboarding API.
class RemoteProfileSetupRepository implements ProfileSetupRepository {
  const RemoteProfileSetupRepository({
    required ProfileSetupRemoteDataSource remoteDataSource,
    ProfileSetupDtoMapper mapper = const ProfileSetupDtoMapper(),
  })  : _remoteDataSource = remoteDataSource,
        _mapper = mapper;

  final ProfileSetupRemoteDataSource _remoteDataSource;
  final ProfileSetupDtoMapper _mapper;

  @override
  Future<void> saveProfileSetup(ProfileSetupData data) async {
    final payload = _mapper.toRequestPayload(data);
    await _remoteDataSource.saveProfileSetup(payload);
  }

  @override
  Future<ProfileSetupData?> getProfileSetup() async {
    // The onboarding draft endpoint is write-only in current product contracts.
    return null;
  }
}
