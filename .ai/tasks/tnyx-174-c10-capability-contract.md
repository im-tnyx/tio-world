# TNYX-174 C1.0 Slice A — Vendor-neutral Tio capability contract

**Status:** In progress
**Primary owner:** Connector Architecture + Application/Domain Architecture
**Affected platforms:** External connectors / future MCP adapter / future REST/OpenAPI adapter / future Siri/App Intents adapter / current Supabase protected boundary / future services/api

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner said `Go` on 2026-09-28 after the fresh post-TNYX-173 sequencing audit and explicitly asked to continue through PR + Codex review.
**Approved product/UI/data-shape boundaries:** Architecture/readiness only: freeze the vendor-neutral Tio capability identity, request/result envelope semantics, capability discovery semantics, bounded pagination/range rules, error categories, compatibility/versioning expectations, correlation/audit metadata, read retry expectations, async handoff boundary, and adapter ownership rules.
**Explicit non-changes:** No MCP server/SDK/package; no REST/HTTP routes; no OpenAPI generation; no Supabase Edge Function implementation; no Supabase table/column/RLS/RPC changes; no `services/api` scaffold; no Workout/Nutrition/Profile tool implementation; no ChatGPT client/publishing work; no Siri/App Intents implementation; no write capability enablement; no queue/worker implementation.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** Codex / independent PR review
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** `main@da7e05b6488a92fefd4d9a67aa2e01f7c65b52ea`
**Branch:** `tnyx/tnyx-174-c10-capability-contract`
**HEAD SHA:** `000edae137b4b1285ad85031f33083c18cc17cd7` at the latest completed content + R1-R3 resolution validation before this handoff update
**Observed working-tree state:** GitHub connector branch; no local working tree available.
**Observed uncommitted/dirty files:** Not applicable through GitHub connector.
**PR / tracker:** GitHub PR #457; Linear TNYX-174 In Review.
**Current implementation state:** Canonical vendor-neutral capability contract, ADR-0014, and authority links are authored. No MCP server, connector gateway runtime, connector tool implementation, Supabase connector runtime, or services/api runtime is introduced.
**Relevant execution surface:** Current product/domain ownership remains Flutter/domain + Supabase; this slice defines a logical capability boundary only.
**Validation completed at SHA:** `71d9685cb246ddbd351af41f29a307f3e3222045` — branch remained exactly 9 owned docs/AI files and ahead 19 / behind 0; Codex R1-R3 fixes were self-reviewed against the canonical capability contract + ADR-0014; all three review threads received evidence replies and were resolved.
**Validation remaining:** this handoff update moves HEAD; refresh exact-head compare/checks, request a fresh Codex review, and resolve any new validated in-scope findings. Local `git diff --check` is unavailable through connector-only execution and is not claimed as run.
**Current blocker:** none.
**Open review finding IDs:** none; R1-R3 are fixed, replied to, and resolved. Fresh exact-head re-review pending.
**Next exact action:** request Codex review against the new exact PR #457 head after this handoff commit; inspect exact-head checks and stop at review handoff unless another validated finding requires an in-scope fix.

## 1. Discovery

### User Outcome

Define one stable Tio capability contract that can be exposed through ChatGPT/MCP, future REST/OpenAPI, Siri/App Intents, mobile/web orchestration, and later execution hosts without duplicating domain logic or leaking persistence/runtime details.

### Success Criteria

- Capability identity is Tio-owned, follows a stable semantic naming convention, and is independent of MCP tool names, HTTP paths, provider names, or database shape.
- Inputs/outputs are explicit, structured, minimum-necessary, versionable, and testable.
- Read capabilities have bounded pagination/range/timezone semantics and deterministic missing/not-found/authorization behavior.
- Capability discovery communicates supported behavior/availability, not authorization or entitlement.
- Connector adapters are thin translations over Tio application/domain capabilities.
- MCP wire-version changes do not force Tio domain capability renames or DTO rewrites; future adapter implementation re-checks the then-current MCP spec.
- HTTP/OpenAPI global lifecycle/error/pagination owners remain authoritative; this slice defines connector/domain semantics and mapping only.
- Async/long-running capability semantics can later map to an approved MCP task/job or Tio async primitive without creating a worker now.
- Raw tables/RPC/provider payloads/service-role access never become the public connector contract.

### Scope

- logical gateway/capability boundary;
- capability naming/identity;
- request/result schema principles;
- scope/domain authorization handoff;
- pagination/range/timezone conventions at capability level;
- machine-readable capability error categories;
- discovery/availability semantics;
- correlation/audit metadata expectations;
- read retry/idempotency classification;
- async/deferred-result abstraction boundary;
- compatibility/versioning rules;
- MCP adapter mapping principles;
- REST/OpenAPI and Siri/App Intents mapping principles;
- initial read-only candidate registry/classification without implementing domain contracts.

### Non-Goals

- MCP server implementation or protocol package selection;
- HTTP route/path definitions;
- OpenAPI runtime/schema implementation;
- connector OAuth/grant persistence implementation;
- domain-specific Workout/Nutrition schemas owned by TNYX-247/TNYX-252;
- profile/health summary schemas owned by TNYX-175;
- write-action semantics owned by TNYX-176;
- operational rate-limit/kill-switch implementation owned by TNYX-177;
- cross-app health egress policy owned by TNYX-251;
- ChatGPT/Siri adapter implementation;
- services/api/worker scaffolding.

## 2. Codebase Exploration

### Verified Evidence

- Root `AGENTS.md` requires audit-first bounded slices and no speculative backend/runtime expansion.
- `main@da7e05b6...` has no open PRs at slice start.
- TNYX-172 and TNYX-173 are Done/archived and establish delegated trust + OAuth authorization boundaries.
- TNYX-174 blocks TNYX-247, TNYX-252, TNYX-175, TNYX-176, TNYX-177, TNYX-248 and other downstream connector work.
- Repository search found no MCP/tool gateway implementation, MCP server package, `get_profile`/connector tool runtime, or services/api connector route.
- `API_LIFECYCLE.md` owns public API compatibility/versioning and keeps DB schema separate from public contracts.
- TNYX-43 locks TypeBox -> JSON Schema -> OpenAPI for future protected HTTP routes; connector capability semantics must not create a competing HTTP schema source.
- TNYX-28 owns global HTTP validation/error envelope rules; TNYX-29 owns protected API rate limits/timeouts/logging; TNYX-134 owns HTTP pagination/mutation/concurrency semantics.
- `OBSERVABILITY.md` owns safe correlation/telemetry principles; connector capability metadata should map to it, not duplicate it.
- Current MCP final revision is 2026-07-28. It introduces the modern `server/discover` lifecycle and a stateless per-request era. MCP SDK/spec behavior is adapter-level external protocol behavior, not Tio domain ownership.
- MCP 2026-07-28 supports structured tool results and current SDKs expose JSON Schema-based tool input/output contracts; Tio can map stable DTOs to those schemas without making MCP the canonical domain schema owner.
- MCP Tasks is currently an optional/draft extension for deferred execution, not permission to add a Tio worker/job runtime in this slice.

### Existing Pattern To Follow

Preserve the connector migration invariant:

```text
external adapter contract
  -> delegated authorization
  -> Tio capability/application contract
  -> implementation adapter
  -> canonical domain owner/data
```

Keep capability identity and DTO semantics stable while adapters translate to protocol-specific shapes.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Tio capability identity is canonical; MCP/HTTP/Siri names are adapter mappings | Approved for contract | Prevents vendor/protocol coupling | Connector Architecture |
| V1 capability contract is read-only | Locked by ADR-0012 | First connector release remains bounded read-only | Connector Architecture |
| Capability schemas are explicit JSON-compatible DTO contracts, not DB rows | Approved for contract | Stable/testable/minimum-necessary output | Domain owners + Connector |
| MCP protocol revision is not a Tio capability version | Approved for contract | External protocol revisions evolve independently | Connector Adapter |
| Capability discovery reports support/availability, not authorization | Approved for contract | Discovery must not leak or grant authority | Connector + Security |
| HTTP error/pagination/versioning global policy remains owned by Backend docs/tasks | Approved boundary | Avoid duplicate sources of truth | Backend & Platform |
| Aggregate capabilities declare all required scope families with V1 `all_of` semantics | Approved after Codex R1 | Prevent single-scope authorization of multi-domain aggregates | Connector + Security |
| Bounded history includes cumulative server-side lookback/coverage control | Approved after Codex R2 | Prevent repeated pages/windows from reconstructing unrestricted history | Domain owner + Connector |
| Retryable reads may emit operational audit/telemetry but no user/domain mutation | Approved after Codex R3 | Preserve required audit evidence without misclassifying reads as mutations | Connector + Observability |
| Adapter-specific tool descriptions/prompts are non-canonical presentation metadata | Approved boundary | Domain meaning must remain vendor neutral | Adapter owner |
| Async/deferred work uses a transport-neutral operation/result concept only when needed | Approved boundary | Avoid speculative queue/worker/runtime | Future owning slice |
| Exact MCP SDK/package/server host | Deferred | Implementation-time adapter decision | TNYX-248 / owning runtime slice |
| Exact domain tool schemas for Workout/Nutrition/Profile summaries | Deferred | Owned by TNYX-247/TNYX-252/TNYX-175 | Domain owners |

## 4. Architecture Design

### Chosen Approach

A logical Tio capability registry/contract sits between delegated authorization and protocol adapters. Each capability has a stable semantic identity, owner, complete required scope-family set plus combination semantics, input/output contract, boundedness/privacy rules, availability state, error categories, and compatibility policy.

```text
ChatGPT / MCP / Siri / future HTTP client
        ↓ thin protocol adapter
Tio capability identity + typed request/result
        ↓
delegated client/grant/scope resolution where external
        ↓
domain/resource authorization
        ↓
feature-owned application/domain contract
        ↓
current approved execution boundary
        ↓
canonical Tio data
```

The logical gateway is not a new service. It is an architecture boundary that can later be implemented in an approved Supabase protected function or future `services/api` without changing the capability contract.

### Alternative Rejected

- MCP-native tool schemas as Tio's canonical domain schema: rejected because protocol versions/SDKs evolve independently.
- REST/OpenAPI paths as canonical capability identity: rejected because HTTP is one adapter/transport.
- Generic CRUD/table tools: rejected because they leak persistence and bypass domain ownership/minimization.
- One giant `get_health_data` capability: rejected because it weakens purpose limitation and bounded authorization.
- services/api/MCP server scaffolding now: rejected because this planning slice proves no implementation trigger.
- Re-defining global HTTP errors/pagination/rate limits here: rejected because those have existing owners.

## 5. Implementation Plan

- [x] Reconcile root governance, current main, TNYX-172/173 outputs, TNYX-174 dependency graph, API lifecycle/architecture ownership, and current source searches.
- [x] Re-check current MCP final protocol revision and modern lifecycle/tool schema direction.
- [x] Create approved focused task brief.
- [x] Create canonical connector capability/gateway contract under `docs/integrations/`.
- [x] Record durable capability/adaptor ownership decision in ADR-0014 and index it.
- [x] Reconcile connector trust-boundary / delegated OAuth / architecture / docs index links only where needed.
- [x] Add active task to `.ai/tasks/README.md`.
- [x] Audit exact branch delta and current security-check requirements.
- [x] Publish focused PR; move TNYX-174 to In Review after this handoff update.
- [x] Request Codex exact-head review and inspect required/supplemental checks; first substantive review produced R1-R3.
- [x] Resolve validated in-scope findings R1-R3 in docs/ADR, reply with evidence, and resolve all three threads; fresh exact-head review remains pending.

## 6. Quality Review

### Validation Run

```text
Validated content head: 71d9685cb246ddbd351af41f29a307f3e3222045
Base / merge-base: da7e05b6488a92fefd4d9a67aa2e01f7c65b52ea
Branch compare at that head: ahead 19 / behind 0
Changed files: exactly 9 owned docs/AI paths
- .ai/tasks/README.md
- .ai/tasks/tnyx-174-c10-capability-contract.md
- docs/README.md
- docs/adr/0014-vendor-neutral-connector-capability-contract.md
- docs/adr/README.md
- docs/architecture/ARCHITECTURE.md
- docs/integrations/CONNECTOR_CAPABILITY_CONTRACT.md
- docs/integrations/CONNECTOR_TRUST_BOUNDARY.md
- docs/integrations/DELEGATED_OAUTH_AUTHORIZATION.md

Runtime/source inspection: PASS
- no MCP server/SDK, connector gateway/tool runtime, connector Supabase function/schema, REST route/OpenAPI runtime, services/api or worker implementation added

Canonical reconciliation: PASS
- trust and delegated OAuth boundaries preserved
- ADR-0014 records Tio-owned capability semantics and thin adapter ownership
- capability naming convention is Tio semantic dot notation; existing get_* names remain adapter candidates
- API lifecycle/OpenAPI ownership remains under Backend & Platform
- detailed HTTP error/rate/pagination tasks are referenced without being falsely marked implemented
- MCP 2026-07-28 is an external adapter protocol revision, not a Tio capability version
- optional/draft MCP Tasks is not adopted

Security-sensitive merge-gate baseline:
- main protected: YES
- required context: Commit attribution guard (app_id 5032971)
- required `Commit attribution guard` passed on the prior reviewed head; exact-head checks after this handoff commit are PENDING by construction
- local git diff --check: NOT AVAILABLE through connector-only execution
- runtime/build tests: not applicable to this docs/architecture-only slice
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| R1 | P2 | Resolved in branch | Capability descriptor modeled only one required scope; aggregate capabilities need complete scope sets and combination semantics. | `d144a28639` | `required_scope_families` + V1 `all_of`; aggregate capabilities list every needed domain scope. |
| R2 | P2 | Resolved in branch | Per-request pagination/range bounds could still permit cumulative full-history reconstruction. | `d144a28639` | Require server-authoritative cumulative lookback/coverage control across pages and adjacent windows. |
| R3 | P2 | Resolved in branch | Retry rule forbade all durable state, conflicting with required audit/metrics/rate-limit records. | `d144a28639` | Retryable reads forbid user/domain mutation while allowing separately attributed operational evidence. |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/README.md`
- `.ai/tasks/tnyx-174-c10-capability-contract.md`
- `docs/README.md`
- `docs/adr/0014-vendor-neutral-connector-capability-contract.md`
- `docs/adr/README.md`
- `docs/architecture/ARCHITECTURE.md`
- `docs/integrations/CONNECTOR_CAPABILITY_CONTRACT.md`
- `docs/integrations/CONNECTOR_TRUST_BOUNDARY.md`
- `docs/integrations/DELEGATED_OAUTH_AUTHORIZATION.md`

### Actual Behavior

No runtime behavior changed. This slice freezes vendor-neutral Tio capability semantics, adapter ownership and ADR-0014 only.

### Known Limitations

This slice freezes shared capability semantics only. Domain-specific read schemas, external protocol adapters, OAuth runtime, operational controls, and production publishing remain separately gated.

### Final Status

`REVIEW`
