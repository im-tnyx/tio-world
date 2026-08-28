import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_auth/auth.dart';

void main() {
  group('SignUpWithEmailUseCase', () {
    test('canonicalizes Gmail before repository Signup', () async {
      final repository = RecordingAuthSignInRepository(
        signUpResult: const SignInFailure(
          'pending',
          code: 'email_confirmation_required',
        ),
      );
      final useCase = SignUpWithEmailUseCase(signInRepository: repository);

      await useCase(
        email: ' T.NYX+FIT@googlemail.com ',
        password: 'password123',
      );

      expect(repository.signUpCalls, 1);
      expect(repository.lastSignUpEmail, 'tnyx@gmail.com');
    });

    test('preserves non-Gmail plus tags before Signup', () async {
      final repository = RecordingAuthSignInRepository(
        signUpResult: const SignInFailure(
          'pending',
          code: 'email_confirmation_required',
        ),
      );
      final useCase = SignUpWithEmailUseCase(signInRepository: repository);

      await useCase(
        email: ' User.Name+Fit@Example.COM ',
        password: 'password123',
      );

      expect(repository.lastSignUpEmail, 'user.name+fit@example.com');
    });

    test('fresh pending and obfuscated duplicate have identical outcome',
        () async {
      final pendingRepository = RecordingAuthSignInRepository(
        signUpResult: const SignInFailure(
          'Check new@example.com to confirm your email before signing in.',
          code: 'email_confirmation_required',
        ),
      );
      final duplicateRepository = RecordingAuthSignInRepository(
        signUpResult: const SignInFailure(
          'This email is already registered. Please log in to continue.',
          code: 'user_already_exists',
        ),
      );

      final pendingResult = await SignUpWithEmailUseCase(
        signInRepository: pendingRepository,
      )(
        email: 'new@example.com',
        password: 'password123',
      );
      final duplicateResult = await SignUpWithEmailUseCase(
        signInRepository: duplicateRepository,
      )(
        email: 'new@example.com',
        password: 'password123',
      );

      expect(pendingResult, duplicateResult);
      expect(pendingResult, isA<SignInFailure>());
      expect(
        (pendingResult as SignInFailure).code,
        'email_confirmation_required',
      );
    });

    test('invalid Email fails before repository call', () async {
      final repository = RecordingAuthSignInRepository();
      final useCase = SignUpWithEmailUseCase(signInRepository: repository);

      final result = await useCase(
        email: 'not-an-email',
        password: 'password123',
      );

      expect(result, isA<SignInFailure>());
      expect((result as SignInFailure).code, 'invalid_email');
      expect(repository.signUpCalls, 0);
    });

    test('Signup timeout returns controlled retryable failure', () async {
      final pending = Completer<SignInResult>();
      final repository = RecordingAuthSignInRepository(
        signUpFuture: pending.future,
      );
      final useCase = SignUpWithEmailUseCase(
        signInRepository: repository,
        timeout: const Duration(milliseconds: 10),
      );

      final result = await useCase(
        email: 'new@example.com',
        password: 'password123',
      );

      expect(result, isA<SignInFailure>());
      expect((result as SignInFailure).code, 'email_signup_timeout');
    });

    test('authenticated Signup success is preserved', () async {
      const success = SignInSuccess(
        AuthSession(userId: 'usr-1', email: 'tnyx@gmail.com'),
      );
      final repository = RecordingAuthSignInRepository(signUpResult: success);
      final useCase = SignUpWithEmailUseCase(signInRepository: repository);

      final result = await useCase(
        email: 't.nyx+fit@gmail.com',
        password: 'password123',
      );

      expect(result, success);
      expect(repository.lastSignUpEmail, 'tnyx@gmail.com');
    });
  });

  group('SignInWithEmailUseCase', () {
    test('canonicalizes Gmail before password Login', () async {
      final repository = RecordingAuthSignInRepository(
        signInResult: const SignInFailure('invalid credentials'),
      );
      final useCase = SignInWithEmailUseCase(signInRepository: repository);

      await useCase(
        email: ' T.NYX+FIT@googlemail.com ',
        password: 'password123',
      );

      expect(repository.signInCalls, 1);
      expect(repository.lastSignInEmail, 'tnyx@gmail.com');
    });

    test('invalid Email fails before password Login', () async {
      final repository = RecordingAuthSignInRepository();
      final useCase = SignInWithEmailUseCase(signInRepository: repository);

      final result = await useCase(
        email: 'bad email@example.com',
        password: 'password123',
      );

      expect(result, isA<SignInFailure>());
      expect((result as SignInFailure).code, 'invalid_email');
      expect(repository.signInCalls, 0);
    });
  });
}

class RecordingAuthSignInRepository extends Fake
    implements AuthSignInRepository {
  RecordingAuthSignInRepository({
    this.signUpResult = const SignInFailure('not configured'),
    this.signInResult = const SignInFailure('not configured'),
    this.signUpFuture,
  });

  final SignInResult signUpResult;
  final SignInResult signInResult;
  final Future<SignInResult>? signUpFuture;

  int signUpCalls = 0;
  int signInCalls = 0;
  String? lastSignUpEmail;
  String? lastSignInEmail;

  @override
  Future<SignInResult> signUpWithEmailPassword({
    required String email,
    required String password,
    String? name,
  }) {
    signUpCalls++;
    lastSignUpEmail = email;
    return signUpFuture ?? Future.value(signUpResult);
  }

  @override
  Future<SignInResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    lastSignInEmail = email;
    return signInResult;
  }
}
