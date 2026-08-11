import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  for (final size in TioAvatarSize.values) {
    testWidgets('${size.name} uses its semantic dimensions', (tester) async {
      const avatarKey = Key('avatar');

      await tester.pumpWidget(
        _AvatarTestApp(
          child: TioAvatar(key: avatarKey, size: size),
        ),
      );

      expect(
          tester.getSize(find.byKey(avatarKey)), Size.square(size.dimension));
    });
  }

  testWidgets('uses circle by default and supports rounded profile shape',
      (tester) async {
    const circleKey = Key('circle-avatar');
    const roundedKey = Key('rounded-avatar');

    await tester.pumpWidget(
      const _AvatarTestApp(
        child: Row(
          children: [
            TioAvatar(key: circleKey),
            TioAvatar(
              key: roundedKey,
              shape: TioAvatarShape.rounded,
            ),
          ],
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byKey(circleKey),
        matching: find.byType(ClipOval),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(roundedKey),
        matching: find.byType(ClipRRect),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows initials instead of the fallback icon', (tester) async {
    await tester.pumpWidget(
      const _AvatarTestApp(
        child: TioAvatar(initials: 'st'),
      ),
    );

    expect(find.text('ST'), findsOneWidget);
    expect(find.byIcon(Icons.person), findsNothing);
  });

  testWidgets('returns to the fallback when image decoding fails',
      (tester) async {
    await tester.pumpWidget(
      _AvatarTestApp(
        child: TioAvatar(
          image: MemoryImage(Uint8List.fromList(const [0, 1, 2])),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  testWidgets('exposes an optional image semantic label', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        const _AvatarTestApp(
          child: TioAvatar(semanticLabel: 'Santosh profile photo'),
        ),
      );

      expect(
        tester.getSemantics(find.byType(TioAvatar)),
        matchesSemantics(
          label: 'Santosh profile photo',
          isImage: true,
        ),
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('shell profile entry uses the compact shared avatar',
      (tester) async {
    await tester.pumpWidget(
      _AvatarTestApp(
        child: Scaffold(
          appBar: TioShellTopBar(
            planTier: ShellPlanTier.plus,
            scrollOpacity: 0,
            onAction: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(CircleAvatar), findsNothing);
    expect(find.byType(TioAvatar), findsOneWidget);
    expect(
      tester.getSize(find.byType(TioAvatar)),
      Size.square(TioAvatarSize.compact.dimension),
    );
  });
}

class _AvatarTestApp extends StatelessWidget {
  const _AvatarTestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, appChild) =>
          TioTheme(child: appChild ?? const SizedBox.shrink()),
      home: Scaffold(body: Center(child: child)),
    );
  }
}
