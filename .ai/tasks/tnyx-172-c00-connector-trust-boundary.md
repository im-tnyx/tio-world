# TNYX-172 C0.0 Slice A — Connector V1 trust boundary

**Status:** In progress
**Primary owner:** Connector architecture / Security & Identity
**Affected platforms:** External connectors / Supabase protected boundary / future services/api

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner said `go` on 2026-09-28 after the fresh connector-first-slice audit.
**Approved boundary:** Architecture/readiness only: freeze the V1 trust boundary, read-only capability classification, threat model, scope taxonomy direction, runtime-host decision criteria, migration invariant, and explicit non-goals.
**Explicit non-changes:** No OAuth server implementation; no connector tables/migrations/RLS; no Supabase Edge Function implementation; no `services/api` scaffold; no ChatGPT client registration/publishing; no Settings UI; no connector tool runtime; no writes; no AI plan generation.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** Codex / independent PR review
**Implementation ownership state:** Complete
**Repository state last verified:** `main@4a038c93a4e3b74a87a80ce167977c3ef35ace2f`
**Branch:** `tnyx/tnyx-172-c00-connector-trust-boundary`
**HEAD SHA:** `07b8890b0af8657b98a3ae79e843fb89a24fbe9c` at the latest exact-head validation before this final fourth-pass handoff update
**Base/parent SHA:** `4a038c93a4e3b74a87a80ce167977c3ef35ace2f`
**Observed working-tree state:** GitHub connector branch; no local working tree available.
**Observed uncommitted/dirty files:** Not applicable through GitHub connector.
**PR / tracker:** GitHub PR #453; Linear TNYX-172 In Review.
**Current implementation state:** Canonical connector trust-boundary baseline, ADR-0012, first-party-vs-delegated Auth reconciliation across Auth/Security/Supabase server-access docs, Supabase runtime-host policy, Health-context classification, provider privacy gate, account-deletion lifecycle gate, and audit controls are written; no connector runtime exists or was authorized.
**Relevant execution surface:** `supabase/` current protected boundary; future `services/api` remains architecture-only under ADR-0007.
**Validation completed at SHA:** `07b8890b0af8657b98a3ae79e843fb89a24fbe9c` — merge-base `4a038c93a4e3b74a87a80ce167977c3ef35ace2f`; ahead 23 / behind 0; exactly 12 owned docs/AI files; all 12 Codex findings through the fourth review are resolved. Required `Commit attribution guard` PASSed. Supplemental `github-advanced-security` FAILED before meaningful analysis because its requested model was unsupported; classification: **supplemental + infrastructure/model failure**, not a concrete security finding and not a security pass.
**Validation remaining:** this final handoff-record commit moves HEAD only in the task brief; re-read exact-head compare/checks after the commit, refresh PR/Linear evidence, then request the next Codex review. Local `git diff --check` remains unavailable through connector-only execution.
**Current blocker:** none.
**Open review finding IDs:** none; all first-, second-, third-, and fourth-pass Codex threads are resolved.
**Next exact action:** verify checks on the final handoff HEAD, refresh PR/Linear scope/security evidence, then comment `@codex review` for the next review pass.

## 1. Discovery

### User Outcome

Establish the smallest safe, vendor-neutral architecture baseline required before Tio exposes any user-owned data to ChatGPT-style or future external agent clients.

### Success Criteria

- V1 is explicitly read-only.
- External clients never receive raw database access, Supabase service-role credentials, or a Supabase session as the public connector contract.
- Every future connector request must resolve an authenticated Tio user, connector client, user-owned grant, effective scopes, and Tio domain authorization.
- Health/profile/nutrition/workout/progress data is purpose-bound and minimum-necessary.
- The first runtime host is selected by concrete need, not architecture symmetry.
- External capability/tool contracts stay stable if execution later moves from a Supabase-first host to `services/api`.
- TNYX-173, TNYX-174, TNYX-245, TNYX-246, TNYX-247, TNYX-248 and related follow-ups can reference one stable baseline.

### Scope

- connector capability/data-action classification;
- trust-boundary diagram;
- threat inventory and required fail-closed properties;
- initial read/write/internal-only classification;
- V1 scope taxonomy direction;
- Supabase-first vs `services/api` trigger decision;
- migration invariant;
- explicit V1 non-goals.

### Non-Goals

- endpoint implementation;
- token issuance;
- OAuth storage schema;
- grant persistence implementation;
- domain read-model implementation;
- ChatGPT adapter metadata;
- mobile Integrations UX;
- connector write actions;
- entitlement implementation;
- worker/queue infrastructure.

## 2. Codebase Exploration

### Verified Evidence

- Root `AGENTS.md` requires audit-first bounded slices, treats OAuth/external integrations as security-sensitive, keeps Supabase active/current, and keeps `services/api` architecture-only until a separately approved concrete server slice requires it.
- `.ai/workflow.md` requires Discovery → Codebase Exploration → Clarification → Architecture Design → Implementation → Quality Review → Final Handoff and prohibits speculative large future areas.
- `.ai/FEATURE_DEVELOPMENT.md` requires owner approval for a new independently scoped product slice; this slice is approved.
- `docs/README.md` reserves `docs/integrations/` for canonical connector/OAuth/ChatGPT docs once a real integration document exists.
- ADR-0007 fixes the current boundary as Supabase Auth/Postgres/RLS + approved Edge Functions, with future `services/api` only when a concrete protected-server trigger exists.
- `docs/security/AUTH_ARCHITECTURE.md` keeps Supabase Auth as canonical Tio identity authority.
- `docs/data/SUPABASE_SERVER_ACCESS.md`, `docs/security/SECRETS_AND_ENVIRONMENTS.md`, and `docs/security/DATA_PRIVACY_GOVERNANCE.md` require least privilege, server-only privileged credentials, sensitive-data minimization, and no secret/token logging.
- Linear TNYX-172 is the unblocked C0 entrypoint. TNYX-173 and TNYX-174 are blocked by it; implementation issues TNYX-245/TNYX-246 and downstream ChatGPT pilot work are not valid first slices.
- Current GitHub search found no connector-specific branch/PR/runtime, no `connector_clients` or `connector_grants` source, and no connector OAuth implementation on `main`.
- Root instructions apply to this docs/`.ai` slice; no nested connector-specific `AGENTS.md` was found.

### Existing Pattern To Follow

Use current narrow Supabase protected-function patterns only when a bounded server-only need fits them; preserve Tio domain ownership and keep external/public contracts independent of Supabase table/function internals. Escalate to future `services/api` only if this or a later approved slice proves an ADR-0007 trigger.

### Tests or Validation Already Present

No connector-specific tests exist because connector runtime is not implemented. This slice is documentation/architecture only; minimum repository validation is docs diff/reference/scope review.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| First connector release is read-only | Locked by TNYX-172 | Minimizes external mutation risk and matches the current dependency graph | Owner / Linear |
| ChatGPT is not a Tio identity authority or Supabase session boundary | Locked | Canonical identity remains Supabase Auth; external credential must resolve through a Tio-controlled authorization layer | Architecture |
| No raw tables, SQL, service-role or privileged DB credentials in connector contract | Locked | Required by AGENTS/security policy and TNYX-172 acceptance | Architecture |
| Runtime host selected by concrete need | Locked | ADR-0007 forbids speculative `services/api`; narrow Supabase protected execution is allowed when sufficient | ADR-0007 / Owner |
| Public connector/tool contracts remain runtime-neutral | Locked | Prevents Supabase-first implementation from becoming external persistence coupling | Linear TNYX-172/TNYX-174 |
| Exact OAuth endpoints/token model | Deferred | Owned by TNYX-173/TNYX-245 | Linear |
| Connector persistence schema | Deferred | Owned by TNYX-246 and requires separate table/column owner approval before implementation | Linear / Owner |
| ChatGPT publishing/configuration | Deferred | Owned by TNYX-248 | Linear |
| Tio Settings → Integrations UI | Deferred | Owned by TNYX-249 and requires its own UI approval | Linear / Owner |

## 4. Architecture Design

### Chosen Approach

A vendor-neutral connector trust boundary with read-only V1 capabilities and Tio-controlled delegated authorization. External clients invoke task-level Tio capabilities, not persistence primitives.

### Ownership and Data Flow

```text
External AI / connector client
  -> Tio delegated authorization boundary
  -> connector client + user-owned grant + effective scopes
  -> Tio capability/domain authorization
  -> bounded application/domain read contract
  -> current approved Supabase protected execution when sufficient
     OR future services/api only after a concrete approved trigger
  -> canonical Tio data
```

### Alternative Rejected

Scaffolding `services/api` before a concrete protected-server requirement is rejected by ADR-0007 and root `AGENTS.md`. Exposing Supabase tables/RLS directly as the public connector contract is rejected because it couples external clients to persistence shape and cannot express connector client/grant/scope semantics safely.

### Failure and Accessibility States

This slice has no UI. Security failures must be designed fail-closed: invalid/revoked credentials, cross-user access, insufficient scope, unavailable capability, excessive export, or unresolved identity/grant context must never degrade into broader access.

## 5. Implementation Plan

- [x] Reconcile root governance, canonical docs, Linear graph, current GitHub state, and source search.
- [x] Inspect representative current Supabase protected-function runtime/config patterns.
- [x] Create canonical `docs/integrations/` connector trust-boundary document.
- [x] Add canonical doc to `docs/README.md`.
- [x] Add this active task to `.ai/tasks/README.md`.
- [x] Validate complete branch scope and documentation references.
- [x] Publish a focused PR for review.
- [x] Reconcile TNYX-172 to review state only after the docs slice is actually review-ready.

## 6. Quality Review

### Validation Run

```text
Validated exact head: 07b8890b0af8657b98a3ae79e843fb89a24fbe9c
Base / merge-base: 4a038c93a4e3b74a87a80ce167977c3ef35ace2f
Branch compare: ahead 23 / behind 0
Changed files: exactly 12 owned docs/AI paths
- .ai/tasks/README.md
- .ai/tasks/tnyx-172-c00-connector-trust-boundary.md
- docs/README.md
- docs/adr/0007-active-supabase-and-future-services-api.md
- docs/adr/0012-delegated-external-connector-trust-boundary.md
- docs/adr/README.md
- docs/architecture/ARCHITECTURE.md
- docs/data/SUPABASE_SERVER_ACCESS.md
- docs/data/SUPABASE_STRATEGY.md
- docs/integrations/CONNECTOR_TRUST_BOUNDARY.md
- docs/security/AUTH_ARCHITECTURE.md
- docs/security/SECURITY.md

Canonical reconciliation: PASS
- ADR-0007 remains Accepted for active Supabase, services/api runtime/namespace, DB ownership, and backend-start triggers.
- ADR-0007 token/sub auth flow is explicitly first-party-only.
- ADR-0012 is authoritative for delegated connector authentication/identity and specializes/amends only that part of ADR-0007.
- First-party vs delegated auth is reconciled across canonical Auth/Security/Supabase server-access docs.
- Connector Health-context, provider-privacy, account-deletion lifecycle, and operational/audit gates remain aligned with canonical privacy/security policy.
- All 12 Codex findings through the fourth review are resolved.

Security merge-gate evidence at 07b8890b...:
- main protected: YES
- required context: Commit attribution guard (app_id 5032971)
- Commit attribution guard: PASS
- github-advanced-security: FAIL, supplemental/non-required by current main branch metadata
- GHAS exact-head analysis outcome: infrastructure/model failure before meaningful analysis ("The requested model is not supported"), not a concrete security finding and not a security pass

Local git diff --check: NOT AVAILABLE through connector-only execution
Runtime/build tests: not applicable to this docs-only slice
Exact-head validation after this final handoff commit: PENDING by construction and must be re-read before requesting the next review
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| R1 | P2 | Resolved | Durable connector trust boundary lacked an ADR | `65e924eaff...` | Added accepted ADR-0012, indexed it, and linked it from connector policy |
| R2 | P2 | Resolved | Security-check requiredness/analysis outcome not recorded | `65e924eaff...` | Current `main` metadata proves only Commit attribution guard required; required guard PASS at `e395389f...`; GHAS classified separately |
| R3 | P2 | Resolved | Validation evidence was not tied to an exact SHA | `65e924eaff...` | Exact validated content head `e395389f...` recorded; post-handoff HEAD explicitly marked pending |
| R4 | P2 | Resolved | Noncanonical task status | `65e924eaff...` | Header/index/final state use canonical `In progress` while review is active |
| R5 | P2 | Resolved | Delegated auth conflicted with canonical first-party auth/runtime docs | `65e924eaff...` | Reconciled AUTH_ARCHITECTURE, ARCHITECTURE and SUPABASE_STRATEGY; linked ADR-0012 |
| R6 | P2 | Resolved | Production pilot lacked provider privacy-review gate | `65e924eaff...` | Connector policy now requires DATA_PRIVACY_GOVERNANCE provider review before sensitive egress |
| R7 | P2 | Resolved | Owner Approval trigger classification missing | `65e924eaff...` | Added canonical Trigger field: New independently scoped product task/feature slice |
| R8 | P2 | Resolved | Shared server checklist could derive delegated user identity from connector token `sub` instead of the validated grant | `7bac3423c2...` | `AUTH_ARCHITECTURE.md` now limits Supabase `sub` derivation to first-party callers and makes validated user-owned connector grant the delegated canonical-user source |
| R9 | P2 | Resolved | Remaining canonical security/server-access docs still required Supabase token/sub for every protected caller | `de1608006b...` | `SECURITY.md` and `SUPABASE_SERVER_ACCESS.md` now distinguish first-party Supabase sessions from delegated grant-based callers and explicitly classify any server-secret DB operation as privileged |
| R10 | P2 | Resolved | Production pilot did not require connector grant/token/provider artifacts to join account deletion lifecycle | `de1608006b...` | Connector policy now requires access/refresh invalidation plus documented synchronous deletion, bounded queued deletion, short expiry, or approved retention outcome |
| R11 | P2 | Resolved | Workout/nutrition/progress were classified below canonical Health-context | `de1608006b...` | Connector classification now uses Health-context highest-applicable handling for workout, nutrition, progress, weight/body metrics and related health/fitness context |
| R12 | P2 | Resolved | Accepted ADR-0007 still described services/api auth as Supabase-token-only, conflicting with ADR-0012 delegated auth | `07eb38bec2...` | ADR-0007 now scopes its token/sub flow to first-party callers and explicitly records ADR-0012 as the delegated-auth specialization/amendment without superseding ADR-0007's broader runtime decision |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/README.md`
- `.ai/tasks/tnyx-172-c00-connector-trust-boundary.md`
- `docs/README.md`
- `docs/adr/0007-active-supabase-and-future-services-api.md`
- `docs/adr/0012-delegated-external-connector-trust-boundary.md`
- `docs/adr/README.md`
- `docs/architecture/ARCHITECTURE.md`
- `docs/data/SUPABASE_SERVER_ACCESS.md`
- `docs/data/SUPABASE_STRATEGY.md`
- `docs/integrations/CONNECTOR_TRUST_BOUNDARY.md`
- `docs/security/AUTH_ARCHITECTURE.md`
- `docs/security/SECURITY.md`

### Actual Behavior

No runtime behavior change is authorized or intended.

### Known Limitations

This slice freezes architecture/security intent only. OAuth, grants, read-models, adapter configuration, runtime hosting implementation and UI remain separately gated.

### Final Status

`In progress`
