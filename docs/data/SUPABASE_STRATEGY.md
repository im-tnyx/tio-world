# Supabase-First Platform Strategy

Document Status: Canonical Live Doc
Last Verified: 2026-10-24 (Flutter B2 source checkpoint; hosted Supabase not rechecked)
Owner: Supabase data ownership + Backend & Platform
Truth Boundary: Authoritative for current Supabase ownership and future protected-service boundaries; runtime source and verified live schema prove actual implementation.

## Status

- **M5B-B2 Flutter source checkpoint (2026-10-24):** The active branch implements the New Program five-second Undo adapter and presentation using the already merged B1 six-argument RPC, shared Move gates, exact mutation-token readback and owner/login-cycle guarded list invalidation. Focused Flutter tests and Workout package analysis pass locally. This source work is awaiting PR review; it is not merged or released. Hosted B1 migration/RPC/grant state was not freshly verified, no grant or migration was changed, and `routineMoveReleaseEnabledProvider=false` remains unchanged. No device QA or production activation is claimed.

**Active current Supabase foundation.**
- The root `supabase/` workspace is the current schema/migration owner and contains the checked-in migration history.
- **Current hosted migration verification (2026-10-21, after owner-approved combined #568/#569 CLI deployment):** **68/68** repository SQL migration versions and names exactly match the linked Tio-world hosted ledger, ending at `20261021130000_harden_move_routine_permanent_owner.sql`; no repository-only or hosted-only migration remains. The last two versions were `20261021120000_grant_my_program_first_routine_execute.sql` and `20261021130000_harden_move_routine_permanent_owner.sql`, applied in order with `--skip-vault`. This is independently verified read-only hosted metadata following the owner-provided Windows push receipt; it is **not** an app feature release or physical-device QA receipt. Historical 2026-10-20 66/66, 2026-10-17 62/64 and 2026-10-11 55/55 snapshots are superseded.
- **#568 / #569 hosted RPC security (verified 2026-10-21):** `public.create_user_workout_routine_in_my_program(uuid,text,uuid,jsonb)` has an intentional authenticated-only EXECUTE grant; `anon`, `service_role`, and `PUBLIC` remain denied. The RPC is now directly reachable over authenticated REST even while `myProgramRoutineCreateReleaseEnabledProvider=false` in the Flutter app. Both #569 Move RPCs have the trusted `auth.users.is_anonymous IS FALSE` guard but remain EXECUTE-denied to all client roles; `routineMoveReleaseEnabledProvider=false`. All three hosted function bodies match their committed reviewed migration bodies after line-ending normalization, with `postgres` ownership, `SECURITY DEFINER`, and empty `search_path`. Security Advisor authenticated-SECDEF WARN count changed from 9 to **10**, exactly the expected new #568 API warning; the pre-existing leaked-password WARN and private RLS no-policy INFO remain. No suppression or client activation was performed.
- W3D2 is deployed and hosted-verified. `public.user_workout_exercises` has 12 columns, with the approved optional description/type/primary-muscle/secondary-muscles/primary-equipment definition fields. Owner RLS and least-privilege authenticated grants remain in force; authenticated DELETE remains unavailable.
- **Routine persistence and guarded Flutter integration (2026-10-17 baseline, updated 2026-10-23):** The relational Program-owned Routine/Exercise/Set foundation from #511 is deployed, and live metadata confirms authenticated-only Create, Save, atomic Name+composition Update, and revision-checked owner-scoped Delete RPCs. All four RPCs use SECURITY DEFINER with empty `search_path`; `anon`/`PUBLIC` lack EXECUTE. The anti-resurrection migration tracks retired Routine IDs in a private RLS-protected table rather than exposing a new `public` table. Routine child tables remain owner SELECT-only to clients; no direct authenticated Routine DELETE grant was added. The Flutter composition adapter merged in [PR #513](https://github.com/im-tnyx/tio-world/pull/513), followed by read-only Detail in [PR #530](https://github.com/im-tnyx/tio-world/pull/530); **merged PR #551** provides the shared Program-scoped Create/Edit composer and real Exercise picker, **PR #570** aligns Create Save/Edit Update and Detail Edit placement, **PR #577** wires persisted atomic Name+composition Edit, and **PR #581** wires a Core Routine actions sheet with only supported actions. The app shell routes guarded Routine capabilities through owner, Auth/session and repository availability gates. **Merged PR #587** wires owner/session-guarded **Routine Delete** callbacks for Program Detail and expanded Library; this verifies source integration, **not** a distributed app release or physical-device QA. **Routine Move** is now wired behind dormant app-shell capability gates: owner/session-safe repositories, direct existing-Program Move, atomic New Program Move (`Save & Move`), cross-operation arbitration, list refresh invalidation, UNKNOWN receipt verification, and **M5A real five-second post-commit reverse Move (Undo) for existing Program moves** (with CAS revision check, decoupled list refresh, and session-guarded feedback) have merged (see [#569](https://github.com/im-tnyx/tio-world/issues/569), [PR #604](https://github.com/im-tnyx/tio-world/pull/604), [PR #616](https://github.com/im-tnyx/tio-world/pull/616), [PR #657](https://github.com/im-tnyx/tio-world/pull/657), [PR #660](https://github.com/im-tnyx/tio-world/pull/660), and [PR #661](https://github.com/im-tnyx/tio-world/pull/661)). Both protected Move RPCs are deployed on hosted Supabase (68/68 migrations) but `EXECUTE` remains denied to `anon`, `authenticated`, and `service_role`; direct authenticated `UPDATE(program_id)` is denied, and `routineMoveReleaseEnabledProvider` is hard-coded `false`. M5A existing-Program Undo is strictly distinct from pending M5B full Create & Move Undo (which requires an atomic reparent-and-delete transaction). Production activation, least-privilege grant review, M5B Create & Move Undo, #567 Program Delete, rollback, and Android/iOS real-write QA remain separate gates. Workout Start and wider W4 acceptance remain separately gated. W1/TNYX-78 is **In Progress** and W4/TNYX-81 is **Backlog** in live Linear at this verification. See the [current Routine contract](../screens/routine-library.md) for status and the [historical persistence handoff](../../.ai/archive/2026-10-issue-509-routine-composition-persistence.md) for prior adapter evidence.
- The [canonical readable current `public` schema inventory](SUPABASE_SCHEMA.md) was structurally measured in [PR #640](https://github.com/im-tnyx/tio-world/pull/640) at the historical 66/66 checkpoint. The later #568/#569 migrations only replace existing function bodies and change an RPC EXECUTE grant: the 19 ordinary `public` tables, RLS-enabled 19/19 status and prior catalog shape measurements are unchanged by those migrations. The inventory's ledger/permission checkpoint has now been reconciled to hosted 68/68; source and live metadata remain authoritative.
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
