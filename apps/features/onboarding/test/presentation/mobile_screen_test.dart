import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/src/presentation/screens/profile/mobile_screen.dart';

void main() {
  Widget buildApp({
    String initialMobile = '',
    bool isVerified = false,
    ValueChanged<String>? onMobileChanged,
    ValueChanged<bool>? onVerificationCompleted,
  }) {
    return MaterialApp(
      theme: ThemeData(
        extensions: const [TioColors.light],
      ),
      home: Scaffold(
        body: MobileScreen(
          initialMobile: initialMobile,
          isVerified: isVerified,
          onMobileChanged: onMobileChanged ?? (_) {},
          onVerificationCompleted: onVerificationCompleted ?? (_) {},
        ),
      ),
    );
  }

  testWidgets('mobile is optional without putting Optional in the title',
      (tester) async {
    String? mobile;
    bool? verified;

    await tester.pumpWidget(
      buildApp(
        onMobileChanged: (value) => mobile = value,
        onVerificationCompleted: (value) => verified = value,
      ),
    );

    expect(find.text("What's your mobile number?"), findsOneWidget);
    expect(find.textContaining('(Optional)'), findsNothing);
    expect(find.byType(TioMobileNumberField), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.text('Verify'), findsNothing);
    expect(find.byIcon(Icons.verified_rounded), findsNothing);
    expect(
      find.text(
        'You can add or verify a mobile number later from Account Settings.',
      ),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('mobile-number-input')),
      '9876543210',
    );
    await tester.pump();

    expect(mobile, '+91 9876543210');
    expect(verified, isFalse);
    expect(find.text('Verify'), findsNothing);
    expect(find.byIcon(Icons.verified_rounded), findsNothing);
  });

  testWidgets('provider-verified mobile can be represented as verified',
      (tester) async {
    await tester.pumpWidget(
      buildApp(
        initialMobile: '+91 9876543210',
        isVerified: true,
      ),
    );

    expect(find.byType(TioMobileNumberField), findsOneWidget);
    expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    expect(
      find.text('Verified by your authentication provider.'),
      findsOneWidget,
    );
    expect(find.text('Verify'), findsNothing);

    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('mobile-number-input')),
    );
    expect(field.controller?.text, '9876543210');
  });
}
