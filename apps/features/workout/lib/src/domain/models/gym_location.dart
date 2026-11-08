/// Model representing a gym location fetched from Google Places via Supabase Edge Function.
class GymLocation {
  const GymLocation({
    required this.id,
    required this.name,
    required this.address,
    this.distanceKm,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String address;
  final double? distanceKm;
  final double? latitude;
  final double? longitude;

  factory GymLocation.fromJson(Map<String, dynamic> json) {
    return GymLocation(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'distanceKm': distanceKm,
        'latitude': latitude,
        'longitude': longitude,
      };

  String get formattedDistance {
    if (distanceKm == null) return '';
    return '${distanceKm!.toStringAsFixed(2)} km';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GymLocation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
