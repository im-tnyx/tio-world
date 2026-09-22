# TNYX-229 — Deploy and live-validate protected meal-text parser

**Status:** Validated
**Implementation ownership state:** Complete
**Primary owner:** `supabase/functions/nutrition-meal-text-parse`
**Affected platforms:** Supabase Edge Function only (no Flutter, no schema)

`Validated` here means TNYX-229's **technical deployment/runtime scope**
specifically: the function is deployed, JWT-protected, source-matched to
`main`, and its authenticated/outcome/fallback contract is proven live. It
does not mean the feature is commercially production-cleared — see
"Remaining gates" below.

## Owner Approval and Scope Boundary

**Trigger:** None
**Approval status:** Not required
**Approval evidence:** Not applicable — this file documents/reconciles
already-completed, already-owner-authorized technical work (deployment and
live validation performed in prior sessions, tracked in the six PR-specific
briefs below). It is a governance/documentation follow-up inside an already
approved and technically completed slice, not a new task, feature, or
UI/data-shape change.
**Approved product/UI/data-shape boundaries:** Not applicable — no product,
UI, or data-shape change is made or proposed by this file.
**Explicit non-changes:** This file does not authorize any new
parser/runtime/provider implementation, deployment, Gemini retry/re-check,
provider-ordering change, or commercial/licensing decision. Any such work
requires its own separately authorized task.

## Purpose

This is the consolidated reconciliation record for TNYX-229's deployment and
live-validation scope. TNYX-229's actual work was implemented and reviewed
across several narrow PR-specific briefs, each still stale at `Status: Review
ready` from its own PR review and preserved as historical evidence:

- `.ai/tasks/tnyx-229-redacted-runtime-diagnostics.md` (PR #290)
- `.ai/tasks/tnyx-229-gemini-400-request-contract.md` (PR #292)
- `.ai/tasks/tnyx-229-gemini-http-error-status-diagnostic.md` (PR #296)
- `.ai/tasks/tnyx-229-gemini-error-detail-diagnostic.md` (PR #297)
- `.ai/tasks/tnyx-229-gemini-generate-content-compat.md` (PR #298)
- `.ai/tasks/tnyx-229-gemini-response-json-schema.md` (PR #299)

None of those files is a consolidated deploy/live-validation record, and none
existed at this path. This file is new; it does not replace or edit them.

## Scope

**In scope:**

- consolidated TNYX-229 technical validation record;
- current deployed runtime state;
- source/runtime parity evidence;
- Gemini/OpenAI fallback conclusion;
- separation of technical vs. category-B production gates;
- post-merge stale-branch cleanup handoff (description only).

**Out of scope:**

- runtime/source changes;
- Supabase redeploy;
- Gemini retry/re-check;
- provider ordering changes;
- commercial/licensing decisions;
- TNYX-239 implementation;
- branch deletion in this PR.

## Repository state at reconciliation

- `main`: `f3f78074ba69d46877cbd43bd193d1fde8d54581`
- Reconciliation branch: `tnyx/tnyx-229-post-validation-reconcile`, branched from the SHA above
- Old branch `tnyx/tnyx-229-n5d-7a-deploy-and-live-validate-protected-meal-text-parser` (tip `41ebfee823730f617083a31152e76802a55ea611`) contains only historical/stale audit documentation and no production source absent from current `main`. It is not being continued, merged, or deleted by this change.

## Runtime state

- `nutrition-meal-text-parse`: **ACTIVE v38**, `verify_jwt=true` on project `oykupyiitspujzpwwvuj`.
- No deployment was performed to produce this record; the state above is the already-live version from a prior owner-authorized deployment step.

## Source ↔ runtime parity

Deployed v38 was fetched read-only and compared file-by-file against current
`main`. All 14 non-test source files in
`supabase/functions/nutrition-meal-text-parse` (`index.ts`, `composition.ts`,
`handler.ts`, `contract.ts`, `async_control.ts`, `interpreter_orchestrator.ts`,
`interpretation_schema.ts`, `matching.ts`, `resolver.ts`, `gemini_client.ts`,
`openai_client.ts`, `fatsecret_client.ts`, `edamam_client.ts`,
`diagnostics.ts`) matched byte-for-byte. No new deploy was made to establish
this; it was verified against the already-deployed bundle.

## Validation state

- Authenticated execution: **PASS** — multiple live signed-in runs produced a
  provider-neutral draft through the normal user-session path.
- Representative outcome contract: **PASS** — `success`, `unrecognized`
  (`qwerty asdf`), and `incomplete` (`dal`, and separately an Edamam
  `HTTP 401` resolver failure before credential correction) were each
  observed live in the representative matrix; the team's own record states
  the top-level `unavailable` outcome is covered by prior live evidence plus
  deterministic tests, without a retained example of that specific run in
  the evidence this file draws on.
- Provider-neutral response: **PASS** — `contract.ts`'s `ParseResponse` shape
  carries no provider/model identifiers; live successes returned only
  `mealName`/items.
- Error sanitization: **PASS** — `diagnostics.ts` emits only an allowlisted
  field set (`component`, `stage`, `provider`, `reason`,
  `providerErrorCategory/Status/Reason/Field`, `httpStatus`,
  `measureCategory`); no raw provider message/body is ever logged.
- Raw meal text / provider payload persistence: **not introduced** — the
  parser directory has exactly one logging call site (`diagnostics.ts`), and
  it logs only the allowlisted structured event; the handler makes no
  database writes.
- Server deadline: remains `DEFAULT_REQUEST_DEADLINE_MS = 45_000` (unchanged);
  observed live executions (single-digit-second to ~12s) stayed well inside
  the 45s server / 50s Flutter budgets.
- Unauthenticated rejection: validated deterministically by source/test
  contract (`handler_test.ts`: `"unauthenticated request is rejected with
  401"`); no separate live unauthenticated smoke observation was
  required/recorded.
- Required provider configuration present server-side: established by
  functional behavior across the live evidence trail (Gemini, OpenAI,
  FatSecret and Edamam calls each reached their provider), without
  retrieving or printing any secret value.

### Validation checklist

- [x] Deployed source matches current `main` (14/14 non-test parser files, byte-for-byte).
- [x] `verify_jwt=true` on the deployed function.
- [x] Authenticated success observed live.
- [x] `unrecognized` observed live.
- [x] `incomplete` observed live.
- [x] `unavailable` covered by prior live evidence + deterministic tests (no retained specific example).
- [x] Unauthenticated rejection covered by deterministic source test (no live smoke recorded).
- [x] Provider-neutral response contract confirmed from source.
- [x] Error sanitization confirmed from source (allowlisted diagnostic fields only).
- [x] No raw meal text/provider payload persistence.
- [x] OpenAI fallback live success observed when Gemini was unavailable.
- [ ] Direct Gemini `200` observed — not yet; owned by TNYX-239.
- [ ] Category-B commercial/provider gates cleared — not in scope of this record; remain open.

**Exit criteria:** all boxes above that are in TNYX-229's technical scope are
checked. The two unchecked items are explicitly out of this record's scope
(Gemini direct-200 → TNYX-239; category-B gates → separate
commercial/provider decisions) and are not exit blockers for TNYX-229's
technical completion.

## Gemini / OpenAI state

- **Gemini:** the deployed Gemini request code path (`gemini_client.ts`) is
  unchanged since the last direct observations (through the PR #299 merge
  and up to current `main`). The latest direct provider observation remains
  the earlier `HTTP 503 / UNAVAILABLE` evidence from two consecutive
  authenticated runs on the current request/schema contract
  (`responseMimeType` + `responseJsonSchema`). No fresh Gemini availability
  request was made for this reconciliation, so this record does not claim
  Gemini is currently returning `503` or currently healthy — only that the
  code path that produced the `503` evidence has not changed. Direct Gemini
  `200` has not been observed.
- **OpenAI fallback:** live success observed — when Gemini returned 503, the
  overall request still completed with a valid provider-neutral draft through
  the existing sequential fallback (`interpreter_orchestrator.ts`), with no
  regression to the fallback contract.
- **Technical conclusion:** Gemini availability is not a TNYX-229 blocker.
  Remaining Gemini work (later re-check, direct-200 observation,
  provider-operational routing/retry evaluation) is owned by TNYX-239
  (`Backlog`) and is intentionally not duplicated here.

## Remaining gates (category B — not technical, not solved by this record)

TNYX-229's technical deployment/runtime scope is complete. The following
remain separately gated, open, and are **not** claimed as resolved:

- FatSecret country-aware provider entitlement/commercial coverage.
- Durable nutrition-data storage/caching permission (FatSecret and Edamam
  licensing terms).
- Provider attribution requirements.
- OpenAI account-level retention/privacy posture (organization/project
  setting, not visible to connected tooling).
- Gemini account-level billing/privacy tier (not visible to connected
  tooling).

These are production/commercial/provider-account decisions, not unresolved
parser source defects.

## Active Handoff

**Planning owner:** current session
**Implementation owner:** current session (documentation-only correction)
**Review owner:** pending PR review, not yet assigned
**Implementation ownership state:** Complete
**Repository state last verified:** `main` = `f3f78074ba69d46877cbd43bd193d1fde8d54581`
**Branch:** `tnyx/tnyx-229-post-validation-reconcile`
**HEAD SHA:** this commit — the branch tip at `git log -1` on `tnyx/tnyx-229-post-validation-reconcile` (not hardcoded here: amending this file changes its own commit hash, so a literal value would go stale the moment it is edited; the exact pushed head is also recorded on PR #308)
**PR / tracker:** PR #308 (`docs(task): reconcile TNYX-229 technical completion`), Draft, reconciliation/review only, not merged. Linear TNYX-229 = `Done`. Linear TNYX-239 = `Backlog`, owns remaining Gemini work.
**Current implementation state:** technical TNYX-229 implementation is complete; nothing further to implement in this slice.
**Relevant execution surface:** `supabase/functions/nutrition-meal-text-parse` (read-only verification only in this reconciliation).
**Validation completed at SHA:** validation evidence in this file was gathered against deployed v38 and `main` `f3f78074ba69d46877cbd43bd193d1fde8d54581`; no source changed since.
**Validation remaining:** none for TNYX-229's technical scope. Gemini direct-200 observation remains with TNYX-239. Category-B commercial/provider gates remain with their respective owners.
**Current blocker:** none technical. No blocker to PR #308 review.
**Open review finding IDs:** none open (see Findings resolved in this correction commit).
**Next exact action:** owner-authorized review and merge of PR #308; old stale branch cleanup as separate post-merge housekeeping; TNYX-239 remains Backlog for later Gemini follow-up.

## Next action

No further TNYX-229 parser source/deployment work is expected. Any Gemini
follow-up (later availability re-check, retry/backoff evaluation,
OpenAI-primary routing evaluation) belongs to TNYX-239, still `Backlog`.
Cleanup of the old stale branch
`tnyx/tnyx-229-n5d-7a-deploy-and-live-validate-protected-meal-text-parser` is
post-merge housekeeping only, to be done after this reconciliation lands, and
is not performed by this change.
