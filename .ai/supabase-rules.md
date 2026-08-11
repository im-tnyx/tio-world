# Supabase Rules

Use [the Supabase-first platform strategy](../docs/SUPABASE_STRATEGY.md) and root docs as the canonical source for Supabase setup. Supabase is the planned Auth, data, and private-media foundation; no project configuration or live integration is present yet.

## Incremental Setup

Do not create the full database upfront.

Create tables only when a feature slice needs them.

Recommended flow:

1. Build the UI slice.
2. Identify the real data shape.
3. Define the repository contract.
4. Create the minimum Supabase table or RPC.
5. Add RLS.
6. Add demo seed data.
7. Connect repository.
8. Test the feature end to end.

## Security

- Never expose service-role keys to Flutter, web, admin, Wear OS, or watchOS clients.
- Every client-accessible table needs RLS.
- Atomic writes should use hardened RPCs when needed.
- Backend/admin-only operations must stay server-side.
- Production secrets belong in backend deployment configuration, not committed docs or app code.

## Hardcoded Data

Hardcoded data is allowed only as temporary UI scaffolding.

When a feature becomes testable, move source-of-truth data behind:

- repository
- Supabase table or RPC
- demo seed data
- clear test path

## Storage Buckets

The planned private buckets are `profile`, `nutrition`, `workout`, and `progress`. They contain approved user-owned media only; structured data stays in Postgres behind feature repositories and RLS.

- Create a bucket only with its first concrete user-file slice.
- Use an authenticated user-ID object path and owner-specific Storage RLS policies.
- Define MIME type, size, overwrite, deletion, retention, offline upload, and authorised retrieval behavior before implementation.
- Keep the Workout Exercise Search JSON catalog bundled/versioned in the Workout feature; it is not Storage content.

## Flutter Client Boundary

Flutter clients may use publishable/anon keys only when the architecture requires it.

Client code must not contain:

- service-role keys
- private keys
- privileged admin operations
- raw assumptions about database security

## Future Protected Backend

Supabase owns the planned first Auth, Postgres/RLS, Storage, migration, and seed boundary. A separate backend is a later upgrade for Gemini/provider orchestration, advanced integrations, and long-running work.

Protected backend changes must not silently change mobile or watch feature ownership.
