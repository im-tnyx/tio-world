# TNYX-243 — Redacted factual resolver-success serving diagnostics

**Status:** Validated
**Primary owner:** Nutrition / Supabase Edge Function
**Affected platforms:** `supabase/functions/nutrition-meal-text-parse`

## Owner Approval and Scope Boundary

**Trigger:** None — bounded implementation inside the approved TNYX-243 diagnostic slice.
**Approval status:** Approved
**Approval evidence:** Owner instruction authorizes task brief, branch, deterministic tests, implementation, validation, commit, push, and one Draft PR.
**Approved boundaries:** Emit one redacted Edamam resolver-success event after a complete factual item is built.
**Explicit non-changes:** No deployment; provider order/fallback, food matching, quantity tolerance, unit compatibility, nutrient math, response contract, Flutter, schema/RLS/RPC, configuration, or secrets changes.

## Active Handoff

**Planning owner:** Complete
**Implementation owner:** Complete
**Review owner:** Complete
**Implementation ownership state:** Closed — no active source implementation remains in TNYX-243.
**Repository state last verified:** PR #303 merged into `main` as `f797bedd115405dc896764cd7eaef3e871d6118b`; TNYX-243 is Done in Linear.
**Branch:** Historical implementation branch `tnyx/tnyx-243-n5d-9b1-redacted-resolver-success-serving-diagnostics`
**PR / tracker:** PR #303 merged; TNYX-243 Done
**Current implementation state:** The bounded diagnostic implementation and both review corrections are merged. No further source changes belong to this completed slice.
**Post-merge runtime state:** Supabase Edge Function `nutrition-meal-text-parse` is ACTIVE v38 with `verify_jwt=true`.
**Validation remaining:** None for TNYX-243 implementation. Parent audit TNYX-242 remains UNRESOLVED until its bounded provider-serving observation can be correlated.
**Next exact action:** Do not reopen TNYX-243 for the parent audit. Continue any remaining factual classification only under TNYX-242 and its read-only safety boundary.

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
- PR #303 final handoff head `11ecfbec74d75784528618b26147209ee23d10a3`: GitHub Actions `Supabase Functions CI` #50 PASS; focused diagnostics suite PASS (10 tests); full meal-text parser suite PASS (120 passed, 0 failed).
- PR #303 merged to `main` as `f797bedd115405dc896764cd7eaef3e871d6118b`.
- The separately authorized deployment is live as `nutrition-meal-text-parse` v38, ACTIVE, with `verify_jwt=true`.
- TNYX-243 is Done. The remaining TNYX-242 factual classification is a parent-audit concern, not unfinished implementation in this task.

## Final Handoff

### Changed Files

- `.ai/tasks/tnyx-243-redacted-resolver-success-serving-diagnostics.md`
- `supabase/functions/nutrition-meal-text-parse/diagnostics.ts`
- `supabase/functions/nutrition-meal-text-parse/edamam_client.ts`
- `supabase/functions/nutrition-meal-text-parse/edamam_diagnostics_test.ts`

### Final Status

VALIDATED — the bounded diagnostic implementation is review-clean, merged through PR #303, deployed as `nutrition-meal-text-parse` v38, and TNYX-243 is Done. Parent TNYX-242 remains UNRESOLVED pending its own bounded evidence/classification work. No further implementation is active in this task.
