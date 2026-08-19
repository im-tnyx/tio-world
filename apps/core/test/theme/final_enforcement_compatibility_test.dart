import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('retired theme compatibility APIs have zero Dart references', () {
    final appsRoot = Directory('..');
    expect(
      Directory('../core').existsSync(),
      isTrue,
      reason: 'Run this test from apps/core.',
    );

    final retiredSymbols = <String>[
      'TioMotion' 'Tokens',
      '.radius' 'Small',
      '.radius' 'Medium',
      '.radius' 'Large',
    ];
    final violations = <String>[];

    final dartFiles = appsRoot
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      for (final symbol in retiredSymbols) {
        var offset = 0;
        while (true) {
          final index = source.indexOf(symbol, offset);
          if (index < 0) break;
          final line = '\n'.allMatches(source.substring(0, index)).length + 1;
          violations.add('${file.path}:$line: retired compatibility API: $symbol');
          offset = index + symbol.length;
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Final enforcement compatibility violations:\n${violations.join('\n')}',
    );
  });
}
