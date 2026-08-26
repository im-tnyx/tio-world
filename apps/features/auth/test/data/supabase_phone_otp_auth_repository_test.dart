import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_auth/auth.dart';

void main() {
  group('SupabasePhoneOtpAuthRepository', () {
    test('Signup request sends SMS with create-user enabled', () async {
      String? requestedPhone;
      bool? requestedShouldCreateUser;
      final repository = SupabasePhoneOtpAuthRepository(
        client: FakeSupabaseClient(),
        requestSender: ({
          required String phone,
          required bool shouldCreateUser,
        }) async {
          requestedPhone = phone;
          requestedShouldCreateUser = shouldCreateUser;
        },
      );

      final result = await repository.requestCode(
        phone: '+919876543210',
        intent: PhoneOtpIntent.signup,
      );

      expect(result, const PhoneOtpCodeSent('+919876543210'));
      expect(requestedPhone, '+919876543210');
      expect(requestedShouldCreateUser, isTrue);
    });

    test('Login request sends SMS with create-user disabled', () async {
      bool? requestedShouldCreateUser;
      final repository = SupabasePhoneOtpAuthRepository(
        client: FakeSupabaseClient(),
        requestSender: ({
          required String phone,
          required bool shouldCreateUser,
        }) async {
          requestedShouldCreateUser = shouldCreateUser;
        },
      );

      await repository.requestCode(
        phone: '+14155552671',
        intent: PhoneOtpIntent.login,
      );

      expect(requestedShouldCreateUser, isFalse);
    });

    test('resend repeats the passwordless request with the same intent',
        () async {
      var calls = 0;
      bool? requestedShouldCreateUser;
      final repository = SupabasePhoneOtpAuthRepository(
        client: FakeSupabaseClient(),
        requestSender: ({
          required String phone,
          required bool shouldCreateUser,
        }) async {
          calls++;
          requestedShouldCreateUser = shouldCreateUser;
        },
      );

      final result = await repository.resendCode(
        phone: '+919876543210',
        intent: PhoneOtpIntent.login,
      );

      expect(result, const PhoneOtpCodeSent('+919876543210'));
      expect(calls, 1);
      expect(requestedShouldCreateUser, isFalse);
    });

    test('non-canonical request is rejected before sender call', () async {
      var calls = 0;
      final repository = SupabasePhoneOtpAuthRepository(
        client: FakeSupabaseClient(),
        requestSender: ({
          required String phone,
          required bool shouldCreateUser,
        }) async {
          calls++;
        },
      );

      final result = await repository.requestCode(
        phone: '9876543210',
        intent: PhoneOtpIntent.signup,
      );

      expect(result, isA<PhoneOtpRequestFailure>());
      expect((result as PhoneOtpRequestFailure).code, 'invalid_phone');
      expect(calls, 0);
    });

    test('request Auth failure is mapped to controlled result', () async {
      final repository = SupabasePhoneOtpAuthRepository(
        client: FakeSupabaseClient(),
        requestSender: ({
          required String phone,
          required bool shouldCreateUser,
        }) async {
          throw const AuthException('rate limited', statusCode: '429');
        },
      );

      final result = await repository.requestCode(
        phone: '+919876543210',
        intent: PhoneOtpIntent.signup,
      );

      expect(result, isA<PhoneOtpRequestFailure>());
      expect(
        (result as PhoneOtpRequestFailure).code,
        'phone_otp_request_failed',
      );
    });

    test('verify requires a real session and confirmed matching phone',
        () async {
      final user = _phoneUser();
      final repository = SupabasePhoneOtpAuthRepository(
        client: FakeSupabaseClient(),
        verifier: ({required String phone, required String token}) async {
          expect(phone, '+919876543210');
          expect(token, '123456');
          return _authResponse(user);
        },
      );

      final result = await repository.verifyCode(
        phone: '+919876543210',
        token: '123456',
      );

      expect(result, isA<SignInSuccess>());
      final session = (result as SignInSuccess).session;
      expect(session.userId, 'phone-user');
      expect(session.phone, '+919876543210');
      expect(session.isPhoneVerified, isTrue);
    });

    test('verify fails when Supabase returns user without session', () async {
      final user = _phoneUser();
      final repository = SupabasePhoneOtpAuthRepository(
        client: FakeSupabaseClient(),
        verifier: ({required String phone, required String token}) async {
          return AuthResponse(session: null, user: user);
        },
      );

      final result = await repository.verifyCode(
        phone: '+919876543210',
        token: '123456',
      );

      expect(result, isA<SignInFailure>());
      expect((result as SignInFailure).code, 'phone_otp_session_missing');
    });

    test('verify fails closed when confirmed session phone differs', () async {
      final user = _phoneUser(phone: '+14155552671');
      final repository = SupabasePhoneOtpAuthRepository(
        client: FakeSupabaseClient(),
        verifier: ({required String phone, required String token}) async {
          return _authResponse(user);
        },
      );

      final result = await repository.verifyCode(
        phone: '+919876543210',
        token: '123456',
      );

      expect(result, isA<SignInFailure>());
      expect((result as SignInFailure).code, 'phone_otp_identity_mismatch');
    });

    test('verify fails closed when phone is not confirmed', () async {
      final user = _phoneUser(confirmed: false);
      final repository = SupabasePhoneOtpAuthRepository(
        client: FakeSupabaseClient(),
        verifier: ({required String phone, required String token}) async {
          return _authResponse(user);
        },
      );

      final result = await repository.verifyCode(
        phone: '+919876543210',
        token: '123456',
      );

      expect(result, isA<SignInFailure>());
      expect((result as SignInFailure).code, 'phone_otp_identity_mismatch');
    });

    test('verify success does not wait for device sync', () async {
      final deviceRepository = PendingUserDeviceRepository();
      final user = _phoneUser();
      final repository = SupabasePhoneOtpAuthRepository(
        client: FakeSupabaseClient(),
        userDeviceRepository: deviceRepository,
        verifier: ({required String phone, required String token}) async {
          return _authResponse(user);
        },
      );

      final result = await repository
          .verifyCode(phone: '+919876543210', token: '123456')
          .timeout(const Duration(milliseconds: 200));

      expect(result, isA<SignInSuccess>());
      expect(deviceRepository.syncCalls, 1);
      deviceRepository.complete();
    });

    test('verify Auth failure is controlled', () async {
      final repository = SupabasePhoneOtpAuthRepository(
        client: FakeSupabaseClient(),
        verifier: ({required String phone, required String token}) async {
          throw const AuthException('invalid otp', statusCode: '400');
        },
      );

      final result = await repository.verifyCode(
        phone: '+919876543210',
        token: '000000',
      );

      expect(result, isA<SignInFailure>());
      expect((result as SignInFailure).code, 'phone_otp_verify_failed');
    });
  });
}

User _phoneUser({
  String phone = '+919876543210',
  bool confirmed = true,
}) {
  return User(
    id: 'phone-user',
    appMetadata: const {},
    userMetadata: const {'display_name': 'Phone User'},
    aud: 'authenticated',
    createdAt: DateTime.now().toUtc().toIso8601String(),
    phone: phone,
    phoneConfirmedAt:
        confirmed ? DateTime.now().toUtc().toIso8601String() : null,
  );
}

AuthResponse _authResponse(User user) => AuthResponse(
      session: Session(
        accessToken: 'token',
        tokenType: 'bearer',
        user: user,
      ),
      user: user,
    );

final class FakeSupabaseClient extends Fake implements SupabaseClient {}

final class PendingUserDeviceRepository implements UserDeviceRepository {
  final Completer<void> _completer = Completer<void>();
  int syncCalls = 0;

  @override
  Future<void> syncCurrentDevice() {
    syncCalls++;
    return _completer.future;
  }

  void complete() {
    if (!_completer.isCompleted) {
      _completer.complete();
    }
  }
}
