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
- pre-reconciliation head: `32dd9defbb36be64fd5785b1a8d81d07b5c1aa10`
- stacked delta before this brief: 4 commits, 3 app-shell files, 0 unresolved review threads
- PR remains Draft and mergeable

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

## CI / Review Reconciliation

PR #295 does not auto-run Flutter CI because `.github/workflows/flutter-ci.yml` limits pull-request runs to PRs targeting `main`, while #295 is intentionally stacked on PR #289.

The exact pre-reconciliation head did receive `github-advanced-security`, but that job failed in scanner infrastructure with:

`400 The requested model is not supported`

No code finding was produced by that failure. Do not represent it as a Flutter/source validation failure.

Parent PR #289 exact head previously passed Flutter CI, but the new #295 delta still needs focused validation or a fresh authenticated app run before final handoff.

## Handoff Rule

TNYX-238 remains `PARTIAL` until the latest provenance-display run is recorded and the three resolved matches are assessed.

Do not clear TNYX-229 or TNYX-226 merely because the Open Food Facts diagnostic probe returns resolved cases.
