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
**Review owner:** Not assigned
**Implementation ownership state:** Active
**Repository state last verified:** Clean
**Branch:** `tnyx/tnyx-243-n5d-9b1-redacted-resolver-success-serving-diagnostics`
**HEAD SHA:** `4fc08a81531aa043f505eb188efa58ec2bfeca03`
**PR / tracker:** TNYX-243 In Progress; no PR yet
**Current implementation state:** Implemented locally; commit/push/Draft PR and tracker handoff pending.
**Validation remaining:** Final post-commit branch/ahead-behind audit.
**Next exact action:** Commit the reviewed bounded change, push, create one Draft PR, and hand off to TNYX-243.

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
- `deno check supabase/functions/nutrition-meal-text-parse/index.ts` — PASS.
- `deno test --allow-read=supabase/functions/nutrition-meal-text-parse supabase/functions/nutrition-meal-text-parse/edamam_diagnostics_test.ts` — PASS (9/9).
- `deno test --allow-read=supabase/functions/nutrition-meal-text-parse supabase/functions/nutrition-meal-text-parse` — PASS (119/119).
- Initial sandbox test attempts hit the Windows Deno named-pipe panic; elevated reruns produced the PASS evidence above.
- `git diff --check` — PASS.

## Final Handoff

### Changed Files

- `.ai/tasks/tnyx-243-redacted-resolver-success-serving-diagnostics.md`
- `supabase/functions/nutrition-meal-text-parse/diagnostics.ts`
- `supabase/functions/nutrition-meal-text-parse/edamam_client.ts`
- `supabase/functions/nutrition-meal-text-parse/edamam_diagnostics_test.ts`

### Final Status

REVIEW — implementation validated locally; no deployment performed.
