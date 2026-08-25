import 'package:test/test.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('normalizePhoneNumberE164', () {
    test('canonicalizes current India national input', () {
      expect(normalizePhoneNumberE164('9123456789'), '+919123456789');
    });

    test('removes presentation formatting from India input', () {
      expect(
        normalizePhoneNumberE164('+91 91234-56789'),
        '+919123456789',
      );
      expect(normalizePhoneNumberE164('91 9123456789'), '+919123456789');
    });

    test('preserves explicit valid international E.164 identity', () {
      expect(
        normalizePhoneNumberE164('+1 (415) 555-2671'),
        '+14155552671',
      );
    });

    test('empty optional phone remains empty', () {
      expect(normalizePhoneNumberE164('   '), isEmpty);
    });

    test('rejects ambiguous non-plus international input', () {
      expect(
        () => normalizePhoneNumberE164('14155552671'),
        throwsArgumentError,
      );
    });

    test('rejects invalid E.164 length and leading zero', () {
      expect(
        () => normalizePhoneNumberE164('+1234567'),
        throwsArgumentError,
      );
      expect(
        () => normalizePhoneNumberE164('+0123456789'),
        throwsArgumentError,
      );
      expect(
        () => normalizePhoneNumberE164('+1234567890123456'),
        throwsArgumentError,
      );
    });
  });
}
