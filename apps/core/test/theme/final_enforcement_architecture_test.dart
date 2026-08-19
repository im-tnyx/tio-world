import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
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

    expect(
      violations,
      isEmpty,
      reason: 'Feature-owned presentation design-system catalogs:\n${violations.join('\n')}',
    );
  });

  test('retired core compatibility structure is absent', () {
    expect(
      Directory('lib/src/theme/locals').existsSync(),
      isFalse,
      reason: 'Legacy theme/locals compatibility directory must stay deleted.',
    );
    expect(
      File('lib/src/theme/tokens/effects/tio_motion_tokens.dart').existsSync(),
      isFalse,
      reason: 'TioMotionTokens compatibility facade must stay deleted.',
    );

    final contextRoot = Directory('lib/src/theme/context');
    final contextSources = contextRoot
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.readAsStringSync())
        .join('\n');

    expect(contextSources, isNot(contains('TioSpacing.')));
    expect(contextSources, isNot(contains('TioRadius.')));
    expect(contextSources, isNot(contains('TioMotionTokens')));
  });
}
