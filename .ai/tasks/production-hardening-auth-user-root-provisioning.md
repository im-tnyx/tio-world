# Production Hardening — Database-Owned Auth User Root Provisioning

## Status

ACTIVE implementation slice under #5.

Audit source head: `5bd429ad8fc5385daaaa1d1dc66993ff7b9d9d5d`

## Confirmed problem

The live `tio-world` Supabase project can contain an `auth.users` identity without the required `public.users` account root.

Audit checkpoint:

```text
auth.users          4
public.users        2
auth_without_public 2
public_without_auth 0
```

Both missing roots were Google identities. No custom provisioning trigger existed on `auth.users`.

## Ownership guardrails

```text
public.users         → account/domain root + contacts/status + avatar/bootstrap
public.user_profiles → canonical common Profile, including user-entered Name
```

Do not add Name to Email Signup. Do not make `users.name` canonical Profile Name. Product Onboarding remains:

```text
NameScreen
→ onboarding draft
→ UserProfileMapper
→ UserProfileRepository
→ public.user_profiles.name
```

`users.name` is bootstrap/account compatibility only.

## Implementation scope

1. Add a forward-only database trigger/function so every new `auth.users` row creates exactly one minimal `public.users` root in the same database transaction.
2. Keep the trigger function outside exposed schemas, use `SECURITY DEFINER`, and pin `search_path = ''`.
3. Bootstrap only safe account metadata:
   - `id` from trusted `auth.users.id`
   - normalized `auth.users.email`
   - bootstrap `name` from provider display metadata, then email local-part, then explicit `Tio User` fallback
   - never use user metadata for authorization/RLS decisions
   - never fabricate email/mobile verification timestamps
4. Backfill existing Auth identities missing `public.users` roots idempotently.
5. After the DB invariant is proven, remove client-authoritative root creation:
   - Email signup `public.users.upsert(...)`
   - Google profile bootstrap must update the existing DB-owned root, not upsert/create it
   - username `profile_missing → client INSERT` repair
6. Preserve provider-avatar enrichment as a post-auth update only.

## Acceptance

```text
auth_without_public = 0
public_without_auth = 0
```

Additional acceptance:

- provisioning trigger exists on `auth.users`;
- trigger function is not directly executable by `PUBLIC`, `anon`, or `authenticated`;
- fresh trigger execution creates a root with deterministic bootstrap name/email;
- Product Onboarding Name ownership is unchanged;
- Account Setup username claim no longer creates account roots;
- Flutter/Dart tests and Android native compile are green on the exact accepted SHA;
- Supabase security and performance advisors are reviewed after DDL.

## Out of scope

- Email/Mobile verification UX or reconciliation (#8)
- provider linking / password reset / identity uniqueness (#34)
- Account Settings redesign
- Product Onboarding UI/schema changes
- avatar storage lifecycle beyond preserving current post-auth enrichment
