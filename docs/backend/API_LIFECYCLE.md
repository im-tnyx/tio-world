# API Lifecycle & Client Compatibility

## Status

**Canonical protected-API lifecycle policy for Tio World.**

This document defines how a future Tio protected HTTP API may evolve while independently released Flutter, Wear OS, watchOS, web, admin, partner, coach, and other clients can run different versions at the same time.

It is an architecture/documentation contract only. It does not create `services/api`, Fastify routes, OpenAPI generation, generated clients, deployment infrastructure, or runtime version gates.

It complements the accepted Flutter ↔ server contract strategy:

```text
TypeBox authoring
      ↓
JSON Schema
      ├── request validation
      ├── response serialization
      └── OpenAPI generation
              ↓
        generated clients when useful
          ├── Dart
          └── TypeScript
```

The first protected public API namespace remains `/v1` when the backend is explicitly implemented.

## Core Rules

1. **Installed clients are asynchronous.** Backend deploys must not assume every mobile/watch client updates immediately after a store release.
2. **Database schema is not the public API contract.** Tables, columns, RPC internals, Storage layout, provider payloads, and migration details may evolve without becoming client compatibility promises.
3. **Additive compatible changes may remain in the active API version.** Breaking behavior requires an explicit migration/versioning path.
4. **Responses are contracts, not database dumps.** Externally exposed structured responses use explicit schemas and must not accidentally leak new internal fields.
5. **Unsupported capability fails safely.** The server must not guess client intent, silently reinterpret incompatible payloads, or grant broader behavior because a client is old.
6. **Generated clients are reproducible artifacts.** A generated Dart/TypeScript client must be traceable to the exact OpenAPI contract used to generate it.
7. **Versioning is a compatibility tool, not a release-number mirror.** App version, API version, schema version, and feature/capability state are separate concepts.

## Version Model

### API namespace

Initial protected API namespace:

```text
/v1
```

`/v1` represents a public compatibility contract, not one application release.

A backend deployment may change many times while `/v1` remains compatible.

Do not introduce `/v2` merely because:

- the mobile app major version changes;
- the backend framework/package version changes;
- a database migration is applied;
- a new additive route or optional field is introduced;
- implementation code is reorganized.

Create a new API version only when a breaking contract cannot be safely migrated within the active version.

## Compatible Changes

A change is normally compatible when an existing supported client can continue operating correctly without code changes.

Typical compatible changes include:

- adding a new endpoint;
- adding an optional request field with a safe default;
- adding a response field when clients are generated/decoded in a forward-compatible way and the response schema still protects sensitive fields;
- adding a new optional capability;
- broadening an enum only when all supported clients safely tolerate unknown/new values;
- improving internal implementation without changing observable contract semantics;
- adding metadata that old clients can ignore safely;
- adding server-side validation that only rejects inputs already outside the documented contract.

Compatibility must be judged by actual supported-client behavior, not only by whether JSON remains syntactically valid.

## Breaking Changes

A change is breaking when an existing supported client can no longer safely interpret, send, or depend on the contract.

Examples:

- removing or renaming a field/endpoint used by supported clients;
- changing a field from optional to required;
- changing meaning, units, ownership, or authorization semantics of an existing field;
- narrowing a previously accepted input in a way that valid supported clients still send;
- changing response shape/type incompatibly;
- changing error semantics that supported clients depend on for control flow;
- repurposing an enum value;
- introducing an enum value when supported clients crash or misbehave on unknown values;
- changing pagination/cursor semantics incompatibly;
- changing idempotency/retry behavior in a way that can duplicate or lose user actions;
- changing authentication/authorization requirements without a migration path for supported clients.

A breaking database migration is not automatically a breaking API change, and a breaking API change does not require exposing database changes.

## Deprecation & Removal Process

Do not remove supported API behavior in one deploy just because a new client exists.

Required sequence:

```text
1. identify deprecated contract
2. identify supported clients/consumers
3. provide replacement or migration path
4. mark/document deprecation
5. instrument privacy-safe usage if needed
6. release compatible client migration
7. allow adoption window appropriate to the client surface
8. verify old usage is below the accepted removal threshold
9. remove only with explicit compatibility evidence
```

For store-distributed mobile/watch clients, the adoption window must account for:

- users who delay updates;
- staged store rollout;
- store review/release delay;
- temporarily offline devices;
- supported older app releases.

Do not use a fixed universal number of days in architecture policy. The owning release/product task records the actual deprecation window and removal evidence.

## Supported Client Policy

Tio should distinguish:

```text
latest available client
minimum supported client
unsupported client
```

A minimum supported client version is introduced only when operationally needed, for example:

- a security fix makes an old client unsafe;
- an unavoidable breaking server contract is approved;
- a platform/provider dependency no longer supports the old behavior;
- a critical data-integrity fix requires the new client.

Do not introduce a minimum-version gate merely for convenience.

When a minimum supported version is enforced, define:

- affected platform/surface;
- minimum version/build;
- reason;
- effective time/rollout;
- whether the block is hard or soft;
- safe user-facing upgrade behavior;
- offline behavior;
- rollback/emergency override;
- telemetry that does not expose sensitive payloads.

## Unsupported Client Behavior

Unsupported clients must fail safely and predictably.

Preferred server behavior:

- explicit status/error contract;
- no partial mutation before compatibility rejection where practical;
- no fallback to privileged or legacy behavior merely to make the request succeed;
- no silent reinterpretation of units/fields/intent;
- no raw stack traces/internal schema/provider payloads;
- clear distinction between authentication failure, authorization failure, validation failure, unsupported capability, and server failure.

The client should be able to show a controlled action such as update/retry/feature unavailable rather than entering an infinite retry or refresh loop.

## App Version vs API Version

These versions are independent:

```text
Flutter app version/build
Wear/watch app version/build
API namespace (/v1)
OpenAPI contract revision
Database migration head
feature/capability state
```

Do not infer one from another.

For example, app `3.x` may still consume `/v1`, and `/v1` may have many compatible OpenAPI revisions over time.

## Capability Negotiation

Client-version checks are intentionally coarse.

When a feature requires more precise compatibility, prefer explicit capability negotiation rather than hardcoding many app-version branches.

Possible future pattern:

```json
{
  "capabilities": {
    "progress_photo_upload": true,
    "coach_streaming_v2": false
  }
}
```

Exact route/shape is not selected by this policy.

Capability rules:

- capabilities describe supported behavior, not authorization;
- authorization, billing, entitlement, quota, and safety checks remain server-enforced separately;
- missing/malformed/stale capability information fails to a safe default;
- capability names should be stable semantic contracts, not UI widget names;
- do not expose sensitive targeting inputs in capability payloads;
- remove old capability flags after their compatibility purpose ends.

## Feature Flags vs API Compatibility

Feature flags and API versions solve different problems.

```text
API lifecycle
→ can this client safely speak this contract?

feature/capability rollout
→ should this approved capability be available now for this context?
```

A feature flag must not be used to hide an otherwise breaking public contract indefinitely.

## Request Compatibility

Every externally exposed request contract should define:

- method/path;
- auth requirement;
- params/query/body schema;
- required vs optional fields;
- units and normalization rules;
- enum behavior;
- idempotency/retry semantics where mutation can be repeated;
- client-safe validation errors.

Unknown/extra fields must follow the locked schema strategy rather than being accepted accidentally.

Do not add permissive catch-all request payloads to avoid versioning work.

## Response Compatibility

Response schemas are an allowlist.

Rules:

- do not serialize raw database rows as the public contract;
- adding a database column must not automatically add an API field;
- internal/admin/provider fields stay excluded unless explicitly approved;
- nullable/optional semantics must remain stable for supported clients;
- units/timezone/time semantics must be documented where ambiguity can corrupt interpretation;
- lists/pagination/cursors need stable semantics;
- error bodies need stable machine-readable codes when clients branch on them.

## Enum Evolution

Enums are a common mobile compatibility hazard.

Before adding a new enum value inside the same API version, verify supported clients can safely handle unknown values.

If they cannot, use one of:

- update supported clients before emitting the value;
- gate emission behind capability/version evidence;
- model the field differently for forward compatibility;
- introduce a versioned contract when necessary.

Never repurpose an existing enum value to mean something different.

## Generated Dart & TypeScript Clients

Generation is optional until it demonstrably reduces drift, but once a generated artifact is used it must be reproducible.

Required traceability metadata should identify at least:

```text
OpenAPI contract revision/content hash
API namespace
code-generator name/version
relevant generator configuration/version
source repository commit when generated
```

Generated files must not be manually edited in ways that cannot be reproduced.

A build/release must be able to answer:

```text
Which OpenAPI contract produced this client?
```

If generation is not yet used, manually maintained repository/DTO models remain acceptable behind the same API contract.

## OpenAPI Contract Ownership

Accepted direction remains:

```text
TypeBox route/schema authoring
→ JSON Schema
→ Fastify validation/serialization
→ generated OpenAPI
```

OpenAPI must not become a separately hand-edited competing source of truth.

Documentation examples may illustrate the contract but do not override the generated runtime schema.

When backend implementation is authorized, CI should eventually verify that generated OpenAPI/client artifacts are reproducible and not drifting from the route/schema source.

## Database & Migration Independence

Public API compatibility must be insulated from database evolution.

Preferred pattern:

```text
DB expand
→ server supports old + new representation
→ clients migrate over time
→ server observes compatibility window
→ DB contract/removal only after old dependency is retired
```

This aligns with the database expand/migrate/contract policy.

Do not:

- rename API fields merely because a database column was renamed;
- expose migration version numbers as client behavior contracts;
- require all installed clients to update in the same window as a database migration;
- remove a DB column while a supported server/client compatibility path still requires it.

## Authentication & Authorization Compatibility

Auth changes require extra caution.

A valid old client must never receive broader authorization to preserve compatibility.

If stronger auth/security becomes mandatory:

- fail closed;
- provide a controlled migration/update flow;
- keep authentication and resource authorization distinct;
- do not accept client-supplied `user_id`, Email, Phone, provider identity, or metadata as a substitute for verified server identity;
- do not preserve an insecure legacy route solely because old clients call it.

Security can justify forcing a minimum client version, but that decision must be explicit and documented.

## Error Contract Lifecycle

Client-facing errors used for branching should have stable machine-readable codes.

Compatible evolution may add new codes only when existing clients have a safe generic fallback.

Do not make clients parse human-readable error strings for business control flow.

Sensitive/internal details remain server-side regardless of version.

## Mixed-Version Acceptance

Before shipping a compatibility-sensitive backend change, test at least:

- latest supported client against new server;
- oldest supported client against new server for affected routes;
- new client against currently deployed server when staged rollout can create that combination;
- unsupported-client rejection path when applicable;
- retries/idempotency for mutations;
- auth/authorization behavior;
- unknown enum/field behavior where relevant.

Exact matrices belong to implementation/release tasks, not this policy doc.

## Emergency Changes

Emergency security/data-integrity changes may shorten normal deprecation windows.

They still require an explicit record of:

- risk being mitigated;
- affected clients;
- minimum safe version/capability;
- server behavior for old clients;
- user-facing recovery/update path;
- rollback/kill-switch option when available.

Emergency does not mean silently breaking clients without a defined failure mode.

## Implementation Gate

This policy does **not** authorize backend implementation.

Until a separately approved backend slice starts:

- no `services/api` or Fastify scaffold is created;
- no `/v1` runtime endpoint is created;
- no OpenAPI generator/package is installed;
- no Dart/TypeScript API client is generated;
- no app minimum-version enforcement is enabled;
- no remote capability endpoint is created;
- no production configuration changes are made.

## Acceptance for TNYX-50

- [x] `/v1` lifecycle rules are explicit.
- [x] Compatible vs breaking changes are defined by supported-client behavior.
- [x] Deprecation/removal requires replacement, adoption window, and evidence.
- [x] Backend deploys do not assume immediate mobile/watch store adoption.
- [x] Minimum supported client behavior is defined without prematurely enabling a gate.
- [x] Unsupported clients/capabilities fail safely.
- [x] Capability negotiation is separated from API versioning and authorization.
- [x] Generated Dart/TypeScript clients must be reproducible and traceable to an exact OpenAPI contract.
- [x] TypeBox → JSON Schema → OpenAPI remains the canonical contract strategy.
- [x] Database schema/migration lifecycle is explicitly separate from public API compatibility.
- [x] No backend/runtime implementation is introduced by this documentation slice.
