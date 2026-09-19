# TNYX-234 — FatSecret fail-closed for non-US country without localization entitlement

**Status:** In progress
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
**Review owner:** Pending
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** main at `f0e8ca40704dcf0612c147d7a1449608c1d026fb`; TNYX-234 branch created from main; no PR yet
**Branch:** `tnyx/tnyx-234-n5d-7d-fatsecret-fail-closed-for-non-us-country-without`
**HEAD SHA:** `f0e8ca40704dcf0612c147d7a1449608c1d026fb` before implementation
**Observed working-tree state:** API-based agent; equivalent branch/base reconciliation completed
**Observed uncommitted/dirty files:** Not applicable through GitHub API
**PR / tracker:** Linear TNYX-234 In Progress; blocks TNYX-229
**Current implementation state:** Ready for smallest source/test patch
**Relevant execution surface:** `supabase/functions/nutrition-meal-text-parse/fatsecret_client.ts`, `providers_test.ts`
**Validation completed at SHA:** Existing main parser suite previously 78/78; TNYX-234 validation not yet run
**Validation remaining:** focused parser tests + CI
**Current blocker:** None for source fix
**Open review finding IDs:** None
**Next exact action:** Implement non-US fail-closed before token request and update focused tests.

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

- [ ] Guard FatSecret to `US` only under current Basic scope.
- [ ] Update country mapping tests.
- [ ] Add zero-network-call tests for IN/FR/ZZ.
- [ ] Keep US search/detail region assertions.
- [ ] Validate focused/full parser suite.
- [ ] Open draft PR with exact scope evidence.

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| | | Open | | | |

## 7. Final Handoff

### Changed Files

Pending.

### Actual Behavior

Pending implementation.

### Known Limitations

Production localization entitlement, FatSecret static-egress networking, durable nutrition storage, and production AI privacy remain future gates.

### Final Status

`PARTIAL`
