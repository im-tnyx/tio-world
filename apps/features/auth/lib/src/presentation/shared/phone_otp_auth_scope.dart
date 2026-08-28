import 'package:flutter/widgets.dart';

import '../../domain/domain.dart';

/// App-composition boundary for signed-out Phone OTP use cases.
///
/// Feature pages may still receive explicit use cases for tests/isolated hosts;
/// the app shell supplies production composition through this inherited scope.
class PhoneOtpAuthScope extends InheritedWidget {
  const PhoneOtpAuthScope({
    required this.requestPhoneOtpUseCase,
    required this.resendPhoneOtpUseCase,
    required this.verifyPhoneOtpUseCase,
    required super.child,
    super.key,
  });

  final RequestPhoneOtpUseCase? requestPhoneOtpUseCase;
  final ResendPhoneOtpUseCase? resendPhoneOtpUseCase;
  final VerifyPhoneOtpUseCase? verifyPhoneOtpUseCase;

  static PhoneOtpAuthScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PhoneOtpAuthScope>();
  }

  @override
  bool updateShouldNotify(PhoneOtpAuthScope oldWidget) {
    return requestPhoneOtpUseCase != oldWidget.requestPhoneOtpUseCase ||
        resendPhoneOtpUseCase != oldWidget.resendPhoneOtpUseCase ||
        verifyPhoneOtpUseCase != oldWidget.verifyPhoneOtpUseCase;
  }
}
