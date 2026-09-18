# TNYX-233 — Canonical user country/region context

## Status

Repository implementation and controlled live schema parity are complete. Executable source/test head is validated; governance handoff is ready for PR review.

## Verified evidence

- Base: `main@13da1de59ad4980dc36ce6a9fbc3c206d1463224`.
- Linear TNYX-233 is In Progress and blocks TNYX-229.
- GitHub #284 is the implementation mirror.
- Live Supabase now has nullable `public.user_profiles.country_code`; `public.users` and `public.user_app_preferences` remain without a competing country source.
- Hosted migration ledger records `20260918184442_add_user_profile_country_code`; repository migration identity is reconciled to the same version.
- `public.user_profiles` remains the canonical common personal/profile owner with authenticated own-row RLS.
- Owner-approved contract: nullable uppercase ISO 3166-1 alpha-2 `country_code` on `public.user_profiles`; `NULL` means unknown/unset.

## In scope

- Add nullable `public.user_profiles.country_code`.
- Enforce canonical uppercase two-letter shape without guessing/backfilling existing users.
- Preserve existing user-profile RLS/grants.
- Add focused database validation for valid, invalid, nullable, and own-row behavior.
- Prepare the trusted authenticated read contract needed by protected nutrition routing, without deploying the parser.
- Apply and verify the approved migration on the live `tio-world` Supabase project after separate owner authorization.

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
- Hosted migration identity and repository filename must stay 1:1; the Supabase MCP-generated hosted version `20260918184442` is therefore the canonical migration timestamp.

## Validation plan

- Migration/source parity.
- Database test for `NULL`, accepted uppercase ISO-like alpha-2 shape, rejected lowercase/invalid-length/non-alpha values, RLS ownership preservation.
- `git diff --check` and complete branch changed-file audit before push/PR handoff.
- Controlled live migration only after separate owner authorization, followed by schema, data-preservation, RLS/grant and advisor parity checks.
- Keep `nutrition-meal-text-parse` undeployed in this slice.

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
- Live Supabase migration is applied and parity-checked; `nutrition-meal-text-parse` is still not deployed.
- Current Supabase docs confirm remote migration history and repository migration versions must remain synchronized for deterministic `db push` behavior.
- Current Supabase docs confirm caller-scoped Edge Function clients apply RLS for authenticated user reads.
- FatSecret current docs confirm omitting `region` defaults localization to US; explicit region is therefore required for this global contract.
- The database constraint enforces canonical storage format, not a copied static ISO membership catalog. Unsupported/provider-unavailable codes fail safely at the provider boundary rather than being silently rewritten to another country.
- Existing unrelated Supabase security/performance advisor findings are unchanged after the live migration.

## Validation status

Repository validation before live application:
- Current reviewed implementation head before migration-identity reconciliation: `1ceba8f32b3602d13e5ebdfd6359c05fa7bb72d8`.
- Supabase Database CI run #74: PASS; full migration replay, migration ledger, TNYX-233 SQL matrix, existing SQL matrices, concurrency test, and lint-delta gate passed.
- Supabase Functions CI run #4: PASS on Deno 2.9.6.
- Parser entrypoint/all source/tests `deno check`: PASS.
- Parser tests: PASS — 78 passed / 0 failed, including the unsupported-country no-US-rewrite regression.
- GitHub Advanced Security dynamic AI scan remains an external scanner infrastructure failure, not a code finding: `400 The requested model is not supported`.

Controlled live migration/parity:
- Owner authorized the next controlled gate on 2026-09-19.
- Exact reviewed SQL applied successfully to Supabase project `oykupyiitspujzpwwvuj`.
- Hosted migration ledger version: `20260918184442_add_user_profile_country_code`.
- Live column: `country_code text NULL` with the expected canonical comment.
- Constraint `user_profiles_country_code_check`: present, validated, exact uppercase two-letter-or-NULL shape.
- Existing `public.user_profiles` rows: 3 total; all 3 preserved with `country_code IS NULL`; no backfill/guessing occurred.
- RLS remains enabled; the three existing authenticated own-row policies are unchanged.
- Table grants are unchanged: authenticated remains INSERT/SELECT/UPDATE; service role baseline unchanged; anon gains nothing.
- Security advisor baseline remains 5 existing authenticated `SECURITY DEFINER` warnings plus leaked-password protection disabled; no TNYX-233-specific finding was introduced.
- Performance advisor baseline is unchanged; no TNYX-233-specific finding was introduced.
- Live Edge Function inventory still contains only `google-login-admission`; `nutrition-meal-text-parse` remains NOT DEPLOYED.
- Repository migration filename is reconciled to hosted version `20260918184442`.

## Final executable validation

- Exact executable source/test HEAD: `393074f90cd51bf9786c3bbf358438300e402112`.
- Supabase Functions CI run #6: PASS.
- Supabase Database CI run #76: PASS.
- Complete migration replay and migration ledger: PASS.
- TNYX-233 country SQL matrix: PASS after aligning its ledger assertion to hosted/repository version `20260918184442`.
- Existing SQL matrices, real two-session concurrency test, and lint-delta gate: PASS.
- Branch scope at executable HEAD: 23 ahead / 0 behind `main`, 14 TNYX-233-owned changed files, 0 unresolved review threads, mergeable.
- The prior Database CI #75 failure was test-harness-only: replay/ledger passed, but the TNYX-233 test still asserted the pre-hosted timestamp. No live schema correction was required.

## Handoff

TNYX-233 repository implementation, live schema parity, and executable validation are PASS. This task-brief reconciliation is governance-only and does not change executable source, migration SQL, or tests beyond the already validated `393074f9...` head. PR #285 may proceed to Ready for Review / Linear In Review. TNYX-229 remains blocked until TNYX-233 is merged/cleared into `main`; no parser deployment is authorized by this handoff.
