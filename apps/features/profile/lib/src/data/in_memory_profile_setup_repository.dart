import '../domain/models/profile_setup_data.dart';
import '../domain/repositories/profile_setup_repository.dart';

/// Thread-safe in-memory implementation of [ProfileSetupRepository].
class InMemoryProfileSetupRepository implements ProfileSetupRepository {
  InMemoryProfileSetupRepository({ProfileSetupData? initialData})
      : _data = initialData;

  ProfileSetupData? _data;

  @override
  Future<void> saveProfileSetup(ProfileSetupData data) async {
    _data = data;
  }

  @override
  Future<ProfileSetupData?> getProfileSetup() async {
    return _data;
  }
}
