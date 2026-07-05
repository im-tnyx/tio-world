# Supabase Rules

Use root docs and backend docs as the canonical source for Supabase setup.

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

## Flutter Client Boundary

Flutter clients may use publishable/anon keys only when the architecture requires it.

Client code must not contain:

- service-role keys
- private keys
- privileged admin operations
- raw assumptions about database security

## Backend Workspace

Backend, web/admin, shared contracts, and database migrations should be introduced with clear boundaries when those slices start.

Backend changes must not silently change mobile or watch feature ownership.
