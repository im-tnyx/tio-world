import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_auth/auth.dart';

void main() {
  Widget app(Widget child) {
    return MaterialApp(
      builder: (context, appChild) =>
          TioTheme(child: appChild ?? const SizedBox.shrink()),
      home: child,
    );
  }

  TextField renderedField(WidgetTester tester, String key) {
    return tester.widget<TextField>(
      find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(TextField),
      ),
    );
  }

  OutlineInputBorder outline(InputBorder? border) {
    expect(border, isA<OutlineInputBorder>());
    return border! as OutlineInputBorder;
  }

  testWidgets(
      'login and signup share field geometry while preserving screen semantics',
      (tester) async {
    await tester.pumpWidget(app(const LoginPage()));

    final loginEmail = renderedField(tester, 'login-email-input');
    final loginPassword = renderedField(tester, 'login-password-input');

    final loginEmailEnabled = outline(loginEmail.decoration?.enabledBorder);
    final loginEmailFocused = outline(loginEmail.decoration?.focusedBorder);
    final loginPasswordEnabled = outline(loginPassword.decoration?.enabledBorder);
    final loginPasswordFocused = outline(loginPassword.decoration?.focusedBorder);

    expect(loginEmail.decoration?.labelText, 'Email');
    expect(loginPassword.decoration?.labelText, 'Password');
    expect(loginEmail.decoration?.hintText, isNull);
    expect(loginPassword.decoration?.hintText, isNull);
    expect(
      loginEmail.decoration?.floatingLabelBehavior ?? FloatingLabelBehavior.auto,
      FloatingLabelBehavior.auto,
    );
    expect(
      loginPassword.decoration?.floatingLabelBehavior ??
          FloatingLabelBehavior.auto,
      FloatingLabelBehavior.auto,
    );

    await tester.pumpWidget(app(const EmailSignupPage()));
    await tester.pump();

    final signupEmail = renderedField(tester, 'signup-email-input');
    final signupPassword = renderedField(tester, 'signup-password-input');

    final signupEmailEnabled = outline(signupEmail.decoration?.enabledBorder);
    final signupEmailFocused = outline(signupEmail.decoration?.focusedBorder);
    final signupPasswordEnabled = outline(signupPassword.decoration?.enabledBorder);
    final signupPasswordFocused = outline(signupPassword.decoration?.focusedBorder);

    expect(signupEmail.decoration?.labelText, 'Email');
    expect(signupPassword.decoration?.labelText, 'Password');
    expect(signupEmail.decoration?.hintText, 'Enter your email');
    expect(signupPassword.decoration?.hintText, 'At least 6 characters');
    expect(
      signupEmail.decoration?.floatingLabelBehavior ?? FloatingLabelBehavior.auto,
      FloatingLabelBehavior.auto,
    );
    expect(
      signupPassword.decoration?.floatingLabelBehavior ??
          FloatingLabelBehavior.auto,
      FloatingLabelBehavior.auto,
    );

    expect(signupEmail.decoration?.prefixIcon, isNull);
    expect(signupPassword.decoration?.prefixIcon, isNull);

    expect(
      signupEmail.decoration?.contentPadding,
      loginEmail.decoration?.contentPadding,
    );
    expect(
      signupPassword.decoration?.contentPadding,
      loginPassword.decoration?.contentPadding,
    );

    expect(signupEmailEnabled.borderRadius, loginEmailEnabled.borderRadius);
    expect(signupEmailEnabled.borderSide, loginEmailEnabled.borderSide);
    expect(signupEmailFocused.borderRadius, loginEmailFocused.borderRadius);
    expect(signupEmailFocused.borderSide, loginEmailFocused.borderSide);

    expect(signupPasswordEnabled.borderRadius, loginPasswordEnabled.borderRadius);
    expect(signupPasswordEnabled.borderSide, loginPasswordEnabled.borderSide);
    expect(signupPasswordFocused.borderRadius, loginPasswordFocused.borderRadius);
    expect(signupPasswordFocused.borderSide, loginPasswordFocused.borderSide);

    expect(signupEmailEnabled.borderSide.width, TioStroke.width12);
    expect(signupEmailFocused.borderSide.width, TioStroke.width18);
    expect(signupPasswordEnabled.borderSide.width, TioStroke.width12);
    expect(signupPasswordFocused.borderSide.width, TioStroke.width18);
  });
}
