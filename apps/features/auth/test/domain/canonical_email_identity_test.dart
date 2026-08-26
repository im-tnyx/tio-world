import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_auth/auth.dart';

void main() {
  group('canonicalEmailIdentity', () {
    test('collapses Gmail aliases to one identity', () {
      const variants = <String>[
        'tnyx@gmail.com',
        'T.NYX@gmail.com',
        'tnyx+fit@gmail.com',
        't.n.y.x+anything@googlemail.com',
        '  T.NYX+1@GOOGLEMAIL.COM  ',
      ];

      for (final variant in variants) {
        expect(canonicalEmailIdentity(variant), 'tnyx@gmail.com');
      }
    });

    test('preserves non-Gmail dots and plus tags', () {
      expect(
        canonicalEmailIdentity('  User.Name+Fit@Example.COM  '),
        'user.name+fit@example.com',
      );
    });

    test('preserves non-Gmail local-part plus variants as distinct', () {
      expect(
        canonicalEmailIdentity('user@example.com'),
        'user@example.com',
      );
      expect(
        canonicalEmailIdentity('user+fit@example.com'),
        'user+fit@example.com',
      );
    });

    test('fails closed for malformed identities', () {
      const invalid = <String>[
        '',
        '   ',
        'missing-at.example.com',
        '@example.com',
        'user@',
        'user@@example.com',
        'user name@example.com',
      ];

      for (final value in invalid) {
        expect(canonicalEmailIdentity(value), isNull, reason: value);
      }
    });
  });
}
