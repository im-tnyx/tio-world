import 'package:test/test.dart';
import 'package:tio_shared/shared.dart';

Uri url(String path) => Uri.parse('https://media.example/$path');

ExerciseMediaVariant variant({
  String? image,
  String? thumbnail,
  String? video,
}) =>
    ExerciseMediaVariant(
      imageUrl: image == null ? null : url(image),
      thumbnailUrl: thumbnail == null ? null : url(thumbnail),
      videoUrl: video == null ? null : url(video),
    );

ExerciseMedia media({
  ExerciseMediaGender defaultGender = ExerciseMediaGender.male,
  ExerciseMediaGender? videoFallbackGender,
  ExerciseMediaVariant? male,
  ExerciseMediaVariant? female,
}) =>
    ExerciseMedia(
      type: ExerciseMediaType.video,
      defaultGender: defaultGender,
      videoFallbackGender: videoFallbackGender,
      male: male ?? variant(image: 'm.png', video: 'm.mp4'),
      female: female ?? variant(image: 'f.png', video: 'f.mp4'),
    );

void main() {
  group('ExerciseMediaVariant', () {
    test('accepts absolute https URLs and absent assets', () {
      final value = variant(image: 'a.png');

      expect(value.imageUrl, url('a.png'));
      expect(value.thumbnailUrl, isNull);
      expect(value.videoUrl, isNull);
      expect(value.urlFor(ExerciseMediaKind.image), url('a.png'));
    });

    test('rejects non-https, relative and host-less URLs', () {
      for (final bad in [
        Uri.parse('http://media.example/a.png'),
        Uri.parse('media/a.png'),
        Uri.parse('https:///a.png'),
      ]) {
        expect(
          () => ExerciseMediaVariant(imageUrl: bad),
          throwsA(isA<ArgumentError>()
              .having((error) => error.name, 'name', 'imageUrl')),
          reason: '$bad',
        );
      }
    });

    test('compares by value', () {
      expect(variant(image: 'a.png'), variant(image: 'a.png'));
      expect(
          variant(image: 'a.png').hashCode, variant(image: 'a.png').hashCode);
      expect(variant(image: 'a.png'), isNot(variant(image: 'b.png')));
    });
  });

  group('ExerciseMedia.urlFor', () {
    test('uses the viewer gender variant first', () {
      final value = media();

      expect(
        value.urlFor(ExerciseMediaKind.image,
            gender: ExerciseMediaGender.female),
        url('f.png'),
      );
      expect(
        value.urlFor(ExerciseMediaKind.image, gender: ExerciseMediaGender.male),
        url('m.png'),
      );
    });

    test('uses defaultGender when the viewer gender is unknown', () {
      final value = media(defaultGender: ExerciseMediaGender.female);

      expect(value.urlFor(ExerciseMediaKind.image), url('f.png'));
    });

    test('falls back to defaultGender when the viewer variant lacks it', () {
      final value = media(
        defaultGender: ExerciseMediaGender.male,
        female: variant(image: 'f.png'),
      );

      expect(
        value.urlFor(ExerciseMediaKind.video,
            gender: ExerciseMediaGender.female),
        url('m.mp4'),
      );
    });

    test('uses videoFallbackGender for video after defaultGender', () {
      final value = media(
        defaultGender: ExerciseMediaGender.male,
        videoFallbackGender: ExerciseMediaGender.female,
        male: variant(image: 'm.png'),
      );

      expect(value.urlFor(ExerciseMediaKind.video), url('f.mp4'));
      expect(value.urlFor(ExerciseMediaKind.image), url('m.png'));
    });

    test('falls back to the remaining variant', () {
      final value = media(
        defaultGender: ExerciseMediaGender.male,
        male: variant(image: 'm.png'),
      );

      expect(
        value.urlFor(ExerciseMediaKind.video, gender: ExerciseMediaGender.male),
        url('f.mp4'),
      );
    });

    test('returns null for text-only when no variant has the asset', () {
      final value = media();

      expect(value.urlFor(ExerciseMediaKind.thumbnail), isNull);
    });
  });

  test('ExerciseMedia compares by value', () {
    expect(media(), media());
    expect(media().hashCode, media().hashCode);
    expect(media(), isNot(media(defaultGender: ExerciseMediaGender.female)));
    expect(
      media(),
      isNot(media(videoFallbackGender: ExerciseMediaGender.female)),
    );
  });

  group('Exercise.media', () {
    Exercise exercise({ExerciseMedia? media}) => Exercise(
          ref: ExerciseRef.catalog('ex_synthetic_alpha'),
          displayName: 'Synthetic Alpha Lift',
          status: ExerciseStatus.active,
          media: media,
        );

    test('is optional', () {
      expect(exercise().media, isNull);
    });

    test('participates in value equality', () {
      expect(exercise(media: media()), exercise(media: media()));
      expect(
          exercise(media: media()).hashCode, exercise(media: media()).hashCode);
      expect(exercise(media: media()), isNot(exercise()));
    });
  });
}
