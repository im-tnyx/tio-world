import 'package:google_sign_in/google_sign_in.dart';

/// Result of attempting Google Sign-In.
sealed class GoogleSignInResult {
  const GoogleSignInResult();
}

/// User completed Google sign-in and we obtained the Google ID token.
class GoogleSignInSuccess extends GoogleSignInResult {
  const GoogleSignInSuccess({
    required this.googleIdToken,
    this.displayName,
    this.email,
    this.photoUrl,
  });

  /// Google ID token — used to create a GoogleAuthCredential for Firebase.
  /// Do NOT send this directly to backend — convert to Firebase ID token first.
  final String googleIdToken;
  final String? displayName;
  final String? email;
  final String? photoUrl;
}

/// User dismissed the Google sign-in UI.
class GoogleSignInCancelled extends GoogleSignInResult {
  const GoogleSignInCancelled();
}

/// Sign-in attempt failed with an error.
class GoogleSignInFailed extends GoogleSignInResult {
  const GoogleSignInFailed(this.message);
  final String message;
}

/// Wraps [GoogleSignIn] SDK, isolating it from application logic.
class GoogleSignInProvider {
  GoogleSignInProvider({GoogleSignIn? signIn, String? serverClientId})
      : _signIn = signIn ??
            GoogleSignIn(
              scopes: const ['email', 'profile'],
              serverClientId: serverClientId ??
                  const String.fromEnvironment(
                    'GOOGLE_WEB_CLIENT_ID',
                    defaultValue:
                        '218403286180-2047ibc6i5r6tb2kftoq4lu6220kl8d9.apps.googleusercontent.com',
                  ),
            );

  final GoogleSignIn _signIn;

  GoogleSignIn get signInClient => _signIn;

  Future<GoogleSignInResult> signIn() async {
    try {
      final account = await _signIn.signIn();
      if (account == null) return const GoogleSignInCancelled();
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        return const GoogleSignInFailed('Google ID token missing.');
      }
      return GoogleSignInSuccess(
        googleIdToken: idToken,
        displayName: account.displayName,
        email: account.email,
        photoUrl: account.photoUrl,
      );
    } catch (e) {
      return GoogleSignInFailed(e.toString());
    }
  }

  Future<void> signOut() async {
    await _signIn.signOut();
  }
}
