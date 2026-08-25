import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_auth/auth.dart';

void main() {
  group('password reset request typing', () {
    test('Supabase request success is accepted without an AuthSession', () async {
      final goTrue = _ResetGoTrueClient();
      final repository = SupabaseAuthSignInRepository(
        client: _ResetSupabaseClient(goTrue),
      );

      final result = await repository.sendPasswordResetEmail(
        '  User@Test.COM  ',
      );

      expect(result, const PasswordResetRequestAccepted());
      expect(result, isNot(isA<SignInResult>()));
      expect(goTrue.resetCalls, 1);
      expect(goTrue.lastEmail, 'User@Test.COM');
    });

    test('Supabase reset AuthException preserves message and code', () async {
      final goTrue = _ResetGoTrueClient(
        exceptionToThrow: const AuthException(
          'Reset request rejected',
          statusCode: '429',
        ),
      );
      final repository = SupabaseAuthSignInRepository(
        client: _ResetSupabaseClient(goTrue),
      );

      final result = await repository.sendPasswordResetEmail('user@test.com');

      expect(
        result,
        const PasswordResetRequestFailure(
          'Reset request rejected',
          code: '429',
        ),
      );
      expect(result, isNot(isA<SignInResult>()));
    });

    test('use case delegates dedicated request result without sign-in semantics',
        () async {
      final repository = _PasswordResetRepository(
        result: const PasswordResetRequestAccepted(),
      );
      final useCase = SendPasswordResetEmailUseCase(
        signInRepository: repository,
      );

      final result = await useCase('person@example.com');

      expect(result, const PasswordResetRequestAccepted());
      expect(result, isNot(isA<SignInResult>()));
      expect(repository.lastResetEmail, 'person@example.com');
    });
  });

  group('ForgotPasswordPage', () {
    testWidgets('accepted request shows privacy-safe inbox state', (tester) async {
      final repository = _PasswordResetRepository(
        result: const PasswordResetRequestAccepted(),
      );

      await tester.pumpWidget(
        _testApp(
          ForgotPasswordPage(
            sendPasswordResetEmailUseCase: SendPasswordResetEmailUseCase(
              signInRepository: repository,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'person@example.com');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pump();

      expect(find.text('Check your inbox'), findsOneWidget);
      expect(
        find.textContaining('If an account can receive a reset email at'),
        findsOneWidget,
      );
      expect(find.textContaining('We sent a password reset link'), findsNothing);
    });

    testWidgets('request failure shows error and never enters success state',
        (tester) async {
      final repository = _PasswordResetRepository(
        result: const PasswordResetRequestFailure(
          'Password reset is temporarily unavailable.',
          code: 'reset_unavailable',
        ),
      );

      await tester.pumpWidget(
        _testApp(
          ForgotPasswordPage(
            sendPasswordResetEmailUseCase: SendPasswordResetEmailUseCase(
              signInRepository: repository,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'person@example.com');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pump();

      expect(
        find.text('Password reset is temporarily unavailable.'),
        findsOneWidget,
      );
      expect(find.text('Check your inbox'), findsNothing);
    });

    testWidgets('missing reset dependency fails closed instead of simulating success',
        (tester) async {
      await tester.pumpWidget(_testApp(const ForgotPasswordPage()));

      await tester.enterText(find.byType(TextFormField), 'person@example.com');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pump();

      expect(
        find.text('Password reset is unavailable right now.'),
        findsOneWidget,
      );
      expect(find.text('Check your inbox'), findsNothing);
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

class _ResetSupabaseClient extends Fake implements SupabaseClient {
  _ResetSupabaseClient(this.goTrue);

  final GoTrueClient goTrue;

  @override
  GoTrueClient get auth => goTrue;
}

class _ResetGoTrueClient extends Fake implements GoTrueClient {
  _ResetGoTrueClient({this.exceptionToThrow});

  final Object? exceptionToThrow;
  int resetCalls = 0;
  String? lastEmail;

  @override
  Future<void> resetPasswordForEmail(
    String email, {
    String? redirectTo,
    String? captchaToken,
  }) async {
    resetCalls++;
    lastEmail = email;
    final error = exceptionToThrow;
    if (error != null) throw error;
  }
}

class _PasswordResetRepository implements AuthSignInRepository {
  _PasswordResetRepository({required this.result});

  final PasswordResetRequestResult result;
  String? lastResetEmail;

  @override
  Future<PasswordResetRequestResult> sendPasswordResetEmail(String email) async {
    lastResetEmail = email;
    return result;
  }

  @override
  Future<SignInResult> signInWithGoogle() async => const SignInCancelled();

  @override
  Future<SignInResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async => const SignInCancelled();

  @override
  Future<SignInResult> signUpWithEmailPassword({
    required String email,
    required String password,
    String? name,
  }) async => const SignInCancelled();

  @override
  Future<SignInResult> signInWithOtp({
    required String email,
    required String token,
  }) async => const SignInCancelled();
}
