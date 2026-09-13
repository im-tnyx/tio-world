import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

const _popupKey = ValueKey('anchored-popup');

void main() {
  testWidgets('a control with trailing room keeps leading alignment',
      (tester) async {
    await _pump(tester, alignment: AlignmentDirectional.topStart);

    final anchor = tester.getRect(find.byKey(_anchorKey));
    final popup = tester.getRect(find.byKey(_popupKey));

    expect(popup.left, anchor.left);
    expect(popup.top, greaterThan(anchor.bottom));
  });

  testWidgets('a control near the trailing edge pins the card to that edge',
      (tester) async {
    await _pump(tester, alignment: AlignmentDirectional.topEnd);

    final anchor = tester.getRect(find.byKey(_anchorKey));
    final popup = tester.getRect(find.byKey(_popupKey));

    expect(
      popup.right,
      anchor.right,
      reason: 'the card must stay attached to the control it belongs to',
    );
    expect(popup.width, lessThan(TioSize.dp200));
  });

  testWidgets('the card opens on whichever side of the control has room',
      (tester) async {
    await _pump(tester, alignment: AlignmentDirectional.topEnd);
    var anchor = tester.getRect(find.byKey(_anchorKey));
    var popup = tester.getRect(find.byKey(_popupKey));
    expect(popup.top, greaterThanOrEqualTo(anchor.bottom));

    await _pump(tester, alignment: AlignmentDirectional.bottomEnd);
    anchor = tester.getRect(find.byKey(_anchorKey));
    popup = tester.getRect(find.byKey(_popupKey));
    expect(popup.bottom, lessThanOrEqualTo(anchor.top));
    expect(popup.right, anchor.right);
  });
}

final _anchorKey = GlobalKey();

Future<void> _pump(
  WidgetTester tester, {
  required AlignmentDirectional alignment,
}) async {
  tester.view.physicalSize = const Size(372, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.light),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(TioSpacing.lg),
          child: Align(
            alignment: alignment,
            child: TioAnchoredPopup(
              anchorKey: _anchorKey,
              isOpen: true,
              onDismiss: () {},
              dismissSemanticLabel: 'Dismiss',
              popupKey: _popupKey,
              maximumWidth: TioSize.dp200,
              contentBuilder: (context, maximumHeight) => const SizedBox(
                width: TioSize.dp80,
                height: TioSize.dp48,
              ),
              child: SizedBox.square(
                key: _anchorKey,
                dimension: TioSize.dp48,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
