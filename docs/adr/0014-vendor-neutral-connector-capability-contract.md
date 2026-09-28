# ADR-0014: Vendor-neutral connector capability contract

Document Status: Architecture Decision Record
Last Verified: 2026-09-28
Owner: Connector Architecture + Application/Domain Architecture
Truth Boundary: Authoritative for the durable connector capability/adaptor ownership decision; not proof that an MCP server, HTTP API route, domain connector tool, or connector runtime exists.

- **Status:** Accepted
- **Date:** 2026-09-28

## Context

ADR-0012 established the delegated external-connector trust boundary and ADR-0013 established delegated OAuth client/grant/scope semantics.

TNYX-174 must now define the public application-capability boundary before Workout, Nutrition, profile/health read contracts and external adapters are implemented.

The design must avoid:

- making MCP or another external protocol the canonical owner of Tio domain semantics;
- exposing database tables/RPCs/provider payloads as connector contracts;
- duplicating Workout/Nutrition/Profile business logic in adapters;
- coupling public capability names to a Supabase Edge Function or future Fastify route;
- creating a second HTTP/OpenAPI lifecycle/error/pagination policy;
- scaffolding backend/runtime infrastructure merely to document the contract.

MCP is an evolving external protocol. As of 2026-09-28 its current final specification revision is `2026-07-28`, with a modern stateless per-request lifecycle. Tio must be able to adopt protocol revisions without rewriting its domain capability model.

## Decision

Tio defines a **vendor-neutral capability contract** between delegated authorization and protocol/ecosystem adapters.

The durable boundary is:

```text
external host/client
  -> thin protocol/ecosystem adapter
  -> stable Tio capability identity + typed request/result
  -> capability availability
  -> delegated authorization context where external
  -> Tio domain/resource authorization
  -> feature-owned application/domain operation
  -> approved execution adapter
  -> canonical Tio data
```

A Tio capability has a stable semantic identity owned by Tio, independent of:

- MCP tool/method names;
- HTTP route/path names;
- Siri/App Intent names;
- provider or AI-vendor names;
- database table/column/RPC names;
- Supabase Edge Function names;
- future `services/api` module paths.

Capability contracts use explicit JSON-compatible request/result schemas and must define the applicable owner, complete required scope-family set plus combination semantics, boundedness/privacy rules, error categories, compatibility semantics, availability, and correlation expectations. Canonical capability IDs follow a Tio-owned lowercase dot-separated semantic convention; existing `get_*` names in Linear remain candidate adapter/tool names unless a domain follow-up explicitly adopts them.

The first connector capability set remains read-only. V1 capability descriptors model required scopes as a collection with `all_of` semantics by default, so aggregate capabilities cannot authorize multi-domain data from a single domain scope.

Capability discovery describes supported/available behavior. It is not authorization, entitlement, consent, or proof that a specific user's resource may be read.

MCP, future REST/OpenAPI, Siri/App Intents, ChatGPT-specific publishing metadata, and future external ecosystems are adapters over the same capability semantics.

The MCP adapter may map approved Tio capabilities into MCP tools/resources and current JSON Schema forms, but MCP protocol revision/transport/session metadata never becomes domain data or the canonical capability version.

Future HTTP routes remain governed by the existing Backend & Platform contract:

```text
TypeBox
  -> JSON Schema
  -> Fastify validation/serialization
  -> generated OpenAPI
```

TNYX-174 does not create a competing OpenAPI/schema source of truth.

Global HTTP validation/errors, rate limits/timeouts/logging, and HTTP pagination/mutation/concurrency remain owned by their Backend & Platform policies/tasks (including TNYX-28, TNYX-29 and TNYX-134). TNYX capability contracts define transport-neutral domain semantics; future adapters map those semantics into the then-current implemented transport policy.

Read list/history capabilities must be bounded by server-enforced pagination/range/field rules **and** a server-authoritative cumulative lookback/coverage control so repeated pages or adjacent valid windows cannot reconstruct unrestricted health history. Raw/unrestricted health-history export is not implied by ordinary pagination.

Retryable reads may still create separately attributed operational audit/correlation/metrics/rate-limit records; read classification prohibits user-visible/domain mutation, not required operational evidence.

Long-running operations remain conceptual until a real capability proves the need. The current optional/draft MCP Tasks extension, queues, workers, or job persistence are not adopted by this ADR.

The logical connector gateway is an architecture boundary, not a required service/process. A later implementation may execute an approved capability through a narrow Supabase protected function or future `services/api` only under the existing ADR-0007 trigger rules.

## Alternatives

### Make MCP tool schemas the canonical Tio capability model

Rejected. MCP is an external protocol whose revisions, lifecycle, metadata, and SDK conventions can change independently of Tio domain ownership.

### Make future HTTP/OpenAPI routes the canonical capability identity

Rejected. HTTP is one transport surface. Siri/App Intents, MCP and in-product orchestration must be able to reuse the same application capability semantics.

### Expose generic database CRUD/RPC tools

Rejected. This leaks persistence shape, weakens purpose limitation, and bypasses feature-owned domain authorization/business rules.

### Create one generic health-data export capability

Rejected. It encourages over-broad data retrieval and conflicts with minimum-necessary, purpose-bounded read contracts.

### Scaffold an MCP server or services/api now

Rejected. TNYX-174 is a contract freeze; no concrete runtime workload in this slice justifies backend/process/package creation.

### Re-define HTTP error/pagination/rate-limit policy inside Connector

Rejected. Existing Backend & Platform owners already govern those concerns; duplicating them would create conflicting sources of truth.

## Consequences

### Positive

- Workout, Nutrition, Profile/Progress and future Recovery can own reusable capability semantics once.
- MCP/ChatGPT, Siri, future HTTP/web and other adapters can remain thin.
- Tio can update MCP protocol revisions without renaming/re-owning domain capabilities.
- Supabase-to-`services/api` migration can preserve public connector semantics.
- DB/provider internals stay behind application/domain boundaries.
- Downstream TNYX-247/TNYX-252/TNYX-175 can define domain schemas against one shared contract.

### Constraints / Trade-offs

- Adapters require explicit translation instead of exposing persistence models directly.
- Domain-specific capability names/DTOs still require their owning follow-up issues; this ADR does not finalize them.
- Future HTTP implementations must reconcile capability semantics with the canonical Backend HTTP contract rather than treating either layer as optional.
- Protocol-specific discovery/error/async features may not map one-to-one and require adapter logic.
- Production rate limits, audit controls, cross-app egress rules and write safety remain separate gates.

## Links

- Linear: https://linear.app/tnyx/issue/TNYX-174/c10-define-vendor-neutral-connector-gateway-and-mcp-style-tool
- Canonical capability policy: [Connector Capability Contract](../integrations/CONNECTOR_CAPABILITY_CONTRACT.md)
- Parent trust boundary: [ADR-0012](0012-delegated-external-connector-trust-boundary.md)
- Delegated authorization: [ADR-0013](0013-delegated-oauth-authorization-contract.md)
- Runtime host boundary: [ADR-0007](0007-active-supabase-and-future-services-api.md)
- API lifecycle: [API Lifecycle & Client Compatibility](../backend/API_LIFECYCLE.md)
- MCP current specification reference: https://modelcontextprotocol.io/specification/2026-07-28
