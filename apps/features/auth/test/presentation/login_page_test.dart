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

  group('LoginPage', () {
    testWidgets('renders all core UI elements matching tnyxhub design', (tester) async {
      await tester.pumpWidget(createTestWidget(const LoginPage()));

      expect(find.text('Login'), findsNWidgets(2)); // Title and Login Button
      expect(find.byKey(const ValueKey('login-back-button')), findsOneWidget);
      expect(find.byKey(const ValueKey('login-email-input')), findsOneWidget);
      expect(find.byKey(const ValueKey('login-password-input')), findsOneWidget);
      expect(find.byKey(const ValueKey('login-forgot-password-link')), findsOneWidget);
      expect(find.byKey(const ValueKey('login-submit-button')), findsOneWidget);
      expect(find.text('OR'), findsOneWidget);
      expect(find.byKey(const ValueKey('login-google-button')), findsOneWidget);
      expect(find.byKey(const ValueKey('login-truecaller-button')), findsOneWidget);
      expect(find.byKey(const ValueKey('login-signup-link')), findsOneWidget);
      expect(find.text("Don't have an account? "), findsOneWidget);
    });

    testWidgets('password visibility toggle changes obscureText', (tester) async {
      await tester.pumpWidget(createTestWidget(const LoginPage()));

      final passwordField = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const ValueKey('login-password-input')),
          matching: find.byType(EditableText),
        ),
      );
      expect(passwordField.obscureText, isTrue);

      // Tap visibility toggle icon
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      final updatedPasswordField = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const ValueKey('login-password-input')),
          matching: find.byType(EditableText),
        ),
      );
      expect(updatedPasswordField.obscureText, isFalse);
    });

    testWidgets('login submit button is disabled when fields are empty or invalid', (tester) async {
      await tester.pumpWidget(createTestWidget(const LoginPage()));

      final submitBtn = tester.widget<TioButton>(find.byKey(const ValueKey('login-submit-button')));
      expect(submitBtn.enabled, isFalse);

      // Enter invalid email
      await tester.enterText(find.byKey(const ValueKey('login-email-input')), 'invalid-email');
      await tester.enterText(find.byKey(const ValueKey('login-password-input')), 'secret');
      await tester.pump();

      final submitBtnInvalid = tester.widget<TioButton>(find.byKey(const ValueKey('login-submit-button')));
      expect(submitBtnInvalid.enabled, isFalse);

      // Enter valid email
      await tester.enterText(find.byKey(const ValueKey('login-email-input')), 'user@example.com');
      await tester.pump();

      final submitBtnValid = tester.widget<TioButton>(find.byKey(const ValueKey('login-submit-button')));
      expect(submitBtnValid.enabled, isTrue);
    });

    testWidgets('calls signInWithEmailUseCase when login button is tapped with valid credentials', (tester) async {
      var emailSubmitted = '';
      var passwordSubmitted = '';

      final mockRepo = FakeAuthSignInRepository(
        onSignInWithEmail: (email, pass) async {
          emailSubmitted = email;
          passwordSubmitted = pass;
          return const SignInSuccess(AuthSession(userId: 'usr-1', email: 'user@example.com'));
        },
      );

      await tester.pumpWidget(
        createTestWidget(
          LoginPage(
            signInWithEmailUseCase: SignInWithEmailUseCase(signInRepository: mockRepo),
          ),
        ),
      );

      await tester.enterText(find.byKey(const ValueKey('login-email-input')), 'test@tnyx.fit');
      await tester.enterText(find.byKey(const ValueKey('login-password-input')), 'Password123!');
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('login-submit-button')));
      await tester.pump();

      expect(emailSubmitted, 'test@tnyx.fit');
      expect(passwordSubmitted, 'Password123!');
    });

    testWidgets('displays error banner when sign in fails', (tester) async {
      final mockRepo = FakeAuthSignInRepository(
        onSignInWithEmail: (email, pass) async {
          return const SignInFailure('Invalid login credentials.');
        },
      );

      await tester.pumpWidget(
        createTestWidget(
          LoginPage(
            signInWithEmailUseCase: SignInWithEmailUseCase(signInRepository: mockRepo),
          ),
        ),
      );

      await tester.enterText(find.byKey(const ValueKey('login-email-input')), 'test@tnyx.fit');
      await tester.enterText(find.byKey(const ValueKey('login-password-input')), 'WrongPass');
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('login-submit-button')));
      await tester.pump();

      expect(find.text('Invalid login credentials.'), findsOneWidget);
    });
  });
}

class FakeAuthSignInRepository implements AuthSignInRepository {
  FakeAuthSignInRepository({
    this.onSignInWithEmail,
    this.onSignInWithGoogle,
  });

  final Future<SignInResult> Function(String email, String password)? onSignInWithEmail;
  final Future<SignInResult> Function()? onSignInWithGoogle;

  @override
  Future<SignInResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (onSignInWithEmail != null) {
      return onSignInWithEmail!(email, password);
    }
    return const SignInSuccess(AuthSession(userId: 'usr-1', email: 'user@example.com'));
  }

  @override
  Future<SignInResult> signInWithGoogle() async {
    if (onSignInWithGoogle != null) {
      return onSignInWithGoogle!();
    }
    return const SignInSuccess(AuthSession(userId: 'usr-1', email: 'user@example.com'));
  }

  @override
  Future<SignInResult> signUpWithEmailPassword({
    required String email,
    required String password,
    String? name,
  }) async => const SignInSuccess(AuthSession(userId: 'usr-1'));

  @override
  Future<SignInResult> sendPasswordResetEmail(String email) async =>
      const SignInSuccess(AuthSession(userId: ''));

  @override
  Future<SignInResult> signInWithOtp({
    required String email,
    required String token,
  }) async => const SignInSuccess(AuthSession(userId: 'usr-1'));
}
