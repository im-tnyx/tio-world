# TNYX-233 — Canonical user country/region context

## Status

Implementation owner active. Bounded prerequisite slice for TNYX-229.

## Verified evidence

- Base: `main@13da1de59ad4980dc36ce6a9fbc3c206d1463224`.
- Linear TNYX-233 is In Progress and blocks TNYX-229.
- GitHub #284 is the implementation mirror.
- Live Supabase has no canonical country/region column on `public.users`, `public.user_profiles`, or `public.user_app_preferences`.
- `public.user_profiles` is the existing canonical common personal/profile owner with authenticated own-row RLS.
- Owner-approved contract: nullable uppercase ISO 3166-1 alpha-2 `country_code` on `public.user_profiles`; `NULL` means unknown/unset.

## In scope

- Add nullable `public.user_profiles.country_code`.
- Enforce canonical uppercase two-letter shape without guessing/backfilling existing users.
- Preserve existing user-profile RLS/grants.
- Add focused database validation for valid, invalid, nullable, and own-row behavior.
- Prepare the trusted authenticated read contract needed by protected nutrition routing, without deploying the parser.

## Out of scope

- Country picker or other Flutter UI.
- Inferring country from phone code, timezone, language, IP, or device location.
- Provider-specific country codes in Flutter.
- Parser deployment or provider-secret changes.
- TNYX-226 activation.
- Future Settings Language & Region implementation.

## Decisions

- Canonical owner: User Profile / `public.user_profiles`.
- Persistence: nullable ISO 3166-1 alpha-2 `country_code`, stored uppercase.
- Existing users remain `NULL` until an explicit trusted/user edit supplies country.
- Settings may later edit the canonical value but cannot duplicate ownership.
- Nutrition consumes country read-only; provider localization remains server-side.
- Unknown/unsupported country must not silently map to India or US.

## Validation plan

- Migration/source parity.
- Database test for `NULL`, accepted uppercase ISO-like alpha-2 shape, rejected lowercase/invalid-length/non-alpha values, RLS ownership preservation.
- `git diff --check` and complete branch changed-file audit before push/PR handoff.
- No live production migration is applied as part of repository authoring unless separately authorized and reconciled.

## Handoff

Implementation started. Task brief created before source/schema repository changes.
