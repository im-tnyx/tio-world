import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_profile/profile.dart';

void main() {
  testWidgets('Profile uses an actionable 80dp avatar', (tester) async {
    var avatarTaps = 0;
    var settingsTaps = 0;
    await tester.pumpWidget(
      _ProfileTestApp(
        child: ProfilePage(
          onAvatarPressed: () => avatarTaps++,
          onSettingsPressed: () => settingsTaps++,
          avatarFrame: TioAvatarFrame.plusRing,
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(TioAvatar)),
      const Size.square(80),
    );
    expect(find.byKey(const ValueKey('tio-avatar-plus-ring')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('profile-avatar-entry')));
    expect(avatarTaps, 1);

    expect(
        find.byKey(const ValueKey('profile-settings-action')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('profile-settings-action')));
    expect(settingsTaps, 1);
  });

  testWidgets('photo route is square with safe disabled actions when empty',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var backTaps = 0;

    await tester.pumpWidget(
      _ProfileTestApp(
        child: AvatarPreviewPage(
          onBackPressed: () => backTaps++,
        ),
      ),
    );

    final preview = find.byKey(const ValueKey('profile-avatar-preview'));
    final appBarBottom = tester.getBottomLeft(find.byType(AppBar)).dy;
    final screenBottom = tester.getBottomLeft(find.byType(Scaffold)).dy;

    expect(tester.getSize(preview), const Size.square(360));
    expect(
      tester.getCenter(preview).dy,
      closeTo((appBarBottom + screenBottom) / 2, 1),
    );
    expect(
      tester.getSize(find.byType(TioAvatar)),
      const Size.square(160),
    );

    for (final key in const [
      ValueKey('profile-avatar-edit'),
      ValueKey('profile-avatar-delete'),
      ValueKey('profile-avatar-download'),
    ]) {
      expect(tester.widget<IconButton>(find.byKey(key)).onPressed, isNull);
    }

    await tester.tap(find.byType(BackButton));
    expect(backTaps, 1);
  });

  testWidgets('photo decode failure returns to the shared fallback',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _ProfileTestApp(
          child: AvatarPreviewPage(
            onBackPressed: () {},
            image: MemoryImage(Uint8List.fromList(const [0, 1, 2])),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TioAvatar), findsOneWidget);
      expect(
        tester.getSize(find.byType(TioAvatar)),
        const Size.square(160),
      );
      expect(
        find.bySemanticsLabel('Profile photo unavailable'),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }
  });
}

class _ProfileTestApp extends StatelessWidget {
  const _ProfileTestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, appChild) =>
          TioTheme(child: appChild ?? const SizedBox.shrink()),
      home: child,
    );
  }
}
