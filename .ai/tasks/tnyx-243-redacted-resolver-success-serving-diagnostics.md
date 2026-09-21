# TNYX-243 — Redacted factual resolver-success serving diagnostics

**Status:** In progress
**Primary owner:** Nutrition / Supabase Edge Function
**Affected platforms:** `supabase/functions/nutrition-meal-text-parse`

## Owner Approval and Scope Boundary

**Trigger:** None — bounded implementation inside the approved TNYX-243 diagnostic slice.
**Approval status:** Approved
**Approval evidence:** Owner instruction authorizes task brief, branch, deterministic tests, implementation, validation, commit, push, and one Draft PR.
**Approved boundaries:** Emit one redacted Edamam resolver-success event after a complete factual item is built.
**Explicit non-changes:** No deployment; provider order/fallback, food matching, quantity tolerance, unit compatibility, nutrient math, response contract, Flutter, schema/RLS/RPC, configuration, or secrets changes.

## Active Handoff

**Planning owner:** Current session
**Implementation owner:** Current session
**Review owner:** Current review session
**Implementation ownership state:** Active on existing Draft PR
**Repository state last verified:** Draft PR #303 open and Draft; test correction committed at `c2217d0eac439fb5a3f803914bcdacf6b5aff5bc` before this handoff-only update.
**Branch:** `tnyx/tnyx-243-n5d-9b1-redacted-resolver-success-serving-diagnostics`
**PR / tracker:** Draft PR #303; TNYX-243 In Progress
**Current implementation state:** Initial implementation is on PR #303. The two review P3 items are addressed by focused nutrients-stage failure/timeout + metric-alias coverage and this reconciled handoff metadata.
**Validation remaining:** Verify exact-head Supabase Functions CI and perform a fresh re-review of PR #303.
**Next exact action:** Reconcile the new PR head, require exact-head CI PASS, and re-review. Keep the PR Draft; do not merge, deploy, mark Ready for Review, or run live `2 roti` validation.

## Discovery

### User Outcome

TNYX-242 can distinguish the bounded provider serving category used by a successfully resolved Edamam item without exposing meal, provider, identity, nutrition, or credential data.

### Success Criteria

- One successful Edamam item emits exactly `{ component, stage: "resolver_resolved", provider: "edamam", measureCategory }`.
- `measureCategory` is the closed set `piece | item | whole | unit | metric | other`.
- Failures emit no resolver-success event and current diagnostics/results remain unchanged.
- No raw measure, URI, food/provider identity, meal input, nutrient, session, or credential data appears.

### Non-Goals

No `quantityRelation`; hard-coded roti values; aliases; dal/S2-S5 work; provider routing; live invocation; deployment; or client changes.

## Codebase Exploration

### Verified Evidence

- `EdamamResolver.resolve` validates identity, parsed quantity, compatible measure, nutrient request, and non-null `buildEdamamItem(...)` before returning `resolved`.
- `quantityMatches(...)` makes a success-only quantity relation redundant; mismatches return `amount_mismatch`.
- `normalizeUnit(...)` already normalizes the allowed aliases; `measureIsCompatible(...)` must remain observationally separate.
- Existing `mealParserDiagnostic(...)` serializes a closed event shape, and `edamam_diagnostics_test.ts` captures `console.info` for redaction assertions.

## Architecture Design

### Chosen Approach

- Add `MealParserMeasureCategory` to `diagnostics.ts` and optional `measureCategory` to the diagnostic options.
- Keep a small Edamam-local classifier in `edamam_client.ts`; it calls existing `normalizeUnit(...)` and maps only `g | kg | ml | l | oz` to `metric`, known count labels to their exact category, and all others to `other`.
- Emit after `buildEdamamItem(...)` succeeds and immediately before returning `{ kind: "resolved", item }`.

### Failure and Privacy Boundary

The emitted event contains no free text. It cannot include candidate food name, provider label, food ID, measure URI/label, quantity, nutrients, request URL, provider body, or credentials. It is per successful Edamam item; existing one-event-per-incomplete-meal behavior remains unchanged.

## Implementation Plan

- [x] Add focused failing mapping, success, no-event, redaction, and preservation tests.
- [x] Add the closed diagnostic field and Edamam-local classifier/emission.
- [x] Run focused and full function validation; review the diff.

## Quality Review

### Validation Run

- Expected test-first failure captured: the new `edamamMeasureCategory` export was absent.
- Pre-review baseline: `deno check supabase/functions/nutrition-meal-text-parse/index.ts` — PASS.
- Pre-review baseline: focused diagnostics suite — PASS (9/9).
- Pre-review baseline: full function suite — PASS (119/119).
- Initial sandbox test attempts hit the Windows Deno named-pipe panic; elevated reruns produced the baseline PASS evidence above.
- Pre-review baseline: `git diff --check` — PASS.
- P3 correction adds explicit nutrients-stage transport/HTTP/malformed coverage, an abort-driven timeout case, and the remaining metric aliases accepted by `normalizeUnit(...)`.
- Post-correction source of truth: exact-head GitHub Actions `Supabase Functions CI` for Draft PR #303; verify it before re-review.

## Final Handoff

### Changed Files

- `.ai/tasks/tnyx-243-redacted-resolver-success-serving-diagnostics.md`
- `supabase/functions/nutrition-meal-text-parse/diagnostics.ts`
- `supabase/functions/nutrition-meal-text-parse/edamam_client.ts`
- `supabase/functions/nutrition-meal-text-parse/edamam_diagnostics_test.ts`

### Final Status

REVIEW — both P3 review items are addressed on the existing Draft PR. Exact-head CI and re-review remain required; no deployment performed.
