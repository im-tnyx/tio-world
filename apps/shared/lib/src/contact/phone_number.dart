const _e164MinDigits = 8;
const _e164MaxDigits = 15;
const _indiaCallingCodeDigits = '91';
const _indiaNationalNumberDigits = 10;

/// Canonicalizes a phone number to E.164 for persistence and Auth boundaries.
///
/// Current India-only UI may provide a 10-digit national number, which is
/// interpreted with calling code +91. Explicit international input must start
/// with `+`; this lets a future country picker pass full E.164 without changing
/// the persisted representation.
///
/// Empty input remains empty so optional Account fields can be cleared.
String normalizePhoneNumberE164(
  String phoneNumber, {
  String defaultCallingCodeDigits = _indiaCallingCodeDigits,
  int defaultNationalNumberDigits = _indiaNationalNumberDigits,
}) {
  final trimmed = phoneNumber.trim();
  if (trimmed.isEmpty) return '';

  final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  final callingCodeDigits =
      defaultCallingCodeDigits.replaceAll(RegExp(r'[^0-9]'), '');

  if (callingCodeDigits.isEmpty || callingCodeDigits.startsWith('0')) {
    throw ArgumentError.value(
      defaultCallingCodeDigits,
      'defaultCallingCodeDigits',
      'must contain a valid non-zero country calling code',
    );
  }
  if (defaultNationalNumberDigits <= 0) {
    throw ArgumentError.value(
      defaultNationalNumberDigits,
      'defaultNationalNumberDigits',
      'must be greater than zero',
    );
  }

  late final String e164Digits;
  if (trimmed.startsWith('+')) {
    e164Digits = digits;
  } else if (digits.length == defaultNationalNumberDigits) {
    e164Digits = '$callingCodeDigits$digits';
  } else if (digits.startsWith(callingCodeDigits) &&
      digits.length ==
          callingCodeDigits.length + defaultNationalNumberDigits) {
    e164Digits = digits;
  } else {
    throw ArgumentError.value(
      phoneNumber,
      'phoneNumber',
      'must be a valid national number for the configured calling code or an explicit +E.164 number',
    );
  }

  if (e164Digits.length < _e164MinDigits ||
      e164Digits.length > _e164MaxDigits ||
      e164Digits.startsWith('0')) {
    throw ArgumentError.value(
      phoneNumber,
      'phoneNumber',
      'must be a valid E.164 phone number',
    );
  }

  return '+$e164Digits';
}
