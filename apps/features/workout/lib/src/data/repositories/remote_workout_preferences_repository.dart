import '../../domain/domain.dart';
import '../datasources/workout_preferences_remote_data_source.dart';
import '../mappers/workout_preferences_dto_mapper.dart';

/// Real remote implementation of [WorkoutPreferencesRepository] using the backend onboarding API.
class RemoteWorkoutPreferencesRepository
    implements WorkoutPreferencesRepository {
  const RemoteWorkoutPreferencesRepository({
    required WorkoutPreferencesRemoteDataSource remoteDataSource,
    WorkoutPreferencesDtoMapper mapper = const WorkoutPreferencesDtoMapper(),
  })  : _remoteDataSource = remoteDataSource,
        _mapper = mapper;

  final WorkoutPreferencesRemoteDataSource _remoteDataSource;
  final WorkoutPreferencesDtoMapper _mapper;

  @override
  Future<void> saveWorkoutPreferences(WorkoutPreferencesData data) async {
    final payload = _mapper.toRequestPayload(data);
    await _remoteDataSource.saveWorkoutPreferences(payload);
  }

  @override
  Future<WorkoutPreferencesData?> getWorkoutPreferences() async {
    // Onboarding draft endpoint is write-only in current product contracts.
    return null;
  }
}
