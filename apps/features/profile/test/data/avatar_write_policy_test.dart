import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_profile/src/data/avatar_write_policy.dart';

void main() {
  group('buildCanonicalAvatarWrite', () {
    test('missing avatar preserves the current stored avatar', () {
      expect(buildCanonicalAvatarWrite(), isEmpty);
      expect(buildCanonicalAvatarWrite(avatarUrl: '   '), isEmpty);
    });

    test('new avatar writes only the canonical avatar_url field', () {
      expect(
        buildCanonicalAvatarWrite(
          avatarUrl: '  https://example.com/avatar.jpg  ',
        ),
        const {'avatar_url': 'https://example.com/avatar.jpg'},
      );
    });

    test('explicit delete clears canonical and legacy fallback fields', () {
      expect(
        buildCanonicalAvatarWrite(clear: true),
        const {
          'avatar_url': null,
          'profile_image': null,
        },
      );
    });
  });
}
