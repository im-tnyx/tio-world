import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  testWidgets('TioTheme gives bare AppBars the canonical topbar height',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TioTheme(
          child: Scaffold(
            appBar: AppBar(),
          ),
        ),
      ),
    );

    final context = tester.element(find.byType(Scaffold));
    final appBar = tester.widget<AppBar>(find.byType(AppBar));

    expect(appBar.toolbarHeight, isNull);
    expect(
      Theme.of(context).appBarTheme.toolbarHeight,
      TioNavigationTokens.topBarHeight,
    );
    expect(
      AppBar.preferredHeightFor(context, appBar.preferredSize),
      TioNavigationTokens.topBarHeight,
    );
  });
}
