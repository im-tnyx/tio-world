import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Settings only imports the public Progress domain contract boundary', () {
    final library = Directory('lib');
    expect(library.existsSync(), isTrue);

    final violations = <String>[];
    final progressImport = RegExp(
      r'''import\s+['"]package:tio_feature_progress/([^'"]+)['"]''',
    );

    for (final file in library.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final source = file.readAsStringSync();
      for (final match in progressImport.allMatches(source)) {
        if (match.group(1) != 'progress_contracts.dart') {
          violations.add('${file.path}: ${match.group(0)}');
        }
      }
    }

    expect(violations, isEmpty,
        reason: 'Settings must not import Progress data or presentation '
            'through its broad barrel or private implementation paths.');
  });

  test('Progress contracts barrel exports only Body and Wellness domain', () {
    final barrel = File('../progress/lib/progress_contracts.dart');
    expect(barrel.existsSync(), isTrue);
    final exports = RegExp(r"^export '([^']+)';", multiLine: true)
        .allMatches(barrel.readAsStringSync())
        .map((match) => match.group(1))
        .toList();

    expect(exports, [
      'src/domain/body_setup.dart',
      'src/domain/wellness_targets.dart',
    ]);
  });
}
