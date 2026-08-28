# Auth Google Supabase fail-closed

Status: Complete / Frozen

## Reproduction

Manual QA on the current Product Onboarding branch cleared app/local data, opened Sign Up, tapped Continue with Google, selected an account, then received:

`[core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()`

## Root cause

Production Auth is Supabase-first. Before runtime configuration cleanup, the phone app embedded live Supabase URL/publishable-key defaults, so an ordinary debug APK implicitly had a Supabase client. Configuration cleanup intentionally removed that hidden backend selection.

In a debug build without explicit `SUPABASE_URL` + `SUPABASE_PUBLISHABLE_KEY`, `signInWithGoogleUseCaseProvider` resolves null. Login/Sign Up still carried a legacy `GoogleAuthUseCase` compatibility fallback. That legacy use case used `FirebaseAuth.instance`, although Firebase capability is intentionally unavailable/unconfigured, producing the observed `[core/no-app]` error after account selection.

## Implemented scope

- `GoogleAuthUseCase` is now explicitly documented as a legacy Firebase compatibility path.
- The legacy Firebase path is disabled/fail-closed by default.
- Disabled legacy execution returns controlled `GoogleAuthFailed('Google sign-in is unavailable in this app build.')` before invoking the Google account chooser or `FirebaseAuth.instance`.
- Legacy Firebase behavior can only be exercised through explicit `legacyFirebaseEnabled: true` opt-in; current app production composition does not opt in.
- Supabase-configured Login/Sign Up remain unchanged: `SignInWithGoogleUseCase` is still preferred and uses `SupabaseAuthSignInRepository` with `signupOrExisting` behavior on Sign Up.
- Focused regression proves the disabled fallback does not call the Google provider at all, while explicit compatibility tests retain cancelled/provider-failure behavior.

## Out of scope

- Re-embedding Supabase URL/publishable-key defaults.
- Adding `google-services.json` or `Firebase.initializeApp()`.
- Changing Supabase Google provider configuration.
- OAuth signing/key redesign.
- Product Onboarding data/schema/flow changes.
- Auth #34 broader password/identity work.

## Accepted runtime/source-test checkpoint

```text
2be5c6d058819cd1d520c351c631b00dd6a21c58
Flutter CI #2035 / run 32866187925 ✅
Android Native CI #447 / run 32866188076 ✅
```

Validation on the accepted SHA:

- Flutter analyze ✅
- Dart analyze ✅
- Flutter tests ✅
- Dart tests ✅
- Phone Android debug APK ✅
- Wear Android debug APK ✅

## Manual-QA requirement

A backend-connected manual-QA APK must be built explicitly with both:

```text
SUPABASE_URL
SUPABASE_PUBLISHABLE_KEY
```

A plain debug/CI APK without those values intentionally remains a no-Supabase build and must fail closed instead of silently selecting production or falling back to Firebase.

## Merge guard

PR #50 remains Draft/open/unmerged. Ready/Merge still requires explicit owner authorization.
