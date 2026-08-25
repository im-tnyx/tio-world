# Auth Google Supabase fail-closed

Status: In Progress

## Reproduction

Manual QA on the current Product Onboarding branch cleared app/local data, opened Sign Up, tapped Continue with Google, selected an account, then received:

`[core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()`

## Root cause

Production Auth is Supabase-first. After runtime configuration cleanup, a debug build without `SUPABASE_URL` + `SUPABASE_PUBLISHABLE_KEY` has no Supabase client, so `signInWithGoogleUseCaseProvider` resolves null. The router still injected the legacy `GoogleAuthUseCase`, and Login/Sign Up used that as a fallback. That legacy use case calls `FirebaseAuth.instance`, although Firebase capability is intentionally unavailable/unconfigured.

## Scope

- Production Login/Sign Up routing must not inject the legacy Firebase Google auth fallback.
- Supabase-configured builds continue using `SignInWithGoogleUseCase` / `SupabaseAuthSignInRepository`.
- When no canonical Google sign-in use case is available, the Auth UI fails closed with controlled user feedback and never opens Google/Firebase auth.
- Add focused regression coverage for no-provider Google actions.

## Out of scope

- Re-embedding Supabase URL/publishable-key defaults.
- Adding `google-services.json` or `Firebase.initializeApp()`.
- Changing Supabase Google provider configuration.
- OAuth signing/key redesign.
- Product Onboarding data/schema/flow changes.
- Auth #34 broader password/identity work.

## Acceptance

1. Plain/unconfigured debug build cannot fall into Firebase Google auth.
2. Google Login/Signup with configured Supabase continues to use the existing Supabase use case.
3. No-provider Google action resets loading and shows controlled feedback.
4. Existing Google intent behavior remains covered.
5. Full Flutter/Dart + Android phone/Wear CI passes on the accepted runtime SHA.
6. PR #50 remains Draft/open/unmerged.
