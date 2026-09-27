# Supabase Architecture & Rules

Document Status: Canonical Live Doc
Last Verified: 2026-09-27
Owner: repository AI governance
Truth Boundary: AI execution guardrails for the active Supabase boundary and preserved future HTTP adapters; canonical data/security docs, migrations, verified live metadata, and runtime source remain authoritative.

## Active Production Foundation (Supabase-First)

Tio-World uses Supabase as its active data, authentication, and storage platform.

- **Auth:** Supabase Auth (`GoTrue`) with direct token management and stream observation.
- **Database:** Supabase PostgreSQL is active. The verified readable inventory currently covers 14 `public` tables with RLS enabled; use `docs/data/SUPABASE_SCHEMA.md` for the current structure and treat migrations + verified live metadata as executable truth.
- **Storage:** The current `avatars` bucket is a documented public exception with owner/path controls. Do not generalize that exception to future sensitive module media; follow canonical Storage/privacy policy for each approved slice.

## Future-Safe HTTP Adapter Preservation Rule

Tio-World currently uses **Supabase as the active production data boundary**, while the repository also preserves **future HTTP/remote adapter abstractions**. Their presence is not evidence that `services/api` has been implemented.

The following code is intentional architecture and MUST NOT be deleted, merged away, replaced, or classified as dead/unused code merely because it is not active in the current Supabase production composition:

* `ApiClient`
* `DioApiClient`
* `AuthTokenProvider`
* `RemoteProfileSetupRepository`
* `ProfileSetupDtoMapper`
* `RemoteOnboardingFinalizer`
* `BackendUserSyncRepository`
* `RemoteBackendUserSyncRepository`
* `GoogleAuthUseCase` (fail-closed legacy Firebase compatibility path; not the production Supabase auth path)
* backend transport DTOs and mappers

### Current vs Future Adapter Rule

Current production path:
```text
Flutter → existing repository contracts → Supabase adapters → Supabase Auth + Postgres/RLS
```

Future protected-service path:
```text
Flutter → SAME repository contracts → Remote*/HTTP adapters → future `services/api` when separately authorized
```

A model, coding agent, cleanup task, dead-code audit, refactor, or architecture migration MUST NOT delete inactive Remote*/HTTP adapter infrastructure solely because Supabase is the current production adapter.

Inactive != obsolete.

Removal requires:
1. architecture audit,
2. explicit retirement decision,
3. explicit user approval.
