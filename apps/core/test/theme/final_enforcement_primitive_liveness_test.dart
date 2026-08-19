import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('canonical primitive registries contain production-backed values only', () {
    final appsRoot = Directory('..');
    expect(
      Directory('../core').existsSync(),
      isTrue,
      reason: 'Run this test from apps/core.',
    );

    const registries = <String, String>{
      'TioSize': 'lib/src/theme/tokens/primitive/tio_size.dart',
      'TioOpacity': 'lib/src/theme/tokens/primitive/tio_opacity.dart',
      'TioAlpha': 'lib/src/theme/tokens/primitive/tio_alpha.dart',
      'TioDuration': 'lib/src/theme/tokens/primitive/tio_duration.dart',
      'TioPalette': 'lib/src/theme/tokens/foundation/tio_palette.dart',
    };

    final productionFiles = appsRoot
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) {
          final path = file.path.replaceAll('\\', '/');
          return !path.contains('/test/') &&
              !path.contains('/.dart_tool/') &&
              !path.endsWith('.g.dart') &&
              !path.endsWith('.freezed.dart');
        })
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    final violations = <String>[];

    for (final entry in registries.entries) {
      final className = entry.key;
      final owner = File(entry.value);
      expect(owner.existsSync(), isTrue, reason: 'Missing ${entry.value}');

      final ownerSource = owner.readAsStringSync();
      final names = RegExp(r'static const\s+(\w+)\s*=')
          .allMatches(ownerSource)
          .map((match) => match.group(1)!)
          .toList()
        ..sort();

      for (final name in names) {
        final symbol = '$className.$name';
        var productionReferences = 0;

        for (final file in productionFiles) {
          if (file.absolute.path == owner.absolute.path) continue;
          final source = file.readAsStringSync();
          productionReferences += symbol.allMatches(source).length;
        }

        if (productionReferences == 0) {
          violations.add('$symbol: no production reference outside its owner');
        }
      }
    }

    final report = violations.isEmpty
        ? 'NO_DEAD_PRIMITIVES\n'
        : '${violations.join('\n')}\n';
    File('dead-primitives.txt').writeAsStringSync(report);

    expect(
      violations,
      isEmpty,
      reason: 'Dead primitive registry entries:\n${violations.join('\n')}',
    );
  });
}
