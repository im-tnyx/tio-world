import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/composition/workout_providers.dart';

void main() {
  // Independent test-only markers ensure the explicit override invocations
  // assert the requested value instead of comparing two default values.
  const verifyExplicitOn =
      bool.fromEnvironment('TIO_TEST_EXPECT_MOVE_ON', defaultValue: false);
  const verifyExplicitOff =
      bool.fromEnvironment('TIO_TEST_EXPECT_MOVE_OFF', defaultValue: false);

  test('default Move gate follows the Flutter build mode', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(routineMoveReleaseEnabledProvider), !kReleaseMode);
    expect(container.read(routineMoveQaEnabledProvider), isFalse);
    expect(container.read(routineMoveUiPreviewEnabledProvider), isFalse);
  }, skip: verifyExplicitOn || verifyExplicitOff);

  test('explicit Move ON override enables the existing capability', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(routineMoveReleaseEnabledProvider), isTrue,
        reason: 'the explicit true override must enable the existing gate');
    expect(container.read(routineMoveQaEnabledProvider), isFalse);
    expect(container.read(routineMoveUiPreviewEnabledProvider), isFalse);
  }, skip: !verifyExplicitOn);

  test('explicit Move OFF override disables the development default', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(routineMoveReleaseEnabledProvider), isFalse,
        reason:
            'the explicit false override must win over debug/profile default');
    expect(container.read(routineMoveQaEnabledProvider), isFalse);
    expect(container.read(routineMoveUiPreviewEnabledProvider), isFalse);
  }, skip: !verifyExplicitOff);
}
