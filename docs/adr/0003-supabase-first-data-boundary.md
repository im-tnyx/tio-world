# ADR-0003: Supabase-First Data Boundary

- **Status:** Superseded by [ADR-0007](0007-active-supabase-and-future-services-api.md)
- **Date:** 2026-08-11

## Context

Tio needs authenticated user data, private media, and future AI capabilities. Building a custom authentication and database service before a real product slice would add operational work without proving the required boundary. At the same time, health, nutrition, workout, progress, and profile data require explicit ownership and access control.

## Decision

- Use Supabase as the planned first foundation for Auth, Postgres user data protected by Row Level Security (RLS), private Storage, migrations, and approved server functions.
- Keep Flutter and Wear integrations behind feature-owned repository contracts using only client-safe configuration.
- Create the root `supabase/` workspace only when the first authenticated vertical slice is approved.
- Reserve the separate `backend/` workspace for a later protected-service upgrade: Gemini/provider orchestration, complex integrations, long-running jobs, or needs that Supabase functions no longer cover.
- Keep structured records in Postgres. Private module Storage buckets are for approved user media only and require concrete file rules plus owner-specific policies before provision.

## Consequences

### Positive

- The initial data foundation is small and aligned with the first product slice.
- User data access has an explicit RLS and repository boundary.
- Gemini credentials, privileged joins, and service-role operations remain off mobile and Wear clients.

### Constraints

- Sign-in methods and the first authenticated feature still need explicit approval.
- `AppMode` is device-local for its first slice; account sync remains deferred until an approved Supabase profile contract exists.
- Do not create a full schema, generic migration set, bucket, backend framework, or client dependency in advance.
- There is no live Supabase project, configuration, migration, bucket, credential, or Gemini integration in this repository today.
- `backend/db` is not an owner for Supabase migrations or RLS.

## Supersession note

This ADR is preserved as the historical 2026-08-11 decision record. Its Supabase-first principle led to the active Supabase foundation, but later accepted architecture decisions changed the repository/server shape materially:

- `supabase/` is now active rather than future-only;
- the protected server namespace is `services/`, not `backend/`;
- the first protected API path is `services/api`;
- Node.js + TypeScript + Fastify is the locked initial backend baseline;
- Supabase Auth is the canonical identity authority for the future Tio API.

Do not rewrite the historical Context/Decision above as current-state prose. Use [ADR-0007](0007-active-supabase-and-future-services-api.md) and the canonical architecture docs for current direction.

## Related

- [ADR-0007: Active Supabase and Future `services/api`](0007-active-supabase-and-future-services-api.md)
- [Architecture](../ARCHITECTURE.md)
- [Auth Architecture](../AUTH_ARCHITECTURE.md)
- [Supabase-First Platform Strategy](../SUPABASE_STRATEGY.md)
- [Data and Sync](../DATA_AND_SYNC.md)
- [Security](../SECURITY.md)
- [Supabase foundation task](../../.ai/tasks/supabase-foundation.md)
