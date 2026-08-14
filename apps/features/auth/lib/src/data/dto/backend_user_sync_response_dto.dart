/// Response DTO from POST /api/v1/auth/google-sync (and other sync endpoints).
/// Source: authService.ts AuthResponse interface.
class BackendUserSyncResponseDto {
  const BackendUserSyncResponseDto({
    required this.isNewUser,
    required this.isOnboarded,
    required this.userId,
    required this.referralCode,
    this.customToken,
  });

  final bool isNewUser;
  final bool isOnboarded;
  final String userId;
  final String referralCode;
  /// Only non-null for Truecaller auth flow.
  final String? customToken;

  factory BackendUserSyncResponseDto.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return BackendUserSyncResponseDto(
      isNewUser: json['isNewUser'] as bool? ?? false,
      isOnboarded: json['is_onboarded'] as bool? ?? false,
      userId: user?['id'] as String? ?? '',
      referralCode: user?['referralCode'] as String? ?? '',
      customToken: json['customToken'] as String?,
    );
  }
}
