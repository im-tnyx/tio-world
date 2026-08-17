import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_auth/auth.dart';

void main() {
  testWidgets('Google signup shows loading only on the Google action',
      (tester) async {
    final repository = _PendingGoogleAuthRepository();

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: EmailSignupPage(
          signInWithGoogleUseCase:
              SignInWithGoogleUseCase(signInRepository: repository),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('signup-email-input')),
      'user@tnyx.fit',
    );
    await tester.enterText(
      find.byKey(const ValueKey('signup-password-input')),
      'Pass123456',
    );
    await tester.pump();

    await tester.ensureVisible(
      find.byKey(const ValueKey('signup-google-button')),
    );
    await tester.tap(find.byKey(const ValueKey('signup-google-button')));
    await tester.pump();

    final emailButton = tester.widget<TioButton>(
      find.byKey(const ValueKey('signup-submit-button')),
    );
    final googleButton = tester.widget<TioSocialButton>(
      find.byKey(const ValueKey('signup-google-button')),
    );

    expect(emailButton.loading, isFalse);
    expect(emailButton.enabled, isFalse);
    expect(googleButton.loading, isTrue);

    repository.googleResult.complete(
      const SignInSuccess(AuthSession(userId: 'google-user')),
    );
    await tester.pump();
  });
}

class _PendingGoogleAuthRepository
    implements AuthSignInRepository, GoogleSignInIntentRepository {
  final Completer<SignInResult> googleResult = Completer<SignInResult>();

  @override
  Future<SignInResult> signInWithGoogleForIntent({
    required GoogleSignInIntent intent,
  }) {
    return googleResult.future;
  }

  @override
  Future<SignInResult> signInWithGoogle() => googleResult.future;

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
  Future<SignInResult> sendPasswordResetEmail(String email) async =>
      const SignInSuccess(AuthSession(userId: ''));

  @override
  Future<SignInResult> signInWithOtp({
    required String email,
    required String token,
  }) async => const SignInSuccess(AuthSession(userId: 'otp-user'));
}
