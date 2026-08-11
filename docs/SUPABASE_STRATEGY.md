# Supabase-First Platform Strategy

## Status

**Target architecture; not implemented.** No Supabase project configuration, client package, migration, environment file, credential, or live integration exists in this repository yet.

## Decision

Supabase is the planned foundation for authenticated user data. It will provide the first production boundary for user identity and data instead of building a custom database/authentication service upfront.

| Responsibility | Planned owner |
| :--- | :--- |
| Authentication and sessions | Supabase Auth |
| User-owned application data | Supabase Postgres with explicit Row Level Security (RLS) |
| User media or documents, when a real slice needs them | Supabase Storage with explicit access policies |
| Schema migrations, RLS policies, seed data, and database functions | future root `supabase/` workspace |
| Flutter/Wear client integration | Feature repositories behind client-safe Supabase contracts |
| Gemini API and other privileged third-party calls | Future protected server-side boundary only |
| Long-running jobs, complex AI orchestration, or protected integrations | Future separate `backend/` workspace when the product outgrows the Supabase-first slice |

Supabase is the data/auth platform; it does not make client code privileged. RLS and feature-level repository boundaries remain required.

## Storage Boundary And Module Buckets

Supabase Storage holds user-owned files only. Structured profile, nutrition, workout, and progress records stay in Supabase Postgres behind feature repositories and RLS; they do not become JSON files in a bucket.

The planned module buckets are private by default and are provisioned only when their first real file use case is approved:

| Future private bucket | Owner | Allowed file purpose | Explicit non-purpose |
| :--- | :--- | :--- | :--- |
| `profile` | Profile | Avatar and approved user profile media | Profile fields, Auth data, or arbitrary document backup |
| `nutrition` | Nutrition | Optional user meal/food images when the diary slice approves them | Meal diary records, food search database, or Meal Plan data |
| `workout` | Workout | Approved user workout attachments only when a concrete feature needs them | The bundled Exercise Search JSON catalog, routine/program records, or sensor streams |
| `progress` | Progress | User progress photos | Weight, measurement, achievement, or trend records |

Each user-owned object must use an ownership-safe path rooted in the authenticated user ID, for example `<user-id>/<object-id>`. Storage policies must enforce that the caller can access only their own object path. Do not use public buckets or public URLs for health/fitness media by default; use an authorised retrieval flow with bounded access instead.

Before a bucket is created, its feature task must define allowed MIME types, size limit, image-processing policy, object naming, metadata, overwrite/delete rules, retention, offline upload state, and owner-specific Storage RLS policies. If replacement uploads are supported, the policy design must cover the full required read/write operation rather than only initial upload.

## Target Repository Shape

```text
tio-world/
├─ apps/                 # Flutter phone, Wear OS, core, shared, feature packages
├─ supabase/             # Future: config, migrations, policies, seed data, functions when approved
├─ backend/              # Future upgrade: protected service code only when required
│  ├─ api/               # authenticated/protected service endpoints
│  ├─ ai-coach/          # Gemini adapter, prompts, guardrails, response shaping
│  └─ jobs/              # long-running or scheduled work
├─ docs/
└─ .ai/
```

`backend/db` is not the target owner for Supabase schema/migrations. Do not create either `supabase/` or `backend/` until a real approved vertical slice needs it.

## Client And Security Boundary

- Flutter and Wear OS can use only a client-safe Supabase URL and publishable key through untracked environment/config injection.
- Never place a Supabase secret/service-role key, Gemini API key, private key, privileged RPC credential, or admin operation in a mobile/watch client.
- Every client-accessible table, view, storage bucket, and function needs an explicit access design. Enable RLS for exposed tables and write ownership-specific policies; authentication alone is not authorization.
- Do not base authorization on user-editable metadata. Feature data access stays behind repository contracts rather than being called directly from widgets.
- Sensitive health, nutrition, workout, recovery, and profile data require the minimum collection, clear user intent, and safe logs.

## Gemini Boundary

Gemini is a future AI provider option for Coach or other approved server-side capabilities. It is not a client dependency or a current product feature.

When an approved AI slice begins:

1. Authenticate the caller through Supabase Auth and authorize the requested user data.
2. Prepare the minimum allowed domain summary through server-side contracts.
3. Call Gemini only from a protected server-side function or the future backend service using deployment-managed secrets.
4. Apply product safety, rate-limit, logging-redaction, and response-shaping rules before returning a client-safe result.
5. Keep prompts, provider credentials, and privileged data joins off Flutter and Wear OS clients.

Choose the exact runtime for Gemini later. A Supabase Edge Function may suit a small protected request; a separate backend is reserved for the upgrade when orchestration, queues, integrations, or operational needs require it. Do not select an unconfirmed framework from a typo or add it as a dependency.

## Implementation Sequence

1. Approve the first authenticated vertical slice and supported sign-in methods.
2. Create the minimal `supabase/` configuration only for that slice.
3. Define the feature repository contract, then add the minimum table/policy/storage boundary with tests and RLS review.
4. Connect the Flutter repository using only client-safe configuration; preserve offline-first behavior where required.
5. Add a protected Gemini integration only when the Coach/AI slice has explicit data, safety, cost, and observability requirements.
6. Create the separate `backend/` workspace only when its documented upgrade criteria are met.

## Non-Goals Until Approved

- Full database schema or migrations for future features.
- Direct Gemini requests from Flutter, Wear OS, or watchOS.
- Service-role keys in the repository, clients, screenshots, tests, or documentation.
- A custom backend framework, worker system, or queue before a concrete server-side slice requires one.
- Claims that Supabase Auth, RLS, Storage, Edge Functions, or Gemini are live.

## Related

- [Architecture](ARCHITECTURE.md)
- [Data and Sync](DATA_AND_SYNC.md)
- [Security](SECURITY.md)
- [Roadmap](ROADMAP.md)
- [Supabase foundation task](../.ai/tasks/supabase-foundation.md)
