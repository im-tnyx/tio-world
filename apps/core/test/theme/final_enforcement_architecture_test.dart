import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final report = File('final-architecture-violations.txt');
  report.writeAsStringSync('');

  test('final tree has no feature-owned presentation design-system catalogs', () {
    final featuresRoot = Directory('../features');
    expect(featuresRoot.existsSync(), isTrue);

    final violations = <String>[];
    final dartFiles = featuresRoot
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.replaceAll('\\', '/').contains('/test/'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in dartFiles) {
      final path = file.path.replaceAll('\\', '/');
      final isPresentation = path.contains('/lib/src/presentation/');
      if (path.contains('/lib/src/presentation/theme/') ||
          path.contains('/lib/src/presentation/tokens/') ||
          (isPresentation && path.endsWith('_tokens.dart'))) {
        violations.add('$path: feature-owned presentation design-system catalog');
      }
    }

    report.writeAsStringSync(
      violations.isEmpty
          ? 'NO_FEATURE_CATALOG_VIOLATIONS\n'
          : '${violations.join('\n')}\n',
      mode: FileMode.append,
    );

    expect(
      violations,
      isEmpty,
      reason: 'Feature-owned presentation design-system catalogs:\n${violations.join('\n')}',
    );
  });

  test('retired core compatibility structure is absent', () {
    final violations = <String>[];

    if (Directory('lib/src/theme/locals').existsSync()) {
      violations.add('lib/src/theme/locals: legacy compatibility directory exists');
    }
    if (File('lib/src/theme/tokens/effects/tio_motion_tokens.dart').existsSync()) {
      violations.add(
        'lib/src/theme/tokens/effects/tio_motion_tokens.dart: retired facade exists',
      );
    }

    final contextRoot = Directory('lib/src/theme/context');
    final contextSources = contextRoot
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.readAsStringSync())
        .join('\n');

    if (contextSources.contains('TioSpacing.')) {
      violations.add('theme/context: static TioSpacing wrapper remains');
    }
    if (contextSources.contains('TioRadius.')) {
      violations.add('theme/context: static TioRadius wrapper remains');
    }
    if (contextSources.contains('TioMotionTokens')) {
      violations.add('theme/context: retired TioMotionTokens reference remains');
    }

    report.writeAsStringSync(
      violations.isEmpty
          ? 'NO_COMPATIBILITY_STRUCTURE_VIOLATIONS\n'
          : '${violations.join('\n')}\n',
      mode: FileMode.append,
    );

    expect(
      violations,
      isEmpty,
      reason: 'Final compatibility structure violations:\n${violations.join('\n')}',
    );
  });
}
