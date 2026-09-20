# TNYX-229 — Gemini ErrorInfo / BadRequest diagnostic refinement

**Status:** Review ready
**Primary owner:** ChatGPT
**Affected platforms:** Supabase Edge Function only

## Owner Approval and Scope Boundary

**Trigger:** None
**Approval status:** Not required
**Approval evidence:** Owner explicitly said `go` after v28 authenticated smoke confirmed Gemini HTTP 400 with `providerErrorStatus=INVALID_ARGUMENT`.
**Approved product/UI/data-shape boundaries:** Existing TNYX-229 live-validation defect diagnostic refinement only.
**Explicit non-changes:** No Flutter/UI, no Gemini request-envelope/model/provider-order change, no secret/config change, no schema/RLS/RPC/migration, no deployment, no merge, no TNYX-226 work.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** ChatGPT
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** GitHub `main@2b49fb589d3d16ee8d5d9704327854a17dbf3391`; live parser ACTIVE v29, `verify_jwt=true`, bundle SHA `c523ec4320699680c67e8bd925703ad384e5c47d72f6af1bf61d4ea0e171a50f`.
**Branch:** `tnyx/tnyx-229-gemini-error-detail-diagnostic`
**HEAD SHA:** `2b49fb589d3d16ee8d5d9704327854a17dbf3391` at branch creation
**Observed working-tree state:** Not applicable through GitHub connector; branch created from exact current main.
**Observed uncommitted/dirty files:** Not observable / not applicable to connector-only execution.
**PR / tracker:** Draft PR #297; TNYX-229 In Progress; TNYX-226 Backlog / blocked.
**Current implementation state:** Bounded ErrorInfo/BadRequest diagnostic refinement implemented; source validation passed.
**Relevant execution surface:** `supabase/functions/nutrition-meal-text-parse`
**Validation completed at SHA:** `bed033b0a8ea191079985eeffd38063224a41934` — Supabase Functions CI #36 PASS.
**Validation remaining:** None for review readiness; merge/deploy/live observation remain separate owner-authorized gates.
**Current blocker:** Production observation requires separate merge/deploy authorization; source slice has no blocking implementation finding.
**Open review finding IDs:** None.
**Next exact action:** Final exact-head review and Ready for Review. Do not merge/deploy without separate owner authorization.

## 1. Discovery

### User Outcome

Identify whether Gemini's reproducible `INVALID_ARGUMENT` is caused by a known Google infrastructure/API-key reason or by a bounded request-field area, without exposing provider text, secrets, meal text, identity/session data, or raw field paths.

### Success Criteria

- Existing HTTP status diagnostic remains unchanged.
- Exact Google `ErrorInfo.reason` values are emitted only from a closed allowlist; anything else → `UNKNOWN`.
- `BadRequest.fieldViolations[].field` is reduced to one closed category: `schema`, `response_format`, `generation_config`, `contents`, `model`, or `unknown`.
- Both camelCase and snake_case request field paths are recognized.
- Raw `error.message`, `description`, `metadata`, raw detail objects, raw field paths, API key, meal text and JWT/session material never enter diagnostics.
- Gemini request payload, model, timeout, provider order, fallback and client-visible result remain unchanged.

### Scope

- `diagnostics.ts`: bounded provider error reason + field category types/fields.
- `gemini_client.ts`: parse one cloned non-2xx error envelope and extract only allowlisted metadata.
- `gemini_client_test.ts`: focused allowlist, path mapping, malformed/unknown and explicit redaction tests.
- task/PR handoff.

### Non-Goals

- No root-cause request fix in this slice.
- No request-body/schema/model change.
- No secret retrieval or logging.
- No production deploy.
- No TNYX-226 implementation.

## 2. Codebase Exploration

### Verified Evidence

- Current source already emits closed `providerErrorStatus` and never logs raw Gemini body.
- Live v28 smoke succeeded through fallback but emitted `400 / INVALID_ARGUMENT`.
- Live currently reports v29 with the same bundle SHA as v28; the cause of the version increment is not inferred from the version number alone.
- Google GenerateContent legacy API docs show `ErrorInfo.reason=API_KEY_INVALID` inside `error.details[]` for an invalid API key.
- Google common protos define `BadRequest.fieldViolations[].field` as a request-body field path and define `FieldViolation.reason` / `ErrorInfo.reason` as bounded UPPER_SNAKE_CASE reason identifiers.
- Google `googleapis.com` ErrorReason docs provide stable infrastructure reasons including API-key restriction, service/billing and quota categories.

### Plain key/model sanity probe

Not executed. The connected environment does not provide a safe existing path to call Gemini with the current server-side `GEMINI_API_KEY` without either retrieving/exposing the secret or deploying temporary code. Both are outside this slice. Do not weaken secret boundaries to perform this probe.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Log raw provider message/description/metadata? | Rejected | Unbounded text/metadata can leak sensitive request or account details. | ChatGPT |
| Log raw `fieldViolations.field`? | Rejected | Only the bounded request area is needed. | ChatGPT |
| Allow arbitrary UPPER_SNAKE_CASE reason? | Rejected | Shape validation alone does not make provider text safe/stable. | ChatGPT |
| Closed Google infrastructure reason allowlist | Chosen | Actionable while keeping log surface bounded. | ChatGPT |
| Closed request-field category mapping | Chosen | Identifies likely request area without raw path leakage. | ChatGPT |

## 4. Architecture Design

### Chosen Approach

For Gemini non-2xx:
1. clone and parse the provider JSON once;
2. keep current allowlisted gRPC `status`;
3. inspect only `google.rpc.ErrorInfo` details and map exact known reason values, otherwise `UNKNOWN`;
4. inspect only `google.rpc.BadRequest.fieldViolations[].field`;
5. normalize field paths internally and emit only the closed category;
6. ignore raw descriptions, messages, metadata, localized messages and all unrecognized detail fields;
7. emit one existing `interpreter_unavailable` diagnostic and return unchanged `unavailable`.

### Ownership and Data Flow

`Gemini non-2xx response -> one in-memory safe metadata extraction -> mealParserDiagnostic -> unchanged unavailable -> existing OpenAI fallback`

### Alternative Rejected

A direct plain Gemini key/model probe was not performed because no safe connector path can reuse the server secret without reading it or deploying temporary code. Logging raw provider messages was also rejected.

### Failure and Accessibility States

No UI/product-visible change. Missing, malformed or unknown detail values safely reduce to static `UNKNOWN/unknown`.

## 5. Implementation Plan

- [x] Add provider-error reason and request-field category types to diagnostics.
- [x] Parse Gemini error details once and preserve current status classifier.
- [x] Add exact ErrorInfo reason allowlist scoped to `googleapis.com`.
- [x] Add closed BadRequest field-category mapping for camelCase/snake_case paths.
- [x] Add focused redaction/malformed/unknown tests.
- [x] Preserve existing request-envelope regression test.
- [x] Create Draft PR and validate source head; final docs-only head CI remains.

## 6. Quality Review

### Validation Run

- Supabase Functions CI #35: type-checks PASS, parser tests FAIL due a test-only ambiguous assertion where raw field `model` equaled the safe output category `model`.
- Test corrected to use raw path `model.privateProviderPath`; implementation behavior unchanged.
- Supabase Functions CI #36 on source head `bed033b0a8ea191079985eeffd38063224a41934`: PASS.
- Supabase Functions CI #37 on docs-synced head `d8b653045f3c574289f7b548d6afaa3315a9488a`: PASS.
- Parser entrypoint type-check: PASS.
- Parser source/tests type-check: PASS.
- Parser tests: PASS (93 passed).
- Complete `main...branch` delta reviewed: exactly 4 owned files.
- Existing structured-output request-envelope test remains unchanged.
- Review tightening: `ErrorInfo.reason` is accepted only when detail type is `google.rpc.ErrorInfo` and domain is exactly `googleapis.com`.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|

## 7. Final Handoff

### Changed Files

- `.ai/tasks/tnyx-229-gemini-error-detail-diagnostic.md`
- `supabase/functions/nutrition-meal-text-parse/diagnostics.ts`
- `supabase/functions/nutrition-meal-text-parse/gemini_client.ts`
- `supabase/functions/nutrition-meal-text-parse/gemini_client_test.ts`

### Actual Behavior

Gemini non-2xx diagnostics retain the existing allowlisted gRPC status and now additionally emit:
- `providerErrorReason`: only a closed set of documented `googleapis.com` infrastructure reasons, otherwise `UNKNOWN`;
- `providerErrorField`: only `schema | response_format | generation_config | contents | model | unknown`.

The provider response is parsed once from a clone. Raw message, description, metadata, raw field path and unrecognized detail values are never emitted. Runtime outcome remains `unavailable`, preserving existing OpenAI fallback.

### Known Limitations

This slice only narrows safe diagnostics. It does not fix the underlying Gemini request rejection and is not useful in production until separately authorized merge/deploy.

### Final Status

`REVIEW`
