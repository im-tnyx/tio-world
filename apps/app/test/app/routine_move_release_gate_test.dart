import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/composition/workout_providers.dart';

void main() {
  // Independent test-only expectation. The ON CI invocation must explicitly
  // provide this marker AND TIO_MOVE_ROUTINE_RELEASE=true. If the production
  // opt-in define is omitted, the ON assertion fails rather than silently
  // comparing two false values. Ordinary Flutter test runs assert OFF.
  const verifyOptIn =
      bool.fromEnvironment('TIO_TEST_EXPECT_MOVE_ON', defaultValue: false);

  test('R4 ordinary build keeps Move release OFF', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(routineMoveReleaseEnabledProvider), isFalse);
    expect(container.read(routineMoveQaEnabledProvider), isFalse);
    expect(container.read(routineMoveUiPreviewEnabledProvider), isFalse);
  }, skip: verifyOptIn);

  test('R4 explicitly opted-in build enables Move release', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(routineMoveReleaseEnabledProvider), isTrue,
        reason: 'ON CI must fail when TIO_MOVE_ROUTINE_RELEASE=true is missing');
    expect(container.read(routineMoveQaEnabledProvider), isFalse);
    expect(container.read(routineMoveUiPreviewEnabledProvider), isFalse);
  }, skip: !verifyOptIn);
}
