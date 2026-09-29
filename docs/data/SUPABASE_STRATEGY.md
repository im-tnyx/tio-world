# Supabase-First Platform Strategy

Document Status: Canonical Live Doc
Last Verified: 2026-09-29
Owner: Supabase data ownership + Backend & Platform
Truth Boundary: Authoritative for current Supabase ownership and future protected-service boundaries; runtime source and verified live schema prove actual implementation.

## Status

**Active current Supabase foundation.**
- The root `supabase/` workspace is the current schema/migration owner and contains the checked-in migration history.
- On 2026-09-29, the 50 applied live migrations match the first 50 checked-in migrations by version + name after reconciling the already-applied Workout Program migration to its hosted identity `20260929040034_create_user_workout_programs`. One newer repository migration, `20260929050000_create_user_workout_routines`, remains intentionally unapplied live.
- The canonical readable current `public` schema inventory is [`SUPABASE_SCHEMA.md`](SUPABASE_SCHEMA.md): 15 ordinary live tables, with RLS enabled on all 15 at the verified snapshot. `user_workout_programs` is live; `user_workout_routines` is not live yet.
- Flutter startup initializes configured Supabase through `SupabaseRuntimeConfig` and `initializeSupabaseRuntime`; current feature persistence/auth integrations use feature-owned Supabase repositories behind composition/provider boundaries.
- Future HTTP/backend adapters remain architecture-preserved only where current source still contains them; future `services/api` remains unimplemented until a separately authorized protected-service slice.

## Decision

Supabase is the active foundation for authenticated user data and the current production boundary for user identity and Tio-owned application data. Future protected services extend this boundary only when a separately approved server-side need exceeds the appropriate Supabase function path.

| Responsibility | Current owner / direction |
| :--- | :--- |
| Authentication and sessions | Supabase Auth |
| User-owned application data | Supabase Postgres with explicit Row Level Security (RLS) |
| User media or documents, when a real slice needs them | Supabase Storage with explicit access policies |
| Schema migrations, RLS policies, seed data, and database functions | active root `supabase/` workspace |
| Flutter/Wear client integration | Feature repositories behind client-safe Supabase contracts |
| Gemini API and other privileged third-party calls | approved Supabase server functions today where implemented; future `services/api` when a separately approved protected-service slice requires it |
| Delegated external connector execution | approved narrow Supabase protected function when the full connector credential/client/grant/canonical-user/scope/domain-authorization chain can be enforced safely; future `services/api` when an approved ADR-0007 trigger is proven |
| Long-running jobs or complex orchestration | future `services/api`, with `services/worker` added only for a real asynchronous/background workload |

Supabase is the data/auth platform; it does not make client code privileged. RLS and feature-level repository boundaries remain required.

## Storage Boundary And Module Buckets

Supabase Storage holds user-owned files only. Structured profile, nutrition, workout, and progress records stay in Supabase Postgres behind feature repositories and RLS; they do not become JSON files in a bucket.

Current Storage has one explicit Profile-media exception: the checked-in migration provisions a public `avatars` bucket. `SupabaseProfileAvatarRepository` uploads objects under the authenticated user's first path segment, writes the resulting public URL to `public.users.avatar_url`, and restricts authenticated insert/update/delete policies to the user's owned folder. Public reads are allowed by the current bucket policy.

That public `avatars` bucket is existing implementation truth, not the default pattern for future health/fitness media. A move to private Profile media/signing requires a separately approved migration and repository/client transition.

Future module buckets are private by default and are provisioned only when their first real file use case is approved:

| Future private bucket | Owner | Allowed file purpose | Explicit non-purpose |
| :--- | :--- | :--- | :--- |
| `profile` | Profile | Possible future private replacement/additional Profile media only after an approved migration away from or alongside the current public `avatars` contract | Profile fields, Auth data, or arbitrary document backup |
| `nutrition` | Nutrition | Optional user meal/food images when the diary slice approves them | Meal diary records, food search database, or Meal Plan data |
| `workout` | Workout | Approved user workout attachments only when a concrete feature needs them | The bundled Exercise Search JSON catalog, routine/program records, or sensor streams |
| `progress` | Progress | User progress photos | Weight, measurement, achievement, or trend records |

Each user-owned object must use an ownership-safe path rooted in the authenticated user ID, for example `<user-id>/<object-id>`. Storage policies must enforce that the caller can access only their own object path. Do not introduce new public buckets or public URLs for health/fitness media by default. The existing public `avatars` bucket is a documented exception; new sensitive-media designs should use an authorised retrieval flow with bounded access unless an explicit review approves otherwise.

Before a bucket is created, its feature task must define allowed MIME types, size limit, image-processing policy, object naming, metadata, overwrite/delete rules, retention, offline upload state, and owner-specific Storage RLS policies. If replacement uploads are supported, the policy design must cover the full required read/write operation rather than only initial upload.

## Target Repository Shape

```text
tio-world/
├─ apps/                 # Flutter phone, Wear OS, core, shared, feature packages
├─ supabase/             # ACTIVE: config, migrations, policies, tests, approved functions
├─ services/             # Future only; do not scaffold before an approved need
│  ├─ api/               # Future protected service application
│  └─ worker/            # Future only for real async/background processing
├─ docs/
└─ .ai/
```

`supabase/` is the active owner for Supabase schema/migrations and related platform assets. Do not introduce a parallel `backend/*` namespace. Future protected service implementation belongs under `services/api`, with `services/worker` reserved for an approved asynchronous workload; neither future service path should be scaffolded speculatively.

## Client And Security Boundary

- Flutter and Wear OS can use only a client-safe Supabase URL and publishable key through untracked environment/config injection.
- Never place a Supabase secret/service-role key, Gemini API key, private key, privileged RPC credential, or admin operation in a mobile/watch client.
- Every client-accessible table, view, storage bucket, and function needs an explicit access design. Enable RLS for exposed tables and write ownership-specific policies; authentication alone is not authorization.
- Do not base authorization on user-editable metadata. Feature data access stays behind repository contracts rather than being called directly from widgets.
- Sensitive health, nutrition, workout, recovery, and profile data require the minimum collection, clear user intent, and safe logs.
- External connector credentials are not Supabase user sessions. Connector access must resolve a Tio-controlled client + user-owned grant + canonical user + effective scopes before domain authorization, as defined by [Connector Trust Boundary](../integrations/CONNECTOR_TRUST_BOUNDARY.md) and [ADR-0012](../adr/0012-delegated-external-connector-trust-boundary.md).

## Gemini Boundary

Gemini is a server-side provider option and must never be a client dependency. Existing or future approved provider integrations must stay behind protected server-side boundaries.

For any approved AI/provider slice:

1. Authenticate the caller through Supabase Auth and authorize the requested user data.
2. Prepare the minimum allowed domain summary through server-side contracts.
3. Call Gemini only from an approved Supabase server function or future `services/api` using deployment-managed secrets.
4. Apply product safety, rate-limit, logging-redaction, and response-shaping rules before returning a client-safe result.
5. Keep prompts, provider credentials, and privileged data joins off Flutter and Wear OS clients.

Use an approved Supabase Edge Function when that boundary fits the request. The future protected application path is `services/api`; add `services/worker` only when queue/background workload requirements justify it. Architecture documentation does not authorize creating either future service.

## Implementation Sequence

1. For each new authenticated vertical slice, define the feature repository contract and the minimum required Supabase table/policy/storage/function boundary.
2. Add migrations, RLS/security tests, and access review appropriate to that slice.
3. Connect Flutter/Wear repositories using only client-safe Supabase configuration and preserve offline-first behavior where required.
4. Add or extend a protected provider integration only when the approved slice has explicit data, safety, cost, and observability requirements.
5. For delegated external connectors, keep the public capability contract runtime-neutral; use an approved narrow Supabase protected function only when it can enforce the complete delegated authorization chain, otherwise start `services/api` through a separately approved protected-service slice.
6. Start `services/api` for other protected-service work only through a separately approved slice when Supabase functions are no longer the appropriate boundary.
7. Start `services/worker` only when a real asynchronous/background workload justifies a separate process.

## Non-Goals Until Approved

- Full database schema or migrations for future features.
- Direct Gemini requests from Flutter, Wear OS, or watchOS.
- Service-role keys in the repository, clients, screenshots, tests, or documentation.
- A custom backend framework, worker system, or queue before a concrete server-side slice requires one.
- Unverified claims that a specific Storage bucket, Edge Function deployment, provider integration, or future service path is live.

## Future-Safe Backend Preservation Rule

Supabase is the **CURRENT production adapter**. Remote HTTP/backend adapters are **FUTURE-SAFE architecture**.

Current source still contains inactive/future-safe backend code such as `ApiClient`, `DioApiClient`, `RemoteProfileSetupRepository`, `RemoteOnboardingFinalizer`, `BackendUserSyncRepository`, and `RemoteBackendUserSyncRepository`; these must NEVER be deleted merely because Supabase is active.

Inactive != obsolete. Removal requires:
1. architecture audit,
2. explicit retirement decision,
3. explicit user approval.

## Related

- [Architecture](../architecture/ARCHITECTURE.md)
- [Connector Trust Boundary](../integrations/CONNECTOR_TRUST_BOUNDARY.md)
- [ADR-0012: Delegated external connector trust boundary](../adr/0012-delegated-external-connector-trust-boundary.md)
- [Data and Sync](DATA_AND_SYNC.md)
- [Security](../security/SECURITY.md)
- [Roadmap](../planning/ROADMAP.md)
- [Supabase public schema inventory](SUPABASE_SCHEMA.md)
- [Architecture](../architecture/ARCHITECTURE.md)
