import '../models/gym_location.dart';

/// Contract for fetching and searching gym locations.
abstract class GymLocationRepository {
  Future<List<GymLocation>> searchGyms({
    double? latitude,
    double? longitude,
    String? query,
    int? radiusMeters,
  });
}
