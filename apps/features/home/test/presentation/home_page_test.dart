import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_home/home.dart';

void main() {
  testWidgets('HomePage stays visually empty', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: _HomeTestHost(
          child: HomePage(),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('home-page')), findsOneWidget);
    expect(find.byType(Text), findsNothing);
  });
}

class _HomeTestHost extends StatelessWidget {
  const _HomeTestHost({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TioTheme(child: child);
  }
}
