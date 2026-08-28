/// Returns Tio's canonical Email identity for account resolution.
///
/// Gmail and Googlemail aliases collapse to the same mailbox identity:
/// local-part dots are removed, `+tag` is removed, and `googlemail.com` maps to
/// `gmail.com`. Other providers keep local-part dots and `+tag` semantics.
///
/// Returns `null` when [rawEmail] cannot represent one syntactically usable
/// Email identity. This mirrors the fail-closed contract of the database
/// canonicalizer rather than attempting to repair malformed input.
String? canonicalEmailIdentity(String rawEmail) {
  final normalized = rawEmail.trim().toLowerCase();
  if (normalized.isEmpty || RegExp(r'\s').hasMatch(normalized)) {
    return null;
  }

  final firstAt = normalized.indexOf('@');
  if (firstAt <= 0 ||
      firstAt != normalized.lastIndexOf('@') ||
      firstAt == normalized.length - 1) {
    return null;
  }

  var localPart = normalized.substring(0, firstAt);
  var domain = normalized.substring(firstAt + 1);
  if (localPart.isEmpty || domain.isEmpty) return null;

  if (domain == 'gmail.com' || domain == 'googlemail.com') {
    final plusIndex = localPart.indexOf('+');
    if (plusIndex >= 0) {
      localPart = localPart.substring(0, plusIndex);
    }
    localPart = localPart.replaceAll('.', '');
    domain = 'gmail.com';
    if (localPart.isEmpty) return null;
  }

  return '$localPart@$domain';
}
