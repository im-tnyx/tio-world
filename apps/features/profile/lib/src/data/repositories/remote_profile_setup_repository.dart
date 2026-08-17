import 'package:tio_core/core.dart';

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
  Future<void> updateMeasurementUnitPreferences(
    MeasurementUnitPreferences preferences,
  ) async {
    throw UnsupportedError(
      'Field-specific measurement unit updates require the authenticated profile repository.',
    );
  }

  @override
  Future<ProfileSetupData?> getProfileSetup() async {
    // The onboarding draft endpoint is write-only in current product contracts.
    return null;
  }

  @override
  Stream<ProfileSetupData?> watchProfileSetup() => Stream.value(null);

  @override
  Future<String> uploadAvatarImage({
    required String fileName,
    required List<int> bytes,
  }) async {
    return '';
  }

  @override
  Future<void> deleteAvatarImage() async {}

  @override
  Future<void> updateAvatarFrame(String frame) async {}
}
