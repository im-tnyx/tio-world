import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Profile presentation has governed visual ownership', () {
    final presentationRoot = Directory('lib/src/presentation');
    expect(
      presentationRoot.existsSync(),
      isTrue,
      reason: 'Run this test from apps/features/profile.',
    );

    final violations = <String>[];
    final dartFiles = presentationRoot
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      final relativePath = file.path.replaceAll('\\', '/');

      _collect(
        violations,
        relativePath,
        source,
        RegExp(r'\bColors\.'),
        'direct framework color',
      );
      _collect(
        violations,
        relativePath,
        source,
        RegExp(r'\bColor\s*\(\s*0x'),
        'raw Color(0x...) constructor',
      );
      _collect(
        violations,
        relativePath,
        source,
        RegExp(r'\bFontWeight\.w\d+'),
        'raw FontWeight',
      );
      _collect(
        violations,
        relativePath,
        source,
        RegExp(r'fontSize\s*:\s*-?\d'),
        'numeric fontSize',
      );
      _collect(
        violations,
        relativePath,
        source,
        RegExp(r'letterSpacing\s*:\s*-?\d'),
        'numeric letterSpacing',
      );
      _collect(
        violations,
        relativePath,
        source,
        RegExp(r'withValues\s*\(\s*alpha\s*:\s*\d'),
        'numeric withValues alpha',
      );
      _collect(
        violations,
        relativePath,
        source,
        RegExp(r'withAlpha\s*\(\s*\d'),
        'numeric withAlpha',
      );
      _collect(
        violations,
        relativePath,
        source,
        RegExp(r'Duration\s*\(\s*milliseconds\s*:\s*\d'),
        'numeric millisecond duration',
      );
      _collect(
        violations,
        relativePath,
        source,
        RegExp(r'TioSpacing\.(small|medium|large|extraLarge)\b'),
        'legacy spacing alias',
      );
      _collect(
        violations,
        relativePath,
        source,
        RegExp(r'TioRadius\.(small|medium|large|extraLarge)\b'),
        'legacy radius alias',
      );
    }

    expect(
      violations,
      isEmpty,
      reason: 'Slice F Profile visual ownership violations:\n${violations.join('\n')}',
    );
  });
}

void _collect(
  List<String> violations,
  String path,
  String source,
  RegExp pattern,
  String label,
) {
  for (final match in pattern.allMatches(source)) {
    final line = '\n'.allMatches(source.substring(0, match.start)).length + 1;
    violations.add('$path:$line: $label: ${match.group(0)}');
  }
}
