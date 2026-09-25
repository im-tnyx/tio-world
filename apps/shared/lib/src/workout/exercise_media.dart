/// Gender variant of built-in Exercise media.
enum ExerciseMediaGender { male, female }

/// Primary media type the catalog declares for an Exercise.
enum ExerciseMediaType { video, image }

/// One kind of media asset inside an [ExerciseMediaVariant].
enum ExerciseMediaKind { image, thumbnail, video }

/// Image, thumbnail and video URLs for one gender variant.
///
/// Every present URL must be an absolute `https` URL. Absent assets are null.
final class ExerciseMediaVariant {
  ExerciseMediaVariant({Uri? imageUrl, Uri? thumbnailUrl, Uri? videoUrl})
      : imageUrl = _requireHttps(imageUrl, 'imageUrl'),
        thumbnailUrl = _requireHttps(thumbnailUrl, 'thumbnailUrl'),
        videoUrl = _requireHttps(videoUrl, 'videoUrl');

  final Uri? imageUrl;
  final Uri? thumbnailUrl;
  final Uri? videoUrl;

  /// The URL for [kind], or null when this variant has no such asset.
  Uri? urlFor(ExerciseMediaKind kind) => switch (kind) {
        ExerciseMediaKind.image => imageUrl,
        ExerciseMediaKind.thumbnail => thumbnailUrl,
        ExerciseMediaKind.video => videoUrl,
      };

  static Uri? _requireHttps(Uri? value, String name) {
    if (value == null) return null;
    if (value.scheme != 'https' || value.host.isEmpty) {
      throw ArgumentError.value(value, name, 'must be an absolute https URL');
    }
    return value;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseMediaVariant &&
          other.imageUrl == imageUrl &&
          other.thumbnailUrl == thumbnailUrl &&
          other.videoUrl == videoUrl;

  @override
  int get hashCode => Object.hash(imageUrl, thumbnailUrl, videoUrl);
}

/// Per-gender media for one built-in Exercise.
///
/// [urlFor] is the single selection rule shared by phone and watch surfaces.
final class ExerciseMedia {
  ExerciseMedia({
    required this.type,
    required this.defaultGender,
    this.videoFallbackGender,
    required this.male,
    required this.female,
  });

  final ExerciseMediaType type;

  /// Variant used when the viewer's gender is unknown or not male/female.
  final ExerciseMediaGender defaultGender;

  /// Optional curated variant to try for video after [defaultGender].
  final ExerciseMediaGender? videoFallbackGender;

  final ExerciseMediaVariant male;
  final ExerciseMediaVariant female;

  ExerciseMediaVariant variant(ExerciseMediaGender gender) => switch (gender) {
        ExerciseMediaGender.male => male,
        ExerciseMediaGender.female => female,
      };

  /// Resolves the [kind] URL for a viewer of [gender], or null for text-only.
  ///
  /// Order: [gender] (when known), then [defaultGender], then
  /// [videoFallbackGender] for video, then the remaining variant.
  Uri? urlFor(ExerciseMediaKind kind, {ExerciseMediaGender? gender}) {
    final order = <ExerciseMediaGender>{
      if (gender != null) gender,
      defaultGender,
      if (kind == ExerciseMediaKind.video && videoFallbackGender != null)
        videoFallbackGender!,
      ...ExerciseMediaGender.values,
    };
    for (final candidate in order) {
      final url = variant(candidate).urlFor(kind);
      if (url != null) return url;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseMedia &&
          other.type == type &&
          other.defaultGender == defaultGender &&
          other.videoFallbackGender == videoFallbackGender &&
          other.male == male &&
          other.female == female;

  @override
  int get hashCode =>
      Object.hash(type, defaultGender, videoFallbackGender, male, female);
}
