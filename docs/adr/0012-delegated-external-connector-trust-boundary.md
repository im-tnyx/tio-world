# ADR-0012: Delegated external connector trust boundary

Document Status: Architecture Decision Record
Last Verified: 2026-09-28
Owner: Connector Architecture + Security & Identity
Truth Boundary: Authoritative for the durable delegated external-connector identity/trust boundary and runtime-neutral capability boundary; not proof that OAuth, grants, connector tools, or a connector runtime are implemented.

- **Status:** Accepted
- **Date:** 2026-09-28

## Context

Tio plans to let ChatGPT-style agents and future third-party clients access approved user-owned capabilities. Existing first-party phone/watch authentication is based on Supabase Auth sessions and Supabase access tokens, but an external connector must not receive a user's Supabase session, privileged database credential, or persistence-level contract.

The connector boundary is security-sensitive because it must preserve Tio's canonical user identity, consent/grant semantics, least privilege, domain authorization, health-data minimization, and future host portability. ADR-0007 already keeps Supabase active/current and permits future `services/api` only when a concrete protected-server need justifies it.

## Decision

External connector clients use a **Tio-controlled delegated connector credential**, not a Supabase user session, as their external authentication credential.

A connector request must resolve this authorization chain before a Tio capability is allowed:

```text
validated connector credential
  -> connector client
  -> user-owned connector grant
  -> canonical Tio user identity
  -> effective scopes
  -> Tio domain/resource authorization
  -> bounded Tio capability
```

Supabase Auth remains the canonical Tio identity authority. Delegated connector credentials do not create a second Tio identity model; connector grants resolve to the canonical Tio user UUID.

The first connector release is read-only. External contracts expose task-oriented Tio capabilities, never raw tables, raw SQL, generic database RPCs, Supabase `service_role`/secret credentials, or provider-specific persistence contracts.

The public connector/tool contract is runtime-neutral. An approved narrow Supabase server function may host a bounded connector capability when it can safely enforce connector credential -> client -> grant -> canonical user -> scope/domain authorization. Future `services/api` is used only when an approved slice proves an ADR-0007 trigger such as broader shared protected authorization/orchestration, server-only integration complexity, operational isolation, or long-running/async execution.

Exact OAuth endpoints, token format/lifecycle, client registration, grant/token persistence, and write-action policy remain owned by their separately approved follow-up issues.

## Alternatives

### Require external connectors to use a Supabase user session

Rejected. It would couple external clients to first-party session semantics, expose an implementation-specific authentication boundary, and weaken explicit connector-client/grant/scope separation.

### Expose Supabase tables/RLS directly as the connector API

Rejected. Persistence access is not a task-oriented Tio capability contract and cannot safely replace connector client, consent/grant, scope, purpose, and domain-authorization checks.

### Scaffold `services/api` immediately for connectors

Rejected. ADR-0007 requires a concrete approved protected-server trigger; repository symmetry or future intent is not sufficient.

## Consequences

### Positive

- First-party Supabase-session authentication and external delegated authentication are explicit, non-conflicting contracts.
- Supabase Auth remains the single canonical Tio user identity authority.
- Connector clients receive only stable Tio capability contracts rather than storage/runtime details.
- A Supabase-first bounded implementation can migrate to `services/api` without changing domain ownership or public connector semantics.
- Read-only V1 limits the initial external mutation and confirmation risk.

### Constraints / Trade-offs

- Tio must implement and operate explicit connector client, grant, scope, revocation, and audit semantics before a production pilot.
- Every connector capability still requires domain-level ownership/authorization and minimum-necessary response shaping after credential validation.
- A production provider/client that receives Personal, Sensitive, or Health-context data requires the provider-specific privacy review defined by `DATA_PRIVACY_GOVERNANCE.md`.
- If narrow Supabase functions stop being an appropriate host, migration to `services/api` becomes an explicitly approved implementation task rather than an invisible refactor.
- Write capabilities require a later approved policy and implementation slice; this ADR does not authorize them.

## Links

- Linear issue: https://linear.app/tnyx/issue/TNYX-172/c00-audit-external-agentconnector-platform-requirements-and-threat
- Canonical connector policy: [Connector Trust Boundary and V1 Exposure Policy](../integrations/CONNECTOR_TRUST_BOUNDARY.md)
- Authentication architecture: [Authentication Architecture](../security/AUTH_ARCHITECTURE.md)
- Supabase/future-service boundary: [ADR-0007](0007-active-supabase-and-future-services-api.md)
- Data/privacy policy: [Data & Privacy Governance](../security/DATA_PRIVACY_GOVERNANCE.md)
- Review PR: https://github.com/im-tnyx/tio-world/pull/453
