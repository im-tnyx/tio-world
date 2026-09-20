# TNYX-238 — Open Food Facts authenticated smoke validation

**Status:** In progress
**Primary owner:** TNYX-238 / bounded capability validation
**Affected surface:** existing debug-only Flutter smoke harness + already-deployed synthetic Open Food Facts probe

## Owner Approval and Scope

Owner approved continuing this bounded validation slice via repeated `go` / `go next` instructions.

In scope:
- reuse the existing signed-in Supabase client and debug-only smoke route;
- invoke only `tnyx-238-open-food-facts-probe`;
- display bounded synthetic query/category plus sanitized matched product name and complete per-100g kcal/protein/carbs/fat;
- assess whether resolved results are nutritionally defensible;
- reconfirm the `dahi` unavailable case;
- record validation truthfully.

Explicit non-goals:
- no production meal-parser routing change;
- no Add Food / TNYX-226 activation;
- no persistence, schema/RLS/RPC, secrets, provider-key, or `services/api` change;
- no raw provider payload/URL, JWT, access token, credential, identity, or user meal text exposure;
- no deployment or merge from this slice without separate authorization.

## Reconciled Starting State — 2026-09-20

Immediate stacked base:
- PR #289 branch: `tnyx/tnyx-229-authenticated-smoke-harness`
- base SHA: `83392b32e7e9baf7cf88b10a7d7e390d90aabbc1`

Current slice:
- PR #295
- branch: `tnyx/tnyx-238-open-food-facts-smoke-action`
- current head before this docs reconciliation: `6e8fc5daa6b833b3fc892b8546580f09e6854b92`
- stacked delta: TNYX-238 debug wiring + provenance display + focused widget coverage + this task brief
- PR remains Draft and mergeable
- unresolved review threads: 0

Live Supabase:
- `tnyx-238-open-food-facts-probe`: ACTIVE v1, `verify_jwt=true`
- deployed probe is synthetic-only and accepts no user meal text
- production `nutrition-meal-text-parse` routing is unchanged

Recorded authenticated capability evidence from the prior smoke head:
- `plain yogurt`: resolved
- `dal`: resolved
- `roti`: resolved
- `dahi`: unavailable

This evidence is PARTIAL because result category alone does not prove semantic/nutrition match quality.

## Current Validation Goal

Run the existing authenticated debug action once with the latest provenance-display code and record only:

`query -> category | productName | kcal, protein, carbs, fat /100g`

Then assess:
1. whether the matched product is a defensible match for the query;
2. whether the factual macro set is complete and plausible for that matched product;
3. whether `dahi` remains unavailable/incomplete;
4. whether Open Food Facts merits a separate production adapter/readiness slice.

## Focused Test Coverage

Added `apps/app/test/app/meal_parser_smoke_page_test.dart` on head `6e8fc5da...`.

The test covers:
- resolved provenance display: query + category + sanitized product name + complete per-100g kcal/protein/carbs/fat;
- unavailable bounded display;
- malformed probe payload fails closed to the existing safe message;
- no token/http detail is rendered by the synthetic fixture.

Execution status: **AUTHORED, NOT EXECUTED** in the connected tool surface. Do not claim PASS until Flutter validation actually runs.

## CI / Review Reconciliation

PR #295 does not auto-run Flutter CI because `.github/workflows/flutter-ci.yml` limits pull-request runs to PRs targeting `main`, while #295 is intentionally stacked on PR #289.

The earlier app head received `github-advanced-security`, but that job failed in scanner infrastructure with:

`400 The requested model is not supported`

No code finding was produced by that failure. Do not represent it as a Flutter/source validation failure.

Parent PR #289 exact head previously passed Flutter CI for the underlying smoke harness. The #295-specific provenance/widget-test delta still requires executable Flutter validation and one fresh authenticated provenance run before final handoff.

Attempts to reproduce the live probe from the current assistant runtime were blocked by environment/network restrictions:
- direct Supabase function call: DNS resolution unavailable;
- direct Open Food Facts legacy search endpoint: blocked by web tooling/robots policy.

These limitations are tooling constraints, not runtime evidence.

## Handoff Rule

TNYX-238 remains `PARTIAL` until:
1. the latest focused Flutter test/analyze validation is actually executed; and
2. the latest normal signed-in provenance-display run is recorded and the three resolved matches are assessed.

Do not clear TNYX-229 or TNYX-226 merely because the Open Food Facts diagnostic probe returns resolved cases.
