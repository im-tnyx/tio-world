import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_auth/auth.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      builder: (context, appChild) =>
          TioTheme(child: appChild ?? const SizedBox.shrink()),
      home: child,
    );
  }

  group('EmailSignupPage', () {
    testWidgets('renders all core UI elements matching clean design', (tester) async {
      await tester.pumpWidget(createTestWidget(const EmailSignupPage()));

      expect(find.text('Sign Up'), findsOneWidget); // Title
      expect(find.byKey(const ValueKey('signup-back-button')), findsOneWidget);
      expect(find.byKey(const ValueKey('signup-email-input')), findsOneWidget);
      expect(find.byKey(const ValueKey('signup-password-input')), findsOneWidget);
      expect(find.byKey(const ValueKey('signup-submit-button')), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.byKey(const ValueKey('signup-login-link')), findsOneWidget);
      expect(find.text('Already have an account? '), findsOneWidget);
    });

    testWidgets('password visibility toggle changes obscureText', (tester) async {
      await tester.pumpWidget(createTestWidget(const EmailSignupPage()));

      final passwordField = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const ValueKey('signup-password-input')),
          matching: find.byType(EditableText),
        ),
      );
      expect(passwordField.obscureText, isTrue);

      // Tap eye toggle icon
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      final updatedPasswordField = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const ValueKey('signup-password-input')),
          matching: find.byType(EditableText),
        ),
      );
      expect(updatedPasswordField.obscureText, isFalse);
    });

    testWidgets('create account button is disabled when fields are empty or invalid', (tester) async {
      await tester.pumpWidget(createTestWidget(const EmailSignupPage()));

      final submitBtn = tester.widget<TioButton>(find.byKey(const ValueKey('signup-submit-button')));
      expect(submitBtn.enabled, isFalse);

      // Enter short password (less than 6)
      await tester.enterText(find.byKey(const ValueKey('signup-email-input')), 'user@tnyx.fit');
      await tester.enterText(find.byKey(const ValueKey('signup-password-input')), '12345');
      await tester.pump();

      final submitBtnShort = tester.widget<TioButton>(find.byKey(const ValueKey('signup-submit-button')));
      expect(submitBtnShort.enabled, isFalse);

      // Enter valid password (6+ chars)
      await tester.enterText(find.byKey(const ValueKey('signup-password-input')), '123456');
      await tester.pump();

      final submitBtnValid = tester.widget<TioButton>(find.byKey(const ValueKey('signup-submit-button')));
      expect(submitBtnValid.enabled, isTrue);
    });

    testWidgets('calls signUpWithEmailUseCase on valid submit', (tester) async {
      var emailSubmitted = '';
      var passwordSubmitted = '';

      final mockRepo = FakeAuthSignInRepository(
        onSignUpWithEmail: (email, pass) async {
          emailSubmitted = email;
          passwordSubmitted = pass;
          return const SignInSuccess(AuthSession(userId: 'usr-2', email: 'new@tnyx.fit'));
        },
      );

      await tester.pumpWidget(
        createTestWidget(
          EmailSignupPage(
            signUpWithEmailUseCase: SignUpWithEmailUseCase(signInRepository: mockRepo),
          ),
        ),
      );

      await tester.enterText(find.byKey(const ValueKey('signup-email-input')), 'new@tnyx.fit');
      await tester.enterText(find.byKey(const ValueKey('signup-password-input')), 'Pass123456');
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('signup-submit-button')));
      await tester.pump();

      expect(emailSubmitted, 'new@tnyx.fit');
      expect(passwordSubmitted, 'Pass123456');
    });

    testWidgets('displays error banner when sign up fails', (tester) async {
      final mockRepo = FakeAuthSignInRepository(
        onSignUpWithEmail: (email, pass) async {
          return const SignInFailure('User already registered with this email.');
        },
      );

      await tester.pumpWidget(
        createTestWidget(
          EmailSignupPage(
            signUpWithEmailUseCase: SignUpWithEmailUseCase(signInRepository: mockRepo),
          ),
        ),
      );

      await tester.enterText(find.byKey(const ValueKey('signup-email-input')), 'existing@tnyx.fit');
      await tester.enterText(find.byKey(const ValueKey('signup-password-input')), 'Pass123456');
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('signup-submit-button')));
      await tester.pump();

      expect(find.text('User already registered with this email.'), findsOneWidget);
    });
  });
}

class FakeAuthSignInRepository implements AuthSignInRepository {
  FakeAuthSignInRepository({
    this.onSignUpWithEmail,
  });

  final Future<SignInResult> Function(String email, String password)? onSignUpWithEmail;

  @override
  Future<SignInResult> signUpWithEmailPassword({
    required String email,
    required String password,
    String? name,
  }) async {
    if (onSignUpWithEmail != null) {
      return onSignUpWithEmail!(email, password);
    }
    return const SignInSuccess(AuthSession(userId: 'usr-1'));
  }

  @override
  Future<SignInResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async => const SignInSuccess(AuthSession(userId: 'usr-1'));

  @override
  Future<SignInResult> signInWithGoogle() async =>
      const SignInSuccess(AuthSession(userId: 'usr-1'));

  @override
  Future<SignInResult> sendPasswordResetEmail(String email) async =>
      const SignInSuccess(AuthSession(userId: ''));

  @override
  Future<SignInResult> signInWithOtp({
    required String email,
    required String token,
  }) async => const SignInSuccess(AuthSession(userId: 'usr-1'));
}
