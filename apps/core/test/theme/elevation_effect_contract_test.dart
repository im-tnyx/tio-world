import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  group('elevation effect ownership', () {
    test('none remains exact', () {
      expect(TioElevation.none, 0.0);
    });

    test('component contracts alias the shared none role', () {
      expect(TioCardTokens.materialThemeElevation, TioElevation.none);
      expect(TioNavigationTokens.elevation, TioElevation.none);
    });
  });
}
