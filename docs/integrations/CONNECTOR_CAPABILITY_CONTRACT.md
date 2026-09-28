# Connector Capability Contract

Document Status: Canonical Live Doc
Last Verified: 2026-09-28
Owner: Connector Architecture + Application/Domain Architecture
Truth Boundary: Authoritative for Tio's vendor-neutral connector capability identity, request/result semantics, boundedness, discovery, error categories, compatibility, and adapter ownership; not proof that an MCP server, HTTP route, Supabase connector function, domain connector tool, or services/api runtime is implemented.

## Status

**Architecture/application contract for TNYX-174 C1.0. Runtime implementation is not started by this document.**

This document builds on:

- [Connector Trust Boundary and V1 Exposure Policy](CONNECTOR_TRUST_BOUNDARY.md)
- [Delegated OAuth Authorization Contract](DELEGATED_OAUTH_AUTHORIZATION.md)
- [ADR-0012](../adr/0012-delegated-external-connector-trust-boundary.md)
- [ADR-0013](../adr/0013-delegated-oauth-authorization-contract.md)

The first connector release remains **read-only**.

## Core Rule

Tio capabilities are canonical application/domain contracts. Protocols and external ecosystems adapt to those contracts.

```text
external host/client
  -> protocol/ecosystem adapter
     (MCP / future REST/OpenAPI / Siri-App Intents / other)
  -> Tio capability identity + typed request
  -> delegated authorization context where external
  -> capability availability
  -> Tio domain/resource authorization
  -> feature-owned application/domain operation
  -> current approved execution boundary
  -> canonical Tio data
  -> typed Tio capability result
  -> adapter-specific response
```

The capability contract is **not**:

- an MCP server contract;
- an HTTP route catalog;
- a database schema;
- a Supabase RPC catalog;
- a provider payload;
- an OpenAI/ChatGPT-specific tool catalog;
- a replacement for feature/domain ownership.

## Capability Identity

Each capability has one stable Tio-owned semantic identity.

Canonical capability IDs use a lowercase, dot-separated semantic convention:

```text
<domain>.<resource-or-purpose>.<operation>
```

Illustrative identities include:

```text
profile.current.get
goals.current.get
nutrition.summary.get
training.summary.get
progress.summary.get
activity.summary.get
profile.audit.run
```

Linear's existing `get_profile`, `get_goals`, `get_nutrition_summary`, and similar names remain candidate **adapter/tool names**, not canonical Tio capability IDs. Domain-specific follow-ups finalize the exact implemented IDs and schemas inside this naming rule.

Rules:

- capability identity describes **what Tio does**, not how it is transported;
- MCP tool names, HTTP paths, Siri/App Intent names, UI labels, and provider listing names are adapter mappings;
- a protocol version change must not force a Tio capability rename;
- a database/table/column rename must not force a Tio capability rename;
- capability names must not encode product UI placement or vendor names;
- aliases may exist in adapters for compatibility, but one Tio capability remains canonical.

## Capability Descriptor

A capability contract should define, at minimum:

```text
id
owner
operation_class        # read now; future write/generation separately gated
required_scope_families
scope_combination       # V1 default: all_of
availability_state
request_schema
result_schema
boundedness_policy
error_categories
compatibility_revision
privacy_classification
correlation_policy
async_behavior         # immediate unless explicitly approved otherwise
```

This is a conceptual contract, not a persistence schema.

### Owner

The existing Tio domain/application owner remains authoritative.

Examples:

- Workout owns routines/workouts/exercises/history.
- Nutrition owns meals/foods/targets/diary semantics.
- Progress owns measurements/trends/progress analytics.
- Profile owns approved profile context.
- Recovery will own recovery/readiness when its canonical slice exists.

Connector code does not become a parallel owner.

### Required scope families

A capability declares the complete set of delegated scope families needed to evaluate it, such as `[\"workout.read\"]` or an aggregate set such as `[\"profile.read\", \"nutrition.read\", \"workout.read\"]`.

Rules:

- the descriptor uses `required_scope_families`, even when only one scope is required;
- V1 combination semantics are `all_of`: every listed scope family must be present in the current effective grant before the capability is eligible to execute;
- an empty list is allowed only for an explicitly public/non-user capability that has been separately approved; no V1 health/profile connector capability is public;
- aggregate capabilities such as `profile.audit.run` must list every domain scope needed for the fields/analysis they may return;
- a capability must not return data from a domain whose required scope is absent merely because another listed scope is present;
- future `any_of` or conditional scope expressions require a separately documented semantic extension and must fail closed in older implementations.

Scope presence is necessary but never sufficient. Effective permission still follows the delegated OAuth contract, capability availability, domain/resource authorization, entitlement/rollout/quota, and any other applicable policy.

## Request Contract

Every capability request must have an explicit JSON-compatible schema.

Rules:

- request fields are allowlisted;
- required vs optional fields are explicit;
- units, date/time/timezone semantics are explicit where relevant;
- enum behavior is explicit;
- identifiers use canonical Tio domain identities, not raw DB row assumptions;
- unknown fields must not silently become persistence;
- client-supplied user identity is never authentication proof;
- range/page/search inputs are bounded;
- defaults must be deterministic and documented;
- request schemas do not embed protocol-only fields such as MCP request IDs or HTTP headers.

Protocol adapters may add transport metadata outside the canonical request DTO.

## Result Contract

Every externally exposed capability result must use an explicit Tio-owned DTO/result schema.

Rules:

- result fields are allowlisted;
- minimum-necessary data is returned for the requested purpose;
- raw database rows are forbidden;
- provider payloads are normalized before exposure;
- internal audit/security metadata is excluded from ordinary results;
- secrets/tokens are never returned;
- missing/unknown data remains distinct from known zero/empty values where domain meaning requires it;
- canonical IDs and timestamps preserve their domain semantics;
- result shape must be deterministic enough for non-LLM clients to consume without parsing prose;
- human-readable summaries may accompany structured data but must not become the only machine contract.

## Read Boundedness

Read capabilities must prevent ordinary assistant queries from becoming unrestricted health/history export.

A list/history/summary capability must define applicable bounds such as:

- maximum page size;
- bounded cursor/page semantics;
- maximum time range per request;
- **maximum total lookback/coverage boundary for the capability**, enforced server-side across pagination and adjacent-window requests;
- allowed aggregate windows;
- stable ordering;
- explicit timezone/date interpretation;
- safe field projection;
- unavailable-data behavior.

The cumulative boundary is part of the capability/domain policy, not merely a per-request validation rule. A client must not reconstruct unrestricted history by paging through every cursor or issuing adjacent otherwise-valid windows. Implementations may enforce this with a fixed approved lookback horizon, a bounded coverage budget, a purpose-specific summary contract, or another server-authoritative mechanism that preserves the same no-unrestricted-export invariant.

Exact domain limits and the chosen cumulative-control mechanism belong to the owning domain contract when TNYX-247/TNYX-252/TNYX-175 define those capabilities.

Broad export is not an accidental side effect of repeated pagination. If Tio ever offers export, it requires a separately designed capability/policy.

## Pagination Contract

Capability pagination is transport-neutral.

Preferred conceptual shape:

```json
{
  "items": [],
  "page": {
    "next_cursor": "opaque-or-null",
    "has_more": false
  }
}
```

Rules:

- cursor values are opaque to clients;
- cursors must not encode secrets or unnecessary health data;
- ordering semantics are stable;
- page size is bounded server-side;
- a client cannot bypass range/export limits by supplying a large page size;
- capability cursors are not database-offset/table contracts.

A future HTTP adapter must reconcile these semantics with `API_LIFECYCLE.md` plus the detailed Backend & Platform HTTP pagination/concurrency work owned by TNYX-134. This conceptual shape is not itself an HTTP wire contract. MCP/Siri adapters map the same capability semantics without redefining them.

## Error Categories

Tio capability errors are stable semantic categories independent of protocol-specific error encoding.

Minimum read-oriented categories:

```text
invalid_request
unauthenticated
not_authorized
not_found_or_not_visible
capability_unavailable
scope_unavailable
range_not_supported
rate_limited
dependency_unavailable
temporarily_unavailable
internal_error
```

Rules:

- clients must not parse human-readable text for control flow;
- authorization/privacy may intentionally collapse not-found vs not-visible behavior;
- internal/provider/database details are sanitized;
- sensitive identifiers or payloads are not echoed;
- protocol adapters translate Tio categories into their own error shapes;
- future HTTP adapters remain subject to the global Tio HTTP error contract rather than inventing status semantics here.

## Capability Discovery

Capability discovery answers:

> What capability contract can this Tio surface support right now?

It does **not** answer:

> Is this caller authorized to read a specific user's data?

Discovery may expose safe metadata such as:

```text
capability id
semantic revision
operation class
availability
required scope families + combination semantics
supported bounded range/pagination/coverage features
adapter compatibility hints
```

Rules:

- discovery does not grant scopes;
- discovery does not bypass entitlement/rollout/domain authorization;
- discovery must not reveal user-specific health/profile facts;
- disabled/unimplemented capabilities are not silently advertised as usable;
- future `sleep.read` capabilities remain unavailable until canonical Tio sleep/recovery data exists.

MCP `server/discover` is a protocol-level server/protocol discovery mechanism. It may help an MCP client negotiate protocol features, but it is not automatically the Tio domain capability registry. An MCP adapter may translate Tio capability discovery into MCP tools/list/server metadata as appropriate.

## Compatibility and Versioning

Three version concepts are distinct:

```text
Tio capability semantic revision
adapter/public contract revision
transport/protocol revision
```

Examples:

- Tio capability revision: meaning/schema of `nutrition.summary.get`;
- HTTP/OpenAPI revision: generated route schema under a future API;
- MCP revision: e.g. protocol version `2026-07-28`.

Rules:

- MCP protocol revision is not the Tio capability version;
- DB migration revision is not the Tio capability version;
- additive compatible changes may remain within a capability revision when consumers can safely ignore them;
- breaking semantic/schema changes require an explicit migration/version path;
- adapter compatibility aliases must not fork domain behavior;
- deprecation follows the canonical API lifecycle principles: replacement, transition window/evidence, then removal.

## MCP Adapter Mapping

As of 2026-09-28, the current final MCP specification revision is `2026-07-28`.

Reference:

- https://modelcontextprotocol.io/specification/2026-07-28

That revision defines a stateless, self-contained request model with per-request capability negotiation and supports tools/resources/prompts at the protocol layer.

Tio rules:

- MCP is an adapter, not the canonical domain owner;
- MCP `tools/list`/tool definitions may expose approved Tio capability descriptors;
- MCP tool input/output JSON Schemas are generated/mapped from approved Tio capability request/result semantics, not from database tables;
- MCP tool descriptions/annotations are adapter-facing metadata and do not grant authorization;
- MCP self-reported client/server identity metadata is not a Tio authorization signal;
- MCP protocol `server/discover` and Tio capability discovery are distinct layers;
- MCP transport/session/version metadata stays out of feature/domain DTOs;
- if an MCP SDK/protocol revision changes, adapter code absorbs that change while Tio capability semantics remain stable whenever possible.

TNYX-248 owns the future ChatGPT/MCP adapter implementation/publishing work and must re-check the then-current MCP specification/SDK behavior at implementation time.

## REST/OpenAPI Adapter Mapping

Future protected HTTP routes remain governed by the existing Backend & Platform contract:

```text
TypeBox
  -> JSON Schema
  -> Fastify validation/serialization
  -> generated OpenAPI
```

TNYX-174 does not create a second OpenAPI source of truth.

A future HTTP adapter:

- maps one or more HTTP routes to stable Tio capabilities;
- uses the applicable `API_LIFECYCLE.md` rules and the detailed HTTP validation/error/pagination/concurrency contracts owned by TNYX-28/TNYX-134 when those runtime contracts are implemented;
- keeps response schemas as explicit allowlists;
- does not expose DB schema;
- does not treat route/path names as the domain capability owner.

## Siri / Apple Intelligence Adapter Mapping

A future Siri/App Intents surface maps Apple-specific intents/entities/shortcuts to the same Tio capabilities.

Apple-specific fields, phrases, intent metadata, and platform lifecycle stay in the Apple adapter. Tio domain logic, authorization, deterministic calculations, and canonical identifiers stay in their existing owners.

TNYX-237 owns that planning lane.

## Retry and Idempotency

### Read capabilities

A deterministic read may be retried when:

- it creates no user-visible/domain mutation;
- authorization is re-evaluated on each attempt;
- separately attributed operational effects such as audit events, correlation records, metrics, rate-limit counters, or security telemetry are allowed and must remain safe/idempotency-aware for repeated attempts;
- dependency/rate guidance permits retry.

Operational evidence must not be suppressed merely to classify a read as retryable. Conversely, operational side effects must not be used to smuggle domain mutation into a read capability.

Reads must not create hidden user/domain mutation merely to support connector convenience.

### Future writes

Write/action idempotency is **not** defined by this read-only slice.

Future state-changing capabilities must inherit TNYX-176 plus the canonical HTTP/async idempotency policies as applicable. An adapter must not invent its own weaker duplicate-execution semantics.

## Correlation and Audit Metadata

Capability execution should support safe correlation without placing operational metadata inside domain DTOs.

Conceptually, the execution context may carry:

```text
server-controlled request/correlation id
connector client reference
grant reference
canonical user safe reference
capability id
effective scope set
result/error category
adapter/protocol category
```

Sensitive payloads, Bearer/refresh tokens, secrets, and unnecessary health content are excluded.

Canonical logging/telemetry details remain owned by [Observability Baseline](../backend/OBSERVABILITY.md) and TNYX-177.

## Rate Limits and Timeouts

TNYX-174 records only the architectural requirement that connector traffic can be identified by client/user/capability and bounded independently.

Numeric limits, enforcement infrastructure, HTTP middleware, cost-aware limits, timeout values, and multi-instance behavior are not defined here.

Those remain owned by TNYX-29/TNYX-177 and the implementation slice that actually hosts a connector capability.

## Async / Long-Running Operations

V1 read capabilities should prefer immediate bounded results.

A future long-running capability may return a transport-neutral operation handle/result state only after a real workload proves that need.

Conceptual states may include:

```text
accepted
running
succeeded
failed
cancelled
expired
```

Rules:

- no queue/worker/job table is authorized by this document;
- operation identifiers are opaque;
- polling/cancellation semantics must be explicit when introduced;
- protocol-specific async mechanisms map to this logical boundary rather than define domain ownership;
- the current MCP ecosystem has an optional/draft Tasks extension for deferred work; a future MCP adapter may evaluate it, but Tio does not adopt or implement it merely because the extension exists;
- `services/worker` is created only when a real durable async workload independently justifies it.

## Candidate V1 Capability Classes

These remain candidates, not proof of implementation:

| Candidate | Likely owner | Scope family | Owning follow-up |
|---|---|---|---|
| profile/goals reads | Profile/account domain | `profile.read`, `goals.read` | TNYX-175 |
| nutrition summary/diary reads | Nutrition | `nutrition.read` | TNYX-175 / TNYX-252 |
| workout/training/routine/history reads | Workout | `workout.read` | TNYX-175 / TNYX-247 |
| progress/body/activity summaries | Progress / approved health owners | `progress.read` | TNYX-175 |
| sleep/recovery reads | future Recovery | `sleep.read` | only after canonical recovery contract exists |
| profile audit aggregate | purpose-built read-model owner | relevant approved read scopes | TNYX-175 |

No row grants implementation permission by itself.

## Security and Privacy Invariants

Every external capability call still requires the delegated chain defined by the OAuth/trust contracts.

A capability contract must never allow an adapter to:

- trust conversation text as authorization;
- accept another app's identity/token as Tio authorization;
- accept a client-supplied user ID as proof;
- bypass current connector grant/scope state;
- bypass resource/domain ownership;
- return broader data because a model requested it;
- expose raw service-role/database/provider credentials;
- log sensitive payloads for debugging;
- elevate capability availability into authorization.

TNYX-251 owns the expanded cross-app composition/egress policy.

## Runtime-Host Neutrality

The logical connector gateway is an architecture boundary, not a required process/folder.

A capability may later execute through:

- an approved narrow Supabase protected function when it can safely enforce the full delegated chain and domain contract; or
- future `services/api` after an approved ADR-0007 trigger.

A host migration must preserve:

```text
capability identity
request/result semantics
authorization expectations
domain owner
canonical identifiers
compatibility behavior
```

External clients must not depend on Supabase table/RPC/Edge Function internals or future Fastify module paths.

## Explicit Non-Goals

TNYX-174 Slice A does not:

- implement an MCP server/client/SDK;
- create HTTP routes or OpenAPI runtime schemas;
- create Supabase Edge Functions/tables/migrations/RLS/RPCs;
- create `services/api` or `services/worker`;
- implement any domain-specific connector tool;
- enable write/generation capabilities;
- select numeric rate limits/timeouts;
- create a public export API;
- build ChatGPT/Siri/UI/publishing integrations;
- supersede Backend & Platform HTTP lifecycle/error/pagination/observability ownership.

## Implementation Handoff

- **TNYX-247** defines bounded Workout capability DTOs/semantics.
- **TNYX-252** defines bounded Nutrition capability DTOs/semantics.
- **TNYX-175** defines purpose-built profile/health summary and audit read models.
- **TNYX-251** defines cross-app health egress/composition policy.
- **TNYX-177** defines production connector audit/rate/kill-switch controls.
- **TNYX-248** implements the future ChatGPT/MCP adapter after its complete blockers are satisfied.
- **TNYX-237** owns future Siri/App Intents adapter planning.
- **TNYX-176** owns future write action/confirmation/idempotency policy.

## Related Policy

- [Connector Trust Boundary](CONNECTOR_TRUST_BOUNDARY.md)
- [Delegated OAuth Authorization Contract](DELEGATED_OAUTH_AUTHORIZATION.md)
- [API Lifecycle & Client Compatibility](../backend/API_LIFECYCLE.md)
- [Observability Baseline](../backend/OBSERVABILITY.md)
- [Architecture](../architecture/ARCHITECTURE.md)
- [Module Ownership](../architecture/MODULE_OWNERSHIP.md)
- [ADR-0007](../adr/0007-active-supabase-and-future-services-api.md)
- [ADR-0012](../adr/0012-delegated-external-connector-trust-boundary.md)
- [ADR-0013](../adr/0013-delegated-oauth-authorization-contract.md)
- [ADR-0014](../adr/0014-vendor-neutral-connector-capability-contract.md)
