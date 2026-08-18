import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  test('measurement preference section label keeps audited typography', () {
    expect(TioMeasurementPreferenceTokens.sectionLabelFontSize, 13.0);
  });
}
