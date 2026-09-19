# TNYX-234 — FatSecret fail-closed for non-US country without localization entitlement

**Status:** Validated
**Primary owner:** TNYX-234 / Nutrition
**Affected platforms:** Supabase Edge Function source only

## Owner Approval and Scope Boundary

**Trigger:** Existing approved TNYX-234 source-safety slice
**Approval status:** Approved
**Approval evidence:** Owner explicitly approved continuing development/testing without FatSecret Premier/static-egress and confirmed country is user-selected account/profile data.
**Approved product/UI/data-shape boundaries:** No UI or schema change. Use existing authenticated `public.user_profiles.country_code`. Under current FatSecret Basic scope, only `US` may reach FatSecret; every other valid country must fail closed before any FatSecret network call. Existing Edamam fallback remains allowed for synthetic development testing.
**Explicit non-changes:** No Flutter/UI, no DB migration/RLS/RPC, no deployment, no secret mutation, no `services/api` implementation, no TNYX-226 work.

## Active Handoff

**Planning owner:** ChatGPT / Linear
**Implementation owner:** ChatGPT
**Review owner:** ChatGPT
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** `main@f0e8ca40704dcf0612c147d7a1449608c1d026fb`; branch head `649c6f266d15f818479cdc9d99337c6ac6f699d6`; 3 ahead / 0 behind; exact 3-file scope; PR #286 draft and mergeable
**Branch:** `tnyx/tnyx-234-n5d-7d-fatsecret-fail-closed-for-non-us-country-without`
**HEAD SHA:** `649c6f266d15f818479cdc9d99337c6ac6f699d6`
**Observed working-tree state:** API-based agent; equivalent branch/base reconciliation completed
**Observed uncommitted/dirty files:** Not applicable through GitHub API
**PR / tracker:** GitHub PR #286 draft; Linear TNYX-234 In Progress; blocks TNYX-229
**Current implementation state:** Source + focused tests implemented and validated; no open review findings
**Relevant execution surface:** `supabase/functions/nutrition-meal-text-parse/fatsecret_client.ts`, `providers_test.ts`
**Validation completed at SHA:** `649c6f266d15f818479cdc9d99337c6ac6f699d6` — Supabase Functions CI #8 PASS; entrypoint type-check PASS; source/tests type-check PASS; parser tests PASS
**Validation remaining:** External review/owner merge decision only
**Current blocker:** None for source fix
**Open review finding IDs:** None
**Next exact action:** Mark PR #286 Ready for Review and reconcile Linear to In Review. Do not merge or deploy without separate owner instruction.

## 1. Discovery

### User Outcome

Keep current Supabase-first development moving safely while preventing a non-US account from silently receiving US-default FatSecret data under a Basic-only entitlement.

### Success Criteria

- Saved user country remains the only routing input.
- `US` can use FatSecret as today.
- Any other canonical two-letter country returns FatSecret `incomplete` before token/network work.
- Existing fallback orchestration may try Edamam.
- No provider-specific behavior leaks into Flutter/domain contracts.

### Scope

- Smallest source change in FatSecret resolver.
- Focused provider regression tests.
- Task/PR evidence.

### Non-Goals

- Premier/localization entitlement.
- Fixed/static egress.
- Deployment/live validation.
- Flutter/UI or persistence changes.

## 2. Codebase Exploration

### Verified Evidence

- `FatSecretResolver.resolve` currently validates any uppercase two-letter country and then calls OAuth token, search and detail with `region=<country>`.
- OAuth scope is hard-coded to `basic`.
- Existing tests currently expect FR/ZZ pass-through.
- TNYX-233 already provides caller-scoped `user_profiles.country_code`.
- Live Supabase still has only `google-login-admission`; meal parser is not deployed.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Country source | Locked | Authenticated user's saved `user_profiles.country_code`; no IP/phone/timezone/language inference | Owner |
| Non-US FatSecret under Basic | Locked | Fail closed before FatSecret network to prevent silent US fallback | Owner |
| Edamam fallback in dev/test | Locked | Allowed for synthetic testing; not proof of production localization | Owner |
| Static egress | Deferred | Future `services/api`/fixed-egress boundary | Owner |

## 4. Architecture Design

### Chosen Approach

Keep current resolver contract and fallback orchestration. Add an entitlement-safe guard inside `FatSecretResolver.resolve`: canonical `US` proceeds; any other valid country returns `incomplete` before `#getToken`.

### Ownership and Data Flow

```text
authenticated user profile country
-> parser resolver context
-> FatSecretResolver
   -> US: FatSecret Basic path
   -> non-US: incomplete, zero FatSecret calls
-> existing fallback orchestration may try Edamam
```

### Alternative Rejected

Passing arbitrary non-US `region` under Basic and trusting provider errors. The provider may ignore localization without a verifiable response-region field.

### Failure and Accessibility States

Non-visual. Missing/invalid country remains `incomplete`. Non-US is deliberately `incomplete` from FatSecret so fallback can run.

## 5. Implementation Plan

- [x] Guard FatSecret to `US` only under current Basic scope.
- [x] Update country mapping tests.
- [x] Add zero-network-call tests for IN/FR/ZZ.
- [x] Keep US search/detail region assertions.
- [x] Validate focused/full parser suite.
- [x] Open draft PR with exact scope evidence.

## 6. Quality Review

### Validation Run

```text
Supabase Functions CI #8: PASS
- Type-check parser entrypoint: PASS
- Type-check parser source and tests: PASS
- Run parser tests: PASS
PR #286: mergeable=true, unresolved review threads=0
Branch scope: 3 ahead / 0 behind; exact 3 changed files
Live Supabase: nutrition-meal-text-parse remains NOT DEPLOYED
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| QR-1 | — | Resolved | No open code-review findings after full PR diff + CI review | `649c6f266d15f818479cdc9d99337c6ac6f699d6` | PR #286 has 0 review threads; CI #8 passed |

## 7. Final Handoff

### Changed Files

`.ai/tasks/tnyx-234-fatsecret-non-us-fail-closed.md`
`supabase/functions/nutrition-meal-text-parse/fatsecret_client.ts`
`supabase/functions/nutrition-meal-text-parse/providers_test.ts`

### Actual Behavior

Under the current FatSecret Basic scope, only canonical `US` proceeds to FatSecret token/search/detail requests. `IN`, `FR`, `ZZ`, or any other non-US/invalid value returns FatSecret `incomplete` before any FatSecret network call, preserving existing fallback orchestration.

### Known Limitations

Production localization entitlement, FatSecret static-egress networking, durable nutrition storage, and production AI privacy remain future gates.

### Final Status

`REVIEW`
