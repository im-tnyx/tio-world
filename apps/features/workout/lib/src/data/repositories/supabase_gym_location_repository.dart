import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/gym_location.dart';
import '../../domain/repositories/gym_location_repository.dart';

/// Supabase Edge Function-backed implementation for fetching nearby gyms from Google Places.
class SupabaseGymLocationRepository implements GymLocationRepository {
  SupabaseGymLocationRepository({required SupabaseClient client})
      : _client = client;

  final SupabaseClient _client;

  @override
  Future<List<GymLocation>> searchGyms({
    double? latitude,
    double? longitude,
    String? query,
    int? radiusMeters,
  }) async {
    try {
      final res = await _client.functions.invoke(
        'nearby-gyms',
        body: {
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
          if (radiusMeters != null) 'radiusMeters': radiusMeters,
        },
      );

      final data = res.data;
      if (data is Map<String, dynamic>) {
        final list = data['gyms'];
        if (list is List) {
          return list
              .whereType<Map<String, dynamic>>()
              .map(GymLocation.fromJson)
              .toList();
        }
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }
}
