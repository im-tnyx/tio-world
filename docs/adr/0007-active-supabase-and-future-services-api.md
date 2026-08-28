# ADR-0007: Active Supabase and Future `services/api` Boundary

- **Status:** Accepted
- **Date:** 2026-08-28

## Context

ADR-0003 established a Supabase-first direction before the repository had a live Supabase workspace. That direction is now implemented: `supabase/` is active and owns the current Auth/data/migration boundary.

Subsequent accepted B0 architecture decisions also locked a different protected-server shape than ADR-0003 originally anticipated:

- `services/` is the canonical runnable server namespace;
- `services/api` is the first protected server application path;
- Node.js + TypeScript + Fastify is the initial runtime/framework baseline;
- the server starts as a modular monolith;
- `supabase/migrations/` remains the sole database-schema/RLS migration owner;
- backend implementation is still deferred and must not start merely because the architecture is documented.

Auth architecture has also converged on Supabase Auth as the canonical identity authority. Firebase Admin token verification is not part of the target Tio API auth flow.

## Decision

### Current foundation

Supabase remains the current source of truth for the first platform boundary:

```text
Flutter / Wear clients
→ Supabase Auth
→ Supabase Postgres + RLS
→ approved Storage / Edge Function paths where required
```

`supabase/` is active. It owns migrations, RLS/policies, approved functions, and Supabase project configuration.

### Future protected API

When a protected backend slice is explicitly approved, its canonical path is:

```text
services/api/
```

Its initial architecture is:

```text
Node.js
+ TypeScript
+ Fastify
+ modular monolith
```

The future auth flow is:

```text
Supabase Auth
→ access token
→ services/api
→ verify Supabase token
→ derive verified user identity
→ authorize operation
```

### Database ownership

`services/api` does not become a parallel database migration owner. Tio schema/RLS changes remain under:

```text
supabase/migrations/
```

Trusted server workflows may use privileged Supabase access only under the canonical server-access policy; privilege must not be used as an automatic retry after RLS denial.

### When backend implementation may start

Creating this ADR does **not** authorize backend code.

Start `services/api` only after an explicitly approved implementation slice requires a protected server boundary and the user/project owner authorizes execution.

Typical valid triggers include a concrete need for one or more of:

- server-only provider/API credentials that cannot safely live in clients;
- trusted orchestration across providers/integrations;
- privileged operations that are intentionally outside ordinary user-scoped RLS access;
- protected API contracts that must be enforced consistently across clients;
- long-running or asynchronous workflows whose execution no longer belongs in a client or narrow Supabase function.

The following are **not** sufficient triggers by themselves:

- the existence of `services/api` in architecture docs;
- a desire for folder symmetry;
- speculative scale concerns;
- an unused Remote*/HTTP adapter in Flutter;
- a future AI/billing/integration idea with no approved implementation slice.

### Future worker

`services/worker` is reserved conceptually but is created only when a real asynchronous workload, queue contract, deployment boundary, or failure-isolation need justifies it.

## Alternatives

### Keep the old `backend/` namespace

Rejected because accepted B0 decisions established `services/` as the canonical runnable-server namespace and `services/api` as the first protected API path. Keeping both names would create competing architecture sources.

### Keep backend framework undecided

Rejected because TypeScript + Fastify is already an accepted B0 decision. The implementation remains framework-light at domain boundaries, but the initial HTTP runtime is no longer undecided.

### Move database ownership into `services/api`

Rejected. Supabase migrations/RLS already have a canonical owner and duplicating schema ownership would create drift and unsafe deployment ordering.

### Build the backend immediately

Rejected. Current product work can continue on the active Supabase foundation. Protected server code starts only for an approved concrete need, not to satisfy architecture completeness.

## Consequences

### Positive

- Current repository documentation matches the live Supabase foundation.
- Future agents have one canonical protected API path: `services/api`.
- Fastify is explicit without forcing backend implementation now.
- Supabase Auth remains the single identity authority across current client flows and future API verification.
- Database migration ownership stays unambiguous.
- Generic future HTTP adapters can be evaluated against a concrete target rather than an undefined custom backend.

### Constraints / Trade-offs

- Existing historical docs/code may still contain `backend/` or Firebase terminology and require bounded cleanup when encountered.
- `services/api` must remain unimplemented until an explicitly authorized backend slice starts.
- The modular monolith may later evolve only when runtime, scale, deployment, ownership, or failure-isolation evidence justifies a change.
- Queue, Redis/cache, multi-region, sharding, Kubernetes, and extra services are not selected by this ADR.

## Links

- Supersedes: [ADR-0003](0003-supabase-first-data-boundary.md)
- [Architecture](../ARCHITECTURE.md)
- [Auth Architecture](../AUTH_ARCHITECTURE.md)
- [Supabase Strategy](../SUPABASE_STRATEGY.md)
- [Supabase Server Access](../SUPABASE_SERVER_ACCESS.md)
- Linear TNYX-17 — monorepo/services namespace
- Linear TNYX-18 — TypeScript + Fastify baseline
- Linear TNYX-21 — Firebase auth architecture cleanup
- Linear TNYX-26 — future `services/api` scaffold contract; implementation not started
- Linear TNYX-41 — `services/api` internal folder architecture
