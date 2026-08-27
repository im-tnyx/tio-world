import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_auth/auth.dart';

void main() {
  group('SupabaseAccountContactVerificationRepository', () {
    test('email change uses Supabase Auth emailChange and mobile callback',
        () async {
      final currentUser = _user(
        email: 'old@example.com',
        emailConfirmedAt: '2026-08-25T00:00:00.000Z',
      );
      final confirmedTarget = _user(
        email: 'new@example.com',
        emailConfirmedAt: '2026-08-25T00:01:00.000Z',
      );
      final auth = FakeContactGoTrueClient(
        currentUser: currentUser,
        verifyResponse: AuthResponse(session: null, user: confirmedTarget),
      );
      final repository = SupabaseAccountContactVerificationRepository(
        client: FakeContactSupabaseClient(auth),
      );

      await repository.requestEmailVerification(' New@Example.com ');
      await repository.verifyEmail(
        email: 'new@example.com',
        token: '123456',
      );

      expect(auth.updatedEmail, 'new@example.com');
      expect(auth.lastEmailRedirectTo, 'tio://login-callback');
      expect(auth.lastVerifyEmail, 'new@example.com');
      expect(auth.lastVerifyType, OtpType.emailChange);
    });

    test('email change cannot succeed from an intermediate unconfirmed response',
        () async {
      final currentUser = _user(
        email: 'old@example.com',
        emailConfirmedAt: '2026-08-25T00:00:00.000Z',
      );
      final intermediateUser = _user(email: 'new@example.com');
      final auth = FakeContactGoTrueClient(
        currentUser: currentUser,
        verifyResponse: AuthResponse(session: null, user: intermediateUser),
      );
      final repository = SupabaseAccountContactVerificationRepository(
        client: FakeContactSupabaseClient(auth),
      );

      await repository.requestEmailVerification('new@example.com');

      await expectLater(
        repository.verifyEmail(email: 'new@example.com', token: '123456'),
        throwsA(isA<StateError>()),
      );
      expect(auth.lastVerifyType, OtpType.emailChange);
    });

    test('existing unconfirmed email resends with mobile callback', () async {
      final auth = FakeContactGoTrueClient(
        currentUser: _user(email: 'pending@example.com'),
      );
      final repository = SupabaseAccountContactVerificationRepository(
        client: FakeContactSupabaseClient(auth),
      );

      await repository.requestEmailVerification(' Pending@Example.com ');

      expect(auth.lastResendEmail, 'pending@example.com');
      expect(auth.lastResendType, OtpType.signup);
      expect(auth.lastResendEmailRedirectTo, 'tio://login-callback');
      expect(auth.updatedEmail, isNull);
    });

    test('phone change normalizes target and requires phoneChange confirmation',
        () async {
      final currentUser = _user(
        email: 'user@example.com',
        emailConfirmedAt: '2026-08-25T00:00:00.000Z',
      );
      final confirmedTarget = _user(
        email: 'user@example.com',
        emailConfirmedAt: '2026-08-25T00:00:00.000Z',
        phone: '+919123456789',
        phoneConfirmedAt: '2026-08-25T00:02:00.000Z',
      );
      final auth = FakeContactGoTrueClient(
        currentUser: currentUser,
        verifyResponse: AuthResponse(session: null, user: confirmedTarget),
      );
      final repository = SupabaseAccountContactVerificationRepository(
        client: FakeContactSupabaseClient(auth),
      );

      await repository.requestPhoneVerification('9123456789');
      await repository.verifyPhoneChange(
        phoneNumber: '9123456789',
        token: '654321',
      );

      expect(auth.updatedPhone, '+919123456789');
      expect(auth.lastVerifyPhone, '+919123456789');
      expect(auth.lastVerifyType, OtpType.phoneChange);
    });

    test('phone change cannot succeed without Supabase phone confirmation',
        () async {
      final currentUser = _user(email: 'user@example.com');
      final auth = FakeContactGoTrueClient(
        currentUser: currentUser,
        verifyResponse: AuthResponse(
          session: null,
          user: _user(email: 'user@example.com', phone: '+919123456789'),
        ),
      );
      final repository = SupabaseAccountContactVerificationRepository(
        client: FakeContactSupabaseClient(auth),
      );

      await repository.requestPhoneVerification('9123456789');

      await expectLater(
        repository.verifyPhoneChange(
          phoneNumber: '9123456789',
          token: '654321',
        ),
        throwsA(isA<StateError>()),
      );
      expect(auth.lastVerifyType, OtpType.phoneChange);
    });
  });
}

User _user({
  required String email,
  String? emailConfirmedAt,
  String? phone,
  String? phoneConfirmedAt,
}) {
  return User(
    id: 'usr-contact-test',
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: '2026-08-25T00:00:00.000Z',
    email: email,
    emailConfirmedAt: emailConfirmedAt,
    phone: phone,
    phoneConfirmedAt: phoneConfirmedAt,
  );
}

class FakeContactSupabaseClient extends Fake implements SupabaseClient {
  FakeContactSupabaseClient(this._auth);

  final GoTrueClient _auth;

  @override
  GoTrueClient get auth => _auth;
}

class FakeContactGoTrueClient extends Fake implements GoTrueClient {
  FakeContactGoTrueClient({
    required this.currentUser,
    this.verifyResponse,
  });

  @override
  final User? currentUser;

  final AuthResponse? verifyResponse;
  String? updatedEmail;
  String? updatedPhone;
  String? lastEmailRedirectTo;
  String? lastResendEmail;
  OtpType? lastResendType;
  String? lastResendEmailRedirectTo;
  String? lastVerifyEmail;
  String? lastVerifyPhone;
  String? lastVerifyToken;
  OtpType? lastVerifyType;

  @override
  Future<UserResponse> updateUser(
    UserAttributes attributes, {
    String? emailRedirectTo,
  }) async {
    updatedEmail = attributes.email;
    updatedPhone = attributes.phone;
    lastEmailRedirectTo = emailRedirectTo;
    final user = currentUser;
    if (user == null) {
      throw StateError('test requires a current user');
    }
    return UserResponse.fromJson(user.toJson());
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
    lastResendEmailRedirectTo = emailRedirectTo;
    return ResendResponse();
  }

  @override
  Future<AuthResponse> verifyOTP({
    String? email,
    String? phone,
    String? token,
    required OtpType type,
    String? redirectTo,
    String? captchaToken,
    String? tokenHash,
  }) async {
    lastVerifyEmail = email;
    lastVerifyPhone = phone;
    lastVerifyToken = token;
    lastVerifyType = type;
    return verifyResponse ?? AuthResponse(session: null, user: currentUser);
  }
}
