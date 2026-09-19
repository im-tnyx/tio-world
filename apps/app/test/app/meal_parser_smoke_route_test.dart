import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/router.dart';

void main() {
  group('debugMealParserSmokeStartupRoute', () {
    test('accepts the exact smoke route in a non-release runtime', () {
      expect(
        debugMealParserSmokeStartupRoute(
          platformRoute: debugMealParserSmokePath,
          isReleaseMode: false,
        ),
        debugMealParserSmokePath,
      );
    });

    test('ignores unrelated platform routes', () {
      expect(
        debugMealParserSmokeStartupRoute(
          platformRoute: '/',
          isReleaseMode: false,
        ),
        isNull,
      );
    });

    test('cannot select the smoke route in release mode', () {
      expect(
        debugMealParserSmokeStartupRoute(
          platformRoute: debugMealParserSmokePath,
          isReleaseMode: true,
        ),
        isNull,
      );
    });
  });
}
