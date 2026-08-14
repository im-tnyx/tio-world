/// Request DTO for `POST /api/v1/auth/google-sync`.
/// Mirrors backend GoogleSyncRequest (Android: GoogleSyncRequest.kt)
/// Transport: publicApiClient with `Authorization: Bearer <firebaseIdToken>`
class GoogleSyncRequestDto {
  const GoogleSyncRequestDto({
    required this.firebaseIdToken,
    required this.deviceId,
    required this.deviceFingerprint,
    this.name,
    this.profileImage,
    this.platform,
    this.osVersion,
  });

  /// Firebase ID Token (NOT Google ID token).
  /// Sent both as Authorization header Bearer token AND as idToken in body.
  final String firebaseIdToken;
  final String? name;
  final String? profileImage;
  final String deviceId;
  final String deviceFingerprint;
  final String? platform;
  final String? osVersion;

  Map<String, dynamic> toJson() => {
    'idToken': firebaseIdToken,
    if (name != null) 'name': name,
    if (profileImage != null) 'profileImage': profileImage,
    'deviceId': deviceId,
    'deviceFingerprint': deviceFingerprint,
    if (platform != null) 'platform': platform,
    if (osVersion != null) 'osVersion': osVersion,
  };
}
