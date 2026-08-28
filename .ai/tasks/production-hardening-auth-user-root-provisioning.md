# Production Hardening — Database-Owned Auth User Root Provisioning

## Status

COMPLETE / FROZEN under #5.

Audit source head: `5bd429ad8fc5385daaaa1d1dc66993ff7b9d9d5d`

Accepted implementation checkpoint:

```text
91a5e8e00564103a6ea741f790a7a580c4d80b9f
Flutter CI #1838 / run 32760646490 ✅
Android Native CI #250 / run 32760646552 ✅
```

Repo migration:

```text
supabase/migrations/20260824180400_provision_account_root_from_auth_users.sql
```

Live migration:

```text
20260824180611 provision_account_root_from_auth_users
```

## Confirmed problem

The live `tio-world` Supabase project could contain an `auth.users` identity without the required `public.users` account root.

Pre-fix audit checkpoint:

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

## Accepted implementation

1. Added a forward-only database trigger/function so every new `auth.users` row creates exactly one minimal `public.users` root in the same database transaction.
2. Trigger function lives in `private`, uses `SECURITY DEFINER`, and pins `search_path = ''`.
3. Bootstrap projection is limited to safe account metadata:
   - `id` from trusted `auth.users.id`
   - normalized `auth.users.email`
   - bootstrap `name` from provider display metadata, then email local-part, then explicit `Tio User` fallback
   - user metadata is never used for authorization/RLS decisions
   - email/mobile verification timestamps are never fabricated
4. Existing Auth identities missing `public.users` roots were backfilled idempotently and conflict-safely.
5. Client-authoritative root creation was removed:
   - Email signup no longer calls `public.users.upsert(...)`
   - Google profile bootstrap updates the existing DB-owned root instead of upserting/creating it
   - username `profile_missing → client INSERT` repair was removed
6. Provider-avatar enrichment remains a post-auth update only.

## Acceptance result

Final live invariant:

```text
auth.users          4
public.users        4
auth_without_public 0
public_without_auth 0
```

Additional acceptance:

- provisioning trigger exists on `auth.users`;
- trigger function direct EXECUTE is denied to `PUBLIC`, `anon`, `authenticated`, and `service_role`, and granted only to `supabase_auth_admin`;
- rollback-only Email-style trigger regression creates the deterministic email-local-part bootstrap name and normalized email;
- rollback-only Google-style trigger regression uses provider `full_name` and normalized email;
- Product Onboarding Name ownership is unchanged;
- Account Setup username claim no longer creates account roots;
- Flutter/Dart tests and Android native compile are green on the exact accepted implementation SHA;
- Supabase security and performance advisors were reviewed after DDL with no provisioning-specific warning introduced.

## Out of scope

- Email/Mobile verification UX or reconciliation (#8)
- provider linking / password reset / identity uniqueness (#34)
- Account Settings redesign
- Product Onboarding UI/schema changes
- avatar storage lifecycle beyond preserving current post-auth enrichment
- unrelated existing advisor warnings tracked separately under production hardening
