import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_auth/auth.dart';

void main() {
  group('Phone OTP use cases', () {
    test('request canonicalizes India national input for Signup', () async {
      final repository = FakePhoneOtpAuthRepository();
      final useCase = RequestPhoneOtpUseCase(repository: repository);

      final result = await useCase(
        phone: '98765 43210',
        intent: PhoneOtpIntent.signup,
      );

      expect(result, const PhoneOtpCodeSent('+919876543210'));
      expect(repository.lastRequestPhone, '+919876543210');
      expect(repository.lastRequestIntent, PhoneOtpIntent.signup);
    });

    test('request preserves explicit E.164 and Login intent', () async {
      final repository = FakePhoneOtpAuthRepository();
      final useCase = RequestPhoneOtpUseCase(repository: repository);

      await useCase(
        phone: '+14155552671',
        intent: PhoneOtpIntent.login,
      );

      expect(repository.lastRequestPhone, '+14155552671');
      expect(repository.lastRequestIntent, PhoneOtpIntent.login);
    });

    test('invalid phone fails before repository request', () async {
      final repository = FakePhoneOtpAuthRepository();
      final useCase = RequestPhoneOtpUseCase(repository: repository);

      final result = await useCase(
        phone: '123',
        intent: PhoneOtpIntent.signup,
      );

      expect(result, isA<PhoneOtpRequestFailure>());
      expect((result as PhoneOtpRequestFailure).code, 'invalid_phone');
      expect(repository.requestCalls, 0);
    });

    test('request timeout is controlled', () async {
      final pending = Completer<PhoneOtpRequestResult>();
      final repository = FakePhoneOtpAuthRepository(
        requestFuture: pending.future,
      );
      final useCase = RequestPhoneOtpUseCase(
        repository: repository,
        timeout: const Duration(milliseconds: 10),
      );

      final result = await useCase(
        phone: '9876543210',
        intent: PhoneOtpIntent.signup,
      );

      expect(result, isA<PhoneOtpRequestFailure>());
      expect(
        (result as PhoneOtpRequestFailure).code,
        'phone_otp_request_timeout',
      );
    });

    test('resend reuses canonical phone and intent', () async {
      final repository = FakePhoneOtpAuthRepository();
      final useCase = ResendPhoneOtpUseCase(repository: repository);

      final result = await useCase(
        phone: '919876543210',
        intent: PhoneOtpIntent.login,
      );

      expect(result, const PhoneOtpCodeSent('+919876543210'));
      expect(repository.lastResendPhone, '+919876543210');
      expect(repository.lastResendIntent, PhoneOtpIntent.login);
    });

    test('resend timeout is controlled', () async {
      final pending = Completer<PhoneOtpRequestResult>();
      final repository = FakePhoneOtpAuthRepository(
        resendFuture: pending.future,
      );
      final useCase = ResendPhoneOtpUseCase(
        repository: repository,
        timeout: const Duration(milliseconds: 10),
      );

      final result = await useCase(
        phone: '9876543210',
        intent: PhoneOtpIntent.signup,
      );

      expect(result, isA<PhoneOtpRequestFailure>());
      expect(
        (result as PhoneOtpRequestFailure).code,
        'phone_otp_resend_timeout',
      );
    });

    test('verify canonicalizes phone and trims token', () async {
      final repository = FakePhoneOtpAuthRepository(
        verifyResult: const SignInFailure('fixture', code: 'fixture'),
      );
      final useCase = VerifyPhoneOtpUseCase(repository: repository);

      final result = await useCase(
        phone: '9876543210',
        token: ' 123456 ',
      );

      expect(result, const SignInFailure('fixture', code: 'fixture'));
      expect(repository.lastVerifyPhone, '+919876543210');
      expect(repository.lastVerifyToken, '123456');
    });

    test('empty verify token fails before repository call', () async {
      final repository = FakePhoneOtpAuthRepository();
      final useCase = VerifyPhoneOtpUseCase(repository: repository);

      final result = await useCase(
        phone: '9876543210',
        token: '   ',
      );

      expect(result, isA<SignInFailure>());
      expect((result as SignInFailure).code, 'invalid_otp');
      expect(repository.verifyCalls, 0);
    });

    test('verify timeout is controlled', () async {
      final pending = Completer<SignInResult>();
      final repository = FakePhoneOtpAuthRepository(
        verifyFuture: pending.future,
      );
      final useCase = VerifyPhoneOtpUseCase(
        repository: repository,
        timeout: const Duration(milliseconds: 10),
      );

      final result = await useCase(
        phone: '9876543210',
        token: '123456',
      );

      expect(result, isA<SignInFailure>());
      expect((result as SignInFailure).code, 'phone_otp_verify_timeout');
    });
  });
}

final class FakePhoneOtpAuthRepository implements PhoneOtpAuthRepository {
  FakePhoneOtpAuthRepository({
    this.requestFuture,
    this.resendFuture,
    this.verifyFuture,
    this.verifyResult = const SignInFailure('unused'),
  });

  final Future<PhoneOtpRequestResult>? requestFuture;
  final Future<PhoneOtpRequestResult>? resendFuture;
  final Future<SignInResult>? verifyFuture;
  final SignInResult verifyResult;

  int requestCalls = 0;
  int resendCalls = 0;
  int verifyCalls = 0;
  String? lastRequestPhone;
  PhoneOtpIntent? lastRequestIntent;
  String? lastResendPhone;
  PhoneOtpIntent? lastResendIntent;
  String? lastVerifyPhone;
  String? lastVerifyToken;

  @override
  Future<PhoneOtpRequestResult> requestCode({
    required String phone,
    required PhoneOtpIntent intent,
  }) {
    requestCalls++;
    lastRequestPhone = phone;
    lastRequestIntent = intent;
    return requestFuture ?? Future.value(PhoneOtpCodeSent(phone));
  }

  @override
  Future<PhoneOtpRequestResult> resendCode({
    required String phone,
    required PhoneOtpIntent intent,
  }) {
    resendCalls++;
    lastResendPhone = phone;
    lastResendIntent = intent;
    return resendFuture ?? Future.value(PhoneOtpCodeSent(phone));
  }

  @override
  Future<SignInResult> verifyCode({
    required String phone,
    required String token,
  }) {
    verifyCalls++;
    lastVerifyPhone = phone;
    lastVerifyToken = token;
    return verifyFuture ?? Future.value(verifyResult);
  }
}
