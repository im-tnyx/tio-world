import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_profile/profile.dart';

/// The preview under a device that reports side insets.
///
/// Everything here exists because the square used to be sized from a box the
/// safe area had already narrowed, so a phone with horizontal insets showed a
/// photo smaller than the screen it was supposed to fill.
Future<void> _pumpPreview(
  WidgetTester tester, {
  required Size viewport,
  double horizontalInset = 0,
  double bottomInset = 0,
  String? avatarUrl,
  String? initials,
  VoidCallback? onBack,
}) async {
  await tester.binding.setSurfaceSize(viewport);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: EdgeInsets.only(
            left: horizontalInset,
            right: horizontalInset,
            top: 44,
            bottom: bottomInset,
          ),
          viewPadding: EdgeInsets.only(
            left: horizontalInset,
            right: horizontalInset,
            top: 44,
            bottom: bottomInset,
          ),
        ),
        child: TioTheme(child: child ?? const SizedBox.shrink()),
      ),
      home: AvatarPreviewPage(
        onBackPressed: onBack ?? () {},
        avatarUrl: avatarUrl,
        initials: initials,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _preview = ValueKey('profile-avatar-preview');

void main() {
  group('the preview reaches both screen edges', () {
    for (final viewport in [const Size(360, 800), const Size(320, 640)]) {
      testWidgets('at ${viewport.width.toInt()} wide with side insets',
          (tester) async {
        await _pumpPreview(
          tester,
          viewport: viewport,
          horizontalInset: 24,
        );

        final rect = tester.getRect(find.byKey(_preview));
        expect(rect.left, 0, reason: 'the left inset must not push it in');
        expect(rect.right, viewport.width);
        expect(
          rect.width,
          viewport.width,
          reason: 'the full viewport width, not the inset width',
        );
      });

      testWidgets('and stays square at ${viewport.width.toInt()} wide',
          (tester) async {
        await _pumpPreview(
          tester,
          viewport: viewport,
          horizontalInset: 24,
        );

        final rect = tester.getRect(find.byKey(_preview));
        expect(rect.width, rect.height);
        expect(tester.getSize(find.byType(TioAvatar)), rect.size);
      });
    }

    testWidgets('no insets is unchanged', (tester) async {
      await _pumpPreview(tester, viewport: const Size(360, 800));

      final rect = tester.getRect(find.byKey(_preview));
      expect(rect.size, const Size.square(360));
      expect(rect.left, 0);
    });
  });

  group('what the fix must not cost', () {
    testWidgets('the bottom inset is still respected', (tester) async {
      // Only the horizontal effect is removed. The home indicator's room is
      // real protection, and in portrait it costs the square nothing anyway:
      // the remaining height still exceeds the width, and the width is what
      // decides the size.
      await _pumpPreview(
        tester,
        viewport: const Size(360, 800),
        horizontalInset: 24,
        bottomInset: 34,
      );

      final body = tester.getRect(find.byType(LayoutBuilder).first);
      expect(
        body.bottom,
        800 - 34,
        reason: 'the body stops above the home indicator',
      );
      expect(
        tester.getRect(find.byKey(_preview)).width,
        360,
        reason: 'and the square is still edge to edge',
      );
    });

    testWidgets('the no-photo fallback fills the same square',
        (tester) async {
      await _pumpPreview(
        tester,
        viewport: const Size(360, 800),
        horizontalInset: 24,
        initials: 'SJ',
      );

      final rect = tester.getRect(find.byKey(_preview));
      expect(rect.left, 0);
      expect(rect.right, 360);
      expect(rect.size, const Size.square(360));
    });

    testWidgets('a photo that cannot decode keeps the same bounds',
        (tester) async {
      await _pumpPreview(
        tester,
        viewport: const Size(360, 800),
        horizontalInset: 24,
        avatarUrl: 'https://example.com/avatar.jpg',
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.byKey(_preview)).size,
        const Size.square(360),
      );
    });

    testWidgets('the actions and Back are untouched', (tester) async {
      var backTaps = 0;
      await _pumpPreview(
        tester,
        viewport: const Size(360, 800),
        horizontalInset: 24,
        onBack: () => backTaps++,
      );

      for (final key in const [
        ValueKey('profile-avatar-edit'),
        ValueKey('profile-avatar-download'),
        ValueKey('profile-avatar-delete'),
      ]) {
        expect(find.byKey(key), findsOneWidget);
      }

      await tester.tap(find.byType(BackButton));
      expect(backTaps, 1);
    });
  });
}
