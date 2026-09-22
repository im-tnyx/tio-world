# TNYX-229 — Deploy and live-validate protected meal-text parser

**Status:** Validated (technical deployment/runtime scope)
**Implementation ownership state:** Completed
**Primary owner:** `supabase/functions/nutrition-meal-text-parse`
**Affected platforms:** Supabase Edge Function only (no Flutter, no schema)

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

## Gemini / OpenAI state

- **Gemini:** latest direct evidence is `HTTP 503 / UNAVAILABLE` (two
  consecutive authenticated runs on the current request/schema contract,
  `responseMimeType` + `responseJsonSchema`). Direct Gemini `200` has not yet
  been observed. `gemini_client.ts` has not changed since that evidence was
  recorded (through the PR #299 merge and up to current `main`), so the 503
  evidence remains representative of the currently deployed Gemini code path.
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

## Next action

No further TNYX-229 parser source/deployment work is expected. Any Gemini
follow-up (later availability re-check, retry/backoff evaluation,
OpenAI-primary routing evaluation) belongs to TNYX-239, still `Backlog`.
Cleanup of the old stale branch
`tnyx/tnyx-229-n5d-7a-deploy-and-live-validate-protected-meal-text-parser` is
post-merge housekeeping only, to be done after this reconciliation lands, and
is not performed by this change.
