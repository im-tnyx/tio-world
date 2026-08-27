import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_auth/auth.dart';

void main() {
  group('Email Signup confirmation return', () {
    test('Signup and resend both use the mobile callback redirect', () async {
      const user = User(
        id: 'pending-user',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-08-27T00:00:00.000Z',
        email: 'pending@example.com',
      );
      final auth = _FakeGoTrueClient(
        signUpResponse: AuthResponse(session: null, user: user),
      );
      final repository = SupabaseAuthSignInRepository(
        client: _FakeSupabaseClient(auth),
      );

      final result = await repository.signUpWithEmailPassword(
        email: ' Pending@Example.com ',
        password: 'password123',
      );
      await repository.resendSignupConfirmation(
        email: ' Pending@Example.com ',
      );

      expect(result, isA<SignInFailure>());
      expect((result as SignInFailure).code, 'email_confirmation_required');
      expect(auth.lastSignUpEmail, 'pending@example.com');
      expect(auth.lastSignUpRedirect, 'tio://login-callback');
      expect(auth.lastResendEmail, 'pending@example.com');
      expect(auth.lastResendType, OtpType.signup);
      expect(auth.lastResendRedirect, 'tio://login-callback');
    });

    testWidgets(
      'pending confirmation shows dedicated Tio verification state and resends safely',
      (tester) async {
        final repository = _PendingEmailAuthRepository();
        final useCase = SignUpWithEmailUseCase(signInRepository: repository);

        await tester.pumpWidget(
          _testApp(
            EmailSignupPage(
              initialMode: AuthEntryMode.email,
              signUpWithEmailUseCase: useCase,
            ),
          ),
        );

        await tester.enterText(
          find.byKey(const ValueKey('signup-email-input')),
          ' User@Example.com ',
        );
        await tester.enterText(
          find.byKey(const ValueKey('signup-password-input')),
          'password123',
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('signup-submit-button')));
        await tester.pump();

        expect(
          find.byKey(const ValueKey('signup-email-verification-view')),
          findsOneWidget,
        );
        expect(find.text('Tio'), findsOneWidget);
        expect(find.text('Please verify your email'), findsOneWidget);
        expect(find.byKey(const ValueKey('signup-resend-email')), findsOneWidget);
        expect(find.text('pending-signup'), findsNothing);

        await tester.tap(find.byKey(const ValueKey('signup-resend-email')));
        await tester.pump();

        expect(repository.lastResendEmail, 'user@example.com');
        expect(
          find.byKey(const ValueKey('signup-verification-message')),
          findsOneWidget,
        );
      },
    );

    testWidgets('actual Signup failures still use the error presentation',
        (tester) async {
      final repository = _FailureEmailAuthRepository();
      final useCase = SignUpWithEmailUseCase(signInRepository: repository);

      await tester.pumpWidget(
        _testApp(
          EmailSignupPage(
            initialMode: AuthEntryMode.email,
            signUpWithEmailUseCase: useCase,
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('signup-email-input')),
        'user@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('signup-password-input')),
        'password123',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('signup-submit-button')));
      await tester.pump();

      expect(find.text('Network unavailable.'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('signup-email-verification-view')),
        findsNothing,
      );
    });
  });
}

Widget _testApp(Widget child) {
  return MaterialApp(
    builder: (context, appChild) =>
        TioTheme(child: appChild ?? const SizedBox.shrink()),
    home: child,
  );
}

class _FakeSupabaseClient extends Fake implements SupabaseClient {
  _FakeSupabaseClient(this._auth);

  final GoTrueClient _auth;

  @override
  GoTrueClient get auth => _auth;
}

class _FakeGoTrueClient extends Fake implements GoTrueClient {
  _FakeGoTrueClient({required this.signUpResponse});

  final AuthResponse signUpResponse;
  String? lastSignUpEmail;
  String? lastSignUpRedirect;
  String? lastResendEmail;
  String? lastResendRedirect;
  OtpType? lastResendType;

  @override
  Future<AuthResponse> signUp({
    String? email,
    String? phone,
    required String password,
    String? emailRedirectTo,
    Map<String, dynamic>? data,
    String? captchaToken,
    OtpChannel channel = OtpChannel.sms,
  }) async {
    lastSignUpEmail = email;
    lastSignUpRedirect = emailRedirectTo;
    return signUpResponse;
  }

  @override
  Future<ResendResponse> resend({
    String? email,
    String? phone,
    required OtpType type,
    String? emailRedirectTo,
    String? captchaToken,
  }) async {
    lastResendEmail = email;
    lastResendType = type;
    lastResendRedirect = emailRedirectTo;
    return ResendResponse();
  }
}

class _PendingEmailAuthRepository
    implements AuthSignInRepository, EmailSignupConfirmationRepository {
  String? lastResendEmail;

  @override
  Future<SignInResult> signUpWithEmailPassword({
    required String email,
    required String password,
    String? name,
  }) async {
    return const SignInFailure(
      'pending-signup',
      code: 'email_confirmation_required',
    );
  }

  @override
  Future<void> resendSignupConfirmation({required String email}) async {
    lastResendEmail = email;
  }

  @override
  Future<SignInResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async => const SignInFailure('unused');

  @override
  Future<SignInResult> signInWithGoogle() async =>
      const SignInFailure('unused');

  @override
  Future<PasswordResetRequestResult> sendPasswordResetEmail(String email) async =>
      const PasswordResetRequestAccepted();

  @override
  Future<SignInResult> signInWithOtp({
    required String email,
    required String token,
  }) async => const SignInFailure('unused');
}

class _FailureEmailAuthRepository implements AuthSignInRepository {
  @override
  Future<SignInResult> signUpWithEmailPassword({
    required String email,
    required String password,
    String? name,
  }) async => const SignInFailure('Network unavailable.', code: 'network');

  @override
  Future<SignInResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async => const SignInFailure('unused');

  @override
  Future<SignInResult> signInWithGoogle() async =>
      const SignInFailure('unused');

  @override
  Future<PasswordResetRequestResult> sendPasswordResetEmail(String email) async =>
      const PasswordResetRequestAccepted();

  @override
  Future<SignInResult> signInWithOtp({
    required String email,
    required String token,
  }) async => const SignInFailure('unused');
}
