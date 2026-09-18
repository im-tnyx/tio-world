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

## Implementation evidence

- Added nullable `public.user_profiles.country_code` with uppercase two-letter format validation; existing rows stay `NULL`.
- Protected parser now resolves request context with `createSupabaseContext(..., { auth: "user" })` and reads `user_profiles.country_code` through the caller-scoped `data.supabase` client, so existing RLS remains the authorization boundary.
- Missing canonical country returns provider-neutral `incomplete` before AI/provider work.
- Country context is threaded internally to factual resolvers and does not enter Flutter/domain response DTOs.
- FatSecret search/detail calls now always receive explicit `region=<countryCode>`; the provider's implicit US default is therefore not used for authenticated requests with country context.
- Provider-specific localization remains server-side. Edamam remains the existing secondary fallback and receives no country-specific client contract.
- Focused handler/provider tests cover missing country, FR/IN country propagation, explicit FatSecret region, no provider call when country is absent, and a valid-format unsupported region that is passed through without any silent US rewrite.
- Supabase Database CI includes the TNYX-233 SQL matrix.
- Supabase Functions CI type-checks the parser entrypoint/all source/tests and runs the parser test suite on Deno 2.9.6.

## Quality review

- Branch remains based on `main@13da1de59ad4980dc36ce6a9fbc3c206d1463224`.
- Live Supabase remains unchanged; `nutrition-meal-text-parse` is still not deployed.
- Current Supabase docs confirm caller-scoped Edge Function clients apply RLS for authenticated user reads.
- FatSecret current docs confirm omitting `region` defaults localization to US; explicit region is therefore required for this global contract.
- The database constraint enforces canonical storage format, not a copied static ISO membership catalog. Unsupported/provider-unavailable codes fail safely at the provider boundary rather than being silently rewritten to another country.
- Existing unrelated Supabase security-advisor warnings remain outside this slice; no new live advisor finding can exist until the migration is applied.

## Validation status

- Static branch/scope audit: PASS; branch remains based on `main@13da1de59ad4980dc36ce6a9fbc3c206d1463224`, with only TNYX-233-owned files.
- Supabase Database CI run #73: PASS on implementation head `f2f4e9643199a421712668ad1c365768cc08cd46`; full migration replay, migration ledger, TNYX-233 SQL matrix, existing SQL matrices, concurrency test, and lint-delta gate all passed.
- Supabase Functions CI run #3: PASS on Deno 2.9.6 on the same implementation head.
- Parser entrypoint/all source/tests `deno check`: PASS.
- Parser tests: PASS — 78 passed / 0 failed, including the unsupported-country no-US-rewrite regression.
- GitHub Advanced Security dynamic AI scan is currently an infrastructure failure, not a code finding: it exits before review with `400 The requested model is not supported`.
- Live migration/deployment: not authorized/performed in this stage.

## Handoff

Repository implementation and executable CI validation are PASS in Draft PR #285. The remaining gate is controlled live Supabase migration/parity before TNYX-233 can clear TNYX-229. No parser deployment is authorized by this handoff.
