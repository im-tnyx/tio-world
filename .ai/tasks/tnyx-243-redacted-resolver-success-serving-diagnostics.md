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
**Implementation ownership state:** Paused after review-clean implementation; no further source edits are approved in this lifecycle step.
**Repository state last verified:** PR #303 is open, mergeable, and Ready for Review; TNYX-243 is In Review. Implementation head immediately before this governance-only handoff update was `9d91b633907992bf9f1babdd3549de193cce5887`, with Supabase Functions CI #49 PASS and fresh review CLEAN.
**Branch:** `tnyx/tnyx-243-n5d-9b1-redacted-resolver-success-serving-diagnostics`
**PR / tracker:** PR #303 Ready for Review; TNYX-243 In Review
**Current implementation state:** Bounded implementation and both P3 corrections are review-clean. This handoff update changes governance metadata only; production/runtime code is unchanged.
**Validation remaining:** Require exact-head Supabase Functions CI PASS for this governance-only handoff commit before any merge decision.
**Next exact action:** After exact-head CI PASS, stop for explicit owner merge decision. Do not merge, deploy, or run live `2 roti` validation without separate owner authorization.

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
- Exact implementation head `9d91b633907992bf9f1babdd3549de193cce5887`: GitHub Actions `Supabase Functions CI` #49 PASS; focused diagnostics suite PASS (10 tests); full meal-text parser suite PASS (120 passed, 0 failed); fresh review CLEAN.
- PR #303 was then moved to Ready for Review and TNYX-243 to In Review under owner authorization.
- This final handoff edit is governance-only; its resulting exact head still requires CI PASS before any merge decision.

## Final Handoff

### Changed Files

- `.ai/tasks/tnyx-243-redacted-resolver-success-serving-diagnostics.md`
- `supabase/functions/nutrition-meal-text-parse/diagnostics.ts`
- `supabase/functions/nutrition-meal-text-parse/edamam_client.ts`
- `supabase/functions/nutrition-meal-text-parse/edamam_diagnostics_test.ts`

### Final Status

REVIEW READY — implementation review is CLEAN, PR #303 is Ready for Review, and TNYX-243 is In Review. Merge, deployment, and live `2 roti` validation remain separate owner-controlled gates.
