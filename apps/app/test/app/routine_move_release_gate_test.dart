import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/app.dart';

void main() {
  // Run in ordinary CI (default OFF) and also with
  // --dart-define=TIO_MOVE_ROUTINE_RELEASE=true (explicit ON).
  test('R4 Move release candidate gate follows only its build-time opt-in', () {
    const releaseOptIn =
        bool.fromEnvironment('TIO_MOVE_ROUTINE_RELEASE', defaultValue: false);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(routineMoveReleaseEnabledProvider), releaseOptIn);
    // The two older QA/preview flags are independent, not an implicit
    // production release switch. Their default build values stay off.
    expect(container.read(routineMoveQaEnabledProvider), isFalse);
    expect(container.read(routineMoveUiPreviewEnabledProvider), isFalse);
  });
}
