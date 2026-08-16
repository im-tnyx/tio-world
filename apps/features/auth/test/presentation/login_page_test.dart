import 'dart:async';

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

  TioButton submitButton(WidgetTester tester) =>
      tester.widget<TioButton>(find.byKey(const ValueKey('login-submit-button')));

  TioSocialButton googleButton(WidgetTester tester) => tester.widget<TioSocialButton>(
        find.byKey(const ValueKey('login-google-button')),
      );

  TioSocialButton truecallerButton(WidgetTester tester) => tester.widget<TioSocialButton>(
        find.byKey(const ValueKey('login-truecaller-button')),
      );

  Future<void> enterValidCredentials(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const ValueKey('login-email-input')),
      'test@tnyx.fit',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password-input')),
      'Password123!',
    );
    await tester.pump();
  }

  group('LoginPage', () {
    testWidgets('renders all core UI elements matching tnyxhub design', (tester) async {
      await tester.pumpWidget(createTestWidget(const LoginPage()));

      expect(find.text('Login'), findsNWidgets(2));
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

      expect(submitButton(tester).enabled, isFalse);

      await tester.enterText(
        find.byKey(const ValueKey('login-email-input')),
        'invalid-email',
      );
      await tester.enterText(
        find.byKey(const ValueKey('login-password-input')),
        'secret',
      );
      await tester.pump();
      expect(submitButton(tester).enabled, isFalse);

      await tester.enterText(
        find.byKey(const ValueKey('login-email-input')),
        'user@example.com',
      );
      await tester.pump();
      expect(submitButton(tester).enabled, isTrue);
    });

    testWidgets('email success emits callback and keeps LoginPage destination-neutral', (tester) async {
      var emailSubmitted = '';
      var passwordSubmitted = '';
      SignInSuccess? success;

      final mockRepo = FakeAuthSignInRepository(
        onSignInWithEmail: (email, pass) async {
          emailSubmitted = email;
          passwordSubmitted = pass;
          return const SignInSuccess(
            AuthSession(userId: 'usr-1', email: 'user@example.com'),
          );
        },
      );

      await tester.pumpWidget(
        createTestWidget(
          LoginPage(
            signInWithEmailUseCase: SignInWithEmailUseCase(signInRepository: mockRepo),
            onSignInSuccess: (result) => success = result,
          ),
        ),
      );

      await enterValidCredentials(tester);
      await tester.tap(find.byKey(const ValueKey('login-submit-button')));
      await tester.pump();

      expect(emailSubmitted, 'test@tnyx.fit');
      expect(passwordSubmitted, 'Password123!');
      expect(success?.session.userId, 'usr-1');
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('google success emits callback and keeps LoginPage destination-neutral', (tester) async {
      SignInSuccess? success;
      final mockRepo = FakeAuthSignInRepository(
        onSignInWithGoogle: () async =>
            const SignInSuccess(AuthSession(userId: 'google-user')),
      );

      await tester.pumpWidget(
        createTestWidget(
          LoginPage(
            signInWithGoogleUseCase: SignInWithGoogleUseCase(signInRepository: mockRepo),
            onSignInSuccess: (result) => success = result,
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('login-google-button')));
      await tester.pump();

      expect(success?.session.userId, 'google-user');
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('email request shows only Login loading and conflict-gates social actions', (tester) async {
      final pending = Completer<SignInResult>();
      final mockRepo = FakeAuthSignInRepository(
        onSignInWithEmail: (_, __) => pending.future,
      );

      await tester.pumpWidget(
        createTestWidget(
          LoginPage(
            signInWithEmailUseCase: SignInWithEmailUseCase(signInRepository: mockRepo),
          ),
        ),
      );
      await enterValidCredentials(tester);

      await tester.tap(find.byKey(const ValueKey('login-submit-button')));
      await tester.pump();

      expect(submitButton(tester).loading, isTrue);
      expect(googleButton(tester).loading, isFalse);
      expect(googleButton(tester).enabled, isFalse);
      expect(truecallerButton(tester).loading, isFalse);
      expect(truecallerButton(tester).enabled, isFalse);

      pending.complete(const SignInCancelled());
      await tester.pump();

      expect(submitButton(tester).loading, isFalse);
      expect(googleButton(tester).enabled, isTrue);
      expect(truecallerButton(tester).enabled, isTrue);
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('Google request shows only Google loading and conflict-gates other actions', (tester) async {
      final pending = Completer<SignInResult>();
      final mockRepo = FakeAuthSignInRepository(
        onSignInWithGoogle: () => pending.future,
      );

      await tester.pumpWidget(
        createTestWidget(
          LoginPage(
            signInWithGoogleUseCase: SignInWithGoogleUseCase(signInRepository: mockRepo),
          ),
        ),
      );
      await enterValidCredentials(tester);

      await tester.tap(find.byKey(const ValueKey('login-google-button')));
      await tester.pump();

      expect(googleButton(tester).loading, isTrue);
      expect(submitButton(tester).loading, isFalse);
      expect(submitButton(tester).enabled, isFalse);
      expect(truecallerButton(tester).loading, isFalse);
      expect(truecallerButton(tester).enabled, isFalse);

      pending.complete(const SignInCancelled());
      await tester.pump();

      expect(googleButton(tester).loading, isFalse);
      expect(submitButton(tester).enabled, isTrue);
      expect(truecallerButton(tester).enabled, isTrue);
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('unavailable Truecaller stays on Login and shows informational feedback', (tester) async {
      var successCount = 0;
      await tester.pumpWidget(
        createTestWidget(
          LoginPage(onSignInSuccess: (_) => successCount++),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('login-truecaller-button')));
      await tester.pump();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(successCount, 0);
      expect(find.text('Truecaller sign-in is not available yet.'), findsOneWidget);
      expect(truecallerButton(tester).loading, isFalse);
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

      await tester.enterText(
        find.byKey(const ValueKey('login-email-input')),
        'test@tnyx.fit',
      );
      await tester.enterText(
        find.byKey(const ValueKey('login-password-input')),
        'WrongPass',
      );
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
    return const SignInSuccess(
      AuthSession(userId: 'usr-1', email: 'user@example.com'),
    );
  }

  @override
  Future<SignInResult> signInWithGoogle() async {
    if (onSignInWithGoogle != null) {
      return onSignInWithGoogle!();
    }
    return const SignInSuccess(
      AuthSession(userId: 'usr-1', email: 'user@example.com'),
    );
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
