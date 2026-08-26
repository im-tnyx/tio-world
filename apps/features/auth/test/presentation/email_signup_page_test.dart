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

  group('EmailSignupPage Phone-first auth entry', () {
    testWidgets('opens in Phone mode with reciprocal round actions',
        (tester) async {
      await tester.pumpWidget(createTestWidget(const EmailSignupPage()));

      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.byKey(const ValueKey('signup-back-button')), findsOneWidget);
      expect(find.byKey(const ValueKey('signup-phone-input')), findsOneWidget);
      expect(find.byKey(const ValueKey('signup-email-input')), findsNothing);
      expect(
        find.byKey(const ValueKey('signup-google-round-action')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('signup-truecaller-round-action')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('signup-mode-round-action')),
        findsOneWidget,
      );
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Truecaller'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.byType(TioTermsDisclaimer), findsOneWidget);
      expect(find.byKey(const ValueKey('signup-login-link')), findsOneWidget);
    });

    testWidgets('Email and Phone switch on the same Signup page',
        (tester) async {
      await tester.pumpWidget(createTestWidget(const EmailSignupPage()));

      await tester.tap(find.byKey(const ValueKey('signup-mode-round-action')));
      await tester.pump();

      expect(find.byType(EmailSignupPage), findsOneWidget);
      expect(find.byKey(const ValueKey('signup-phone-input')), findsNothing);
      expect(find.byKey(const ValueKey('signup-email-input')), findsOneWidget);
      expect(find.byKey(const ValueKey('signup-password-input')), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('signup-mode-round-action')));
      await tester.pump();

      expect(find.byType(EmailSignupPage), findsOneWidget);
      expect(find.byKey(const ValueKey('signup-phone-input')), findsOneWidget);
      expect(find.byKey(const ValueKey('signup-email-input')), findsNothing);
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('Phone Signup requests create-user intent and authenticates only on verify',
        (tester) async {
      final phoneRepository = _FakePhoneOtpAuthRepository();
      SignInSuccess? success;

      await tester.pumpWidget(
        createTestWidget(
          EmailSignupPage(
            requestPhoneOtpUseCase:
                RequestPhoneOtpUseCase(repository: phoneRepository),
            resendPhoneOtpUseCase:
                ResendPhoneOtpUseCase(repository: phoneRepository),
            verifyPhoneOtpUseCase:
                VerifyPhoneOtpUseCase(repository: phoneRepository),
            onSignUpSuccess: (result) => success = result,
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('signup-phone-input')),
        '9876543210',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('signup-phone-send-code')));
      await tester.pump();

      expect(phoneRepository.lastIntent, PhoneOtpIntent.signup);
      expect(phoneRepository.lastRequestedPhone, '+919876543210');
      expect(success, isNull);
      expect(
        find.byKey(const ValueKey('signup-phone-otp-input')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey('signup-phone-otp-input')),
        '123456',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('signup-phone-verify-code')));
      await tester.pump();

      expect(phoneRepository.lastVerifiedPhone, '+919876543210');
      expect(phoneRepository.lastToken, '123456');
      expect(success?.session.userId, 'phone-user');
    });

    testWidgets('keeps account switch footer on the login viewport contract',
        (tester) async {
      await tester.pumpWidget(createTestWidget(const EmailSignupPage()));

      final scaffold = tester.widget<Scaffold>(
        find.descendant(
          of: find.byType(EmailSignupPage),
          matching: find.byType(Scaffold),
        ),
      );
      expect(scaffold.resizeToAvoidBottomInset, isFalse);

      final safeArea = tester.widget<SafeArea>(
        find.descendant(
          of: find.byType(EmailSignupPage),
          matching: find.byType(SafeArea),
        ),
      );
      expect(safeArea.maintainBottomViewPadding, isTrue);

      final footer = tester.widget<Padding>(
        find.byKey(const ValueKey('signup-auth-switch-footer')),
      );
      expect(footer.padding, const EdgeInsets.only(top: TioSpacing.sm));
    });
  });

  group('EmailSignupPage Email mode compatibility', () {
    testWidgets('renders Email + Password on explicit Email mode',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const EmailSignupPage(initialMode: AuthEntryMode.email),
        ),
      );

      expect(find.byKey(const ValueKey('signup-email-input')), findsOneWidget);
      expect(find.byKey(const ValueKey('signup-password-input')), findsOneWidget);
      expect(find.byKey(const ValueKey('signup-submit-button')), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
    });

    testWidgets('password visibility toggle changes obscureText', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const EmailSignupPage(initialMode: AuthEntryMode.email),
        ),
      );

      final passwordField = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const ValueKey('signup-password-input')),
          matching: find.byType(EditableText),
        ),
      );
      expect(passwordField.obscureText, isTrue);

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

    testWidgets('create account button is disabled when fields are empty or invalid',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const EmailSignupPage(initialMode: AuthEntryMode.email),
        ),
      );

      expect(
        tester
            .widget<TioButton>(
              find.byKey(const ValueKey('signup-submit-button')),
            )
            .enabled,
        isFalse,
      );

      await tester.enterText(
        find.byKey(const ValueKey('signup-email-input')),
        'user@tnyx.fit',
      );
      await tester.enterText(
        find.byKey(const ValueKey('signup-password-input')),
        '12345',
      );
      await tester.pump();
      expect(
        tester
            .widget<TioButton>(
              find.byKey(const ValueKey('signup-submit-button')),
            )
            .enabled,
        isFalse,
      );

      await tester.enterText(
        find.byKey(const ValueKey('signup-password-input')),
        '123456',
      );
      await tester.pump();
      expect(
        tester
            .widget<TioButton>(
              find.byKey(const ValueKey('signup-submit-button')),
            )
            .enabled,
        isTrue,
      );
    });

    testWidgets('calls signUpWithEmailUseCase without mapping username to name',
        (tester) async {
      var emailSubmitted = '';
      var passwordSubmitted = '';
      final mockRepo = FakeAuthSignInRepository(
        onSignUpWithEmail: (email, pass) async {
          emailSubmitted = email;
          passwordSubmitted = pass;
          return const SignInSuccess(
            AuthSession(userId: 'usr-2', email: 'new@tnyx.fit'),
          );
        },
      );

      await tester.pumpWidget(
        createTestWidget(
          EmailSignupPage(
            initialMode: AuthEntryMode.email,
            signUpWithEmailUseCase:
                SignUpWithEmailUseCase(signInRepository: mockRepo),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('signup-email-input')),
        'new@tnyx.fit',
      );
      await tester.enterText(
        find.byKey(const ValueKey('signup-password-input')),
        'Pass123456',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('signup-submit-button')));
      await tester.pump();

      expect(emailSubmitted, 'new@tnyx.fit');
      expect(passwordSubmitted, 'Pass123456');
      expect(mockRepo.lastSignUpName, isNull);
    });

    testWidgets('Google signup explicitly uses signup-or-existing intent',
        (tester) async {
      final repository = IntentAwareFakeAuthRepository();
      SignInSuccess? success;

      await tester.pumpWidget(
        createTestWidget(
          EmailSignupPage(
            signInWithGoogleUseCase:
                SignInWithGoogleUseCase(signInRepository: repository),
            onSignUpSuccess: (result) => success = result,
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('signup-google-round-action')),
      );
      await tester.pump();

      expect(repository.lastIntent, GoogleSignInIntent.signupOrExisting);
      expect(success?.session.userId, 'google-user');
    });

    testWidgets('displays error banner when Email sign up fails', (tester) async {
      final mockRepo = FakeAuthSignInRepository(
        onSignUpWithEmail: (email, pass) async => const SignInFailure(
          'User already registered with this email.',
        ),
      );

      await tester.pumpWidget(
        createTestWidget(
          EmailSignupPage(
            initialMode: AuthEntryMode.email,
            signUpWithEmailUseCase:
                SignUpWithEmailUseCase(signInRepository: mockRepo),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('signup-email-input')),
        'existing@tnyx.fit',
      );
      await tester.enterText(
        find.byKey(const ValueKey('signup-password-input')),
        'Pass123456',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('signup-submit-button')));
      await tester.pump();

      expect(
        find.text('User already registered with this email.'),
        findsOneWidget,
      );
    });
  });
}

class _FakePhoneOtpAuthRepository implements PhoneOtpAuthRepository {
  PhoneOtpIntent? lastIntent;
  String? lastRequestedPhone;
  String? lastVerifiedPhone;
  String? lastToken;

  @override
  Future<PhoneOtpRequestResult> requestCode({
    required String phone,
    required PhoneOtpIntent intent,
  }) async {
    lastIntent = intent;
    lastRequestedPhone = phone;
    return PhoneOtpCodeSent(phone);
  }

  @override
  Future<PhoneOtpRequestResult> resendCode({
    required String phone,
    required PhoneOtpIntent intent,
  }) async {
    lastIntent = intent;
    lastRequestedPhone = phone;
    return PhoneOtpCodeSent(phone);
  }

  @override
  Future<SignInResult> verifyCode({
    required String phone,
    required String token,
  }) async {
    lastVerifiedPhone = phone;
    lastToken = token;
    return SignInSuccess(
      AuthSession(
        userId: 'phone-user',
        phone: phone,
        isPhoneVerified: true,
      ),
    );
  }
}

class FakeAuthSignInRepository implements AuthSignInRepository {
  FakeAuthSignInRepository({this.onSignUpWithEmail});

  final Future<SignInResult> Function(String email, String password)?
      onSignUpWithEmail;
  String? lastSignUpName;

  @override
  Future<SignInResult> signUpWithEmailPassword({
    required String email,
    required String password,
    String? name,
  }) async {
    lastSignUpName = name;
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
  Future<PasswordResetRequestResult> sendPasswordResetEmail(String email) async =>
      const PasswordResetRequestAccepted();

  @override
  Future<SignInResult> signInWithOtp({
    required String email,
    required String token,
  }) async => const SignInSuccess(AuthSession(userId: 'usr-1'));
}

class IntentAwareFakeAuthRepository
    implements AuthSignInRepository, GoogleSignInIntentRepository {
  GoogleSignInIntent? lastIntent;

  @override
  Future<SignInResult> signInWithGoogleForIntent({
    required GoogleSignInIntent intent,
  }) async {
    lastIntent = intent;
    return const SignInSuccess(AuthSession(userId: 'google-user'));
  }

  @override
  Future<SignInResult> signInWithGoogle() async =>
      const SignInSuccess(AuthSession(userId: 'legacy-google-user'));

  @override
  Future<SignInResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async => const SignInSuccess(AuthSession(userId: 'email-user'));

  @override
  Future<SignInResult> signUpWithEmailPassword({
    required String email,
    required String password,
    String? name,
  }) async => const SignInSuccess(AuthSession(userId: 'email-user'));

  @override
  Future<PasswordResetRequestResult> sendPasswordResetEmail(String email) async =>
      const PasswordResetRequestAccepted();

  @override
  Future<SignInResult> signInWithOtp({
    required String email,
    required String token,
  }) async => const SignInSuccess(AuthSession(userId: 'otp-user'));
}
