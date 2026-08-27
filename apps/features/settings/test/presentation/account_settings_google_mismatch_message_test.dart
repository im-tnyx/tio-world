import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_settings/settings.dart';

void main() {
  Widget buildPage(GoogleIdentityLinkController controller) {
    return ProviderScope(
      overrides: [
        googleIdentityLinkControllerProvider.overrideWithValue(controller),
      ],
      child: MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: const AccountSettingsPage(
          username: 'member',
          linkedProvider: 'Phone + Email',
        ),
      ),
    );
  }

  testWidgets('Google Email mismatch shows actionable message and keeps Connect',
      (tester) async {
    final controller = _ThrowingGoogleIdentityLinkController(
      StateError('Use the Google account matching your Tio email.'),
    );

    await tester.pumpWidget(buildPage(controller));
    await tester.tap(find.byKey(const ValueKey('google-connect-action')));
    await tester.pumpAndSettle();

    expect(controller.calls, 1);
    expect(
      find.text(
        'Google account doesn’t match. Please choose the Google account with the same email as your Tio account.',
      ),
      findsOneWidget,
    );
    expect(find.text('Could not connect Google. Please try again.'), findsNothing);
    expect(find.text('Connect'), findsOneWidget);
    expect(find.text('Connected'), findsNothing);
  });

  testWidgets('unexpected Google link failure keeps generic error',
      (tester) async {
    final controller = _ThrowingGoogleIdentityLinkController(
      StateError('Unexpected provider failure.'),
    );

    await tester.pumpWidget(buildPage(controller));
    await tester.tap(find.byKey(const ValueKey('google-connect-action')));
    await tester.pumpAndSettle();

    expect(controller.calls, 1);
    expect(
      find.text('Could not connect Google. Please try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('Unexpected provider failure'), findsNothing);
    expect(find.text('Connect'), findsOneWidget);
  });
}

final class _ThrowingGoogleIdentityLinkController
    implements GoogleIdentityLinkController {
  _ThrowingGoogleIdentityLinkController(this.error);

  final Object error;
  int calls = 0;

  @override
  Future<bool> linkGoogleIdentity() async {
    calls++;
    throw error;
  }
}
