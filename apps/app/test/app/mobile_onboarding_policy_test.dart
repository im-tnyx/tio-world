import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/onboarding/onboarding.dart';

void main() {
  test('email, Google, and signed-out flows include optional Mobile', () {
    expect(shouldIncludeMobileOnboarding(null), isTrue);
    expect(shouldIncludeMobileOnboarding(''), isTrue);
    expect(shouldIncludeMobileOnboarding('   '), isTrue);
  });

  test('provider-authenticated phone skips standalone Mobile', () {
    expect(shouldIncludeMobileOnboarding('+919876543210'), isFalse);
  });
}
