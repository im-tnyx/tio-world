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

  group('LoginPage Phone-first auth entry', () {
    testWidgets('opens in Phone mode with reciprocal round actions',
        (tester) async {
      await tester.pumpWidget(createTestWidget(const LoginPage()));

      expect(find.byKey(const ValueKey('login-phone-input')), findsOneWidget);
      expect(find.byKey(const ValueKey('login-email-input')), findsNothing);
      expect(find.byKey(const ValueKey('login-google-round-action')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('login-truecaller-round-action')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('login-mode-round-action')), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Truecaller'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Phone'), findsNothing);
    });

    testWidgets('Email and Phone switch on the same LoginPage', (tester) async {
      await tester.pumpWidget(createTestWidget(const LoginPage()));

      await tester.tap(find.byKey(const ValueKey('login-mode-round-action')));
      await tester.pump();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byKey(const ValueKey('login-phone-input')), findsNothing);
      expect(find.byKey(const ValueKey('login-email-input')), findsOneWidget);
      expect(find.byKey(const ValueKey('login-password-input')), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('Email'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('login-mode-round-action')));
      await tester.pump();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byKey(const ValueKey('login-phone-input')), findsOneWidget);
      expect(find.byKey(const ValueKey('login-email-input')), findsNothing);
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('explicit Email mode preserves Email + Password login',
        (tester) async {
      String? submittedEmail;
      String? submittedPassword;
      SignInSuccess? success;
      final repository = _FakeAuthSignInRepository(
        onEmail: (email, password) async {
          submittedEmail = email;
          submittedPassword = password;
          return const SignInSuccess(
            AuthSession(userId: 'email-user', email: 'user@example.com'),
          );
        },
      );

      await tester.pumpWidget(
        createTestWidget(
          LoginPage(
            initialMode: AuthEntryMode.email,
            signInWithEmailUseCase:
                SignInWithEmailUseCase(signInRepository: repository),
            onSignInSuccess: (result) => success = result,
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('login-email-input')),
        'user@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('login-password-input')),
        'Password123!',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('login-submit-button')));
      await tester.pump();

      expect(submittedEmail, 'user@example.com');
      expect(submittedPassword, 'Password123!');
      expect(success?.session.userId, 'email-user');
    });

    testWidgets('Phone Login requests login intent and authenticates only on verify',
        (tester) async {
      final phoneRepository = _FakePhoneOtpAuthRepository();
      SignInSuccess? success;

      await tester.pumpWidget(
        createTestWidget(
          LoginPage(
            requestPhoneOtpUseCase:
                RequestPhoneOtpUseCase(repository: phoneRepository),
            resendPhoneOtpUseCase:
                ResendPhoneOtpUseCase(repository: phoneRepository),
            verifyPhoneOtpUseCase:
                VerifyPhoneOtpUseCase(repository: phoneRepository),
            onSignInSuccess: (result) => success = result,
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('login-phone-input')),
        '9876543210',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('login-phone-send-code')));
      await tester.pump();

      expect(phoneRepository.lastIntent, PhoneOtpIntent.login);
      expect(phoneRepository.lastRequestedPhone, '+919876543210');
      expect(success, isNull);
      expect(find.byKey(const ValueKey('login-phone-otp-input')), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('login-phone-otp-input')),
        '123456',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('login-phone-verify-code')));
      await tester.pump();

      expect(phoneRepository.lastVerifiedToken, '123456');
      expect(success?.session.userId, 'phone-user');
    });

    testWidgets('Google remains available from Phone mode', (tester) async {
      SignInSuccess? success;
      final repository = _FakeAuthSignInRepository(
        onGoogle: () async =>
            const SignInSuccess(AuthSession(userId: 'google-user')),
      );

      await tester.pumpWidget(
        createTestWidget(
          LoginPage(
            signInWithGoogleUseCase:
                SignInWithGoogleUseCase(signInRepository: repository),
            onSignInSuccess: (result) => success = result,
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('login-google-round-action')));
      await tester.pump();

      expect(success?.session.userId, 'google-user');
    });

    testWidgets('unavailable Truecaller stays on Login and reports feedback',
        (tester) async {
      await tester.pumpWidget(createTestWidget(const LoginPage()));

      await tester.tap(
        find.byKey(const ValueKey('login-truecaller-round-action')),
      );
      await tester.pump();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(
        find.text('Truecaller sign-in is not available yet.'),
        findsOneWidget,
      );
    });
  });
}

class _FakePhoneOtpAuthRepository implements PhoneOtpAuthRepository {
  PhoneOtpIntent? lastIntent;
  String? lastRequestedPhone;
  String? lastVerifiedToken;

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
    lastVerifiedToken = token;
    return SignInSuccess(
      AuthSession(
        userId: 'phone-user',
        phone: phone,
        isPhoneVerified: true,
      ),
    );
  }
}

class _FakeAuthSignInRepository implements AuthSignInRepository {
  _FakeAuthSignInRepository({this.onEmail, this.onGoogle});

  final Future<SignInResult> Function(String email, String password)? onEmail;
  final Future<SignInResult> Function()? onGoogle;

  @override
  Future<SignInResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return onEmail?.call(email, password) ??
        const SignInSuccess(AuthSession(userId: 'email-user'));
  }

  @override
  Future<SignInResult> signInWithGoogle() async {
    return onGoogle?.call() ??
        const SignInSuccess(AuthSession(userId: 'google-user'));
  }

  @override
  Future<SignInResult> signUpWithEmailPassword({
    required String email,
    required String password,
    String? name,
  }) async => const SignInSuccess(AuthSession(userId: 'signup-user'));

  @override
  Future<PasswordResetRequestResult> sendPasswordResetEmail(String email) async =>
      const PasswordResetRequestAccepted();

  @override
  Future<SignInResult> signInWithOtp({
    required String email,
    required String token,
  }) async => const SignInSuccess(AuthSession(userId: 'otp-user'));
}
