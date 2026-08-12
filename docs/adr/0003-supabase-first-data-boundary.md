# ADR-0003: Supabase-First Data Boundary

- **Status:** Accepted
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

## Related

- [Supabase-First Platform Strategy](../SUPABASE_STRATEGY.md)
- [Data and Sync](../DATA_AND_SYNC.md)
- [Security](../SECURITY.md)
- [Supabase foundation task](../../.ai/tasks/supabase-foundation.md)
