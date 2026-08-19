import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production UI has no unexplained raw visual ownership', () {
    final roots = <Directory>[
      Directory('../app/lib/app'),
      ...Directory('../features')
          .listSync()
          .whereType<Directory>()
          .map((feature) => Directory('${feature.path}/lib/src/presentation'))
          .where((directory) => directory.existsSync()),
      Directory('../wear/lib'),
    ];

    final dartFiles = roots
        .expand(
          (root) => root
              .listSync(recursive: true)
              .whereType<File>()
              .where((file) => file.path.endsWith('.dart')),
        )
        .where((file) {
          final path = file.path.replaceAll('\\', '/');
          return !path.contains('/controllers/') &&
              !path.endsWith('.g.dart') &&
              !path.endsWith('.freezed.dart');
        })
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    final violations = <String>[];

    for (final file in dartFiles) {
      final relativePath = file.path.replaceAll('\\', '/');
      var source = file.readAsStringSync();

      // Edge-to-edge platform chrome intentionally uses framework-transparent
      // system bar values rather than product palette roles.
      if (relativePath.endsWith('/app/app.dart') ||
          relativePath.endsWith('/screen/splash_screen.dart') ||
          relativePath.endsWith('/screens/congratulations_screen.dart')) {
        source = source
            .replaceAll('statusBarColor: Colors.transparent,', '')
            .replaceAll('systemNavigationBarColor: Colors.transparent,', '')
            .replaceAll(
              'systemNavigationBarDividerColor: Colors.transparent,',
              '',
            );
      }

      // Username debounce and fallback availability delay are program timing,
      // not visual motion contracts.
      if (relativePath.endsWith('/pages/account_settings_page.dart')) {
        source = source
            .replaceAll('Duration(milliseconds: 450)', 'Duration(program)')
            .replaceAll('Duration(milliseconds: 250)', 'Duration(program)');
      }

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
        'numeric millisecond visual duration',
      );
      _collect(
        violations,
        relativePath,
        source,
        RegExp(r'TioTheme\.colors\s*\('),
        'retired runtime color accessor',
      );
      _collect(
        violations,
        relativePath,
        source,
        RegExp(r'TioSpacing\.(extraSmall|small|medium|large|extraLarge)\b'),
        'retired spacing alias',
      );
      _collect(
        violations,
        relativePath,
        source,
        RegExp(r'TioRadius\.(small|medium|large|extraLarge)\b'),
        'retired radius alias',
      );
    }

    expect(
      violations,
      isEmpty,
      reason: 'Final production visual ownership violations:\n${violations.join('\n')}',
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
