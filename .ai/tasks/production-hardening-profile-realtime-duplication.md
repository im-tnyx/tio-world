# Production Hardening — Profile Realtime Duplication

## Status

**COMPLETE / FROZEN — NO LONGER REPRODUCIBLE. NO SOURCE CHANGE REQUIRED.**

Fresh audit head:

```text
d6ba915aece825e90be4f9c00659e5a806123da1
```

Current canonical source/test checkpoint already validated by:

```text
38949e8d25aeed6c5387f3b825deac224717f12d
Flutter CI #1914 / run 32819604848 ✅
Android Native CI #326 / run 32819604927 ✅
```

Owner tracker: #5 P1 item 11.

## Goal

Verify that the current Profile realtime composition does not maintain duplicate subscriptions or duplicate logical paths for the same database change.

## Historical reproduced cause

The retired `SupabaseProfileSetupRepository.watchProfileSetup()` on `main` subscribed to the same `public.users` row through two independent realtime mechanisms at once:

```text
from('users').stream(primaryKey: ['id']).eq('id', userId)
+
client.channel('public:users:$userId').onPostgresChanges(... table: 'users' ...)
```

It also performed an explicit `getProfileSetup()` refresh. A single `users` mutation could therefore reach the Profile controller through multiple independent paths.

## Fresh current-head findings

### Retired broad Supabase Profile stream is absent

The current branch no longer contains `supabase_profile_setup_repository.dart`. Supabase production composition explicitly retires broad `ProfileSetupRepository` access and uses canonical semantic owners instead.

### One app-level Profile stream owner

`profileDataProvider` has one Supabase production path:

```text
CanonicalProfileDataReader
→ CanonicalSupabaseProfileDataStream.watch()
```

It does not compose the retired broad Profile realtime stream in parallel.

### One realtime channel per semantic owner table

`CanonicalSupabaseProfileDataStream` subscribes exactly once to each canonical table needed by Profile display:

```text
users
user_profiles
body_weight_logs
user_body_goals
```

There is no second `.from(...).stream(...)` subscription for any of those tables.

Realtime events are invalidation signals only; every refresh is parsed through the single `CanonicalProfileDataReader` composition.

### Overlapping invalidations are serialized/coalesced

The current stream keeps one `refreshInFlight` operation and a boolean `refreshQueued` follow-up. Concurrent invalidations do not start parallel reader refreshes or independent emission pipelines.

## Acceptance

- [x] Retired dual `users` realtime mechanisms are absent from current Supabase production composition.
- [x] `profileDataProvider` exposes one Supabase Profile stream owner.
- [x] Each canonical semantic owner table has exactly one realtime channel in that stream.
- [x] All realtime invalidations pass through one canonical reader path.
- [x] Overlapping invalidations do not start parallel refresh pipelines.
- [x] Auth-session changes recreate the provider-owned stream rather than adding a second Profile stream implementation.
- [x] No production source change required.
- [x] No DB migration.

## Classification

The historical Profile realtime duplication bug is **no longer reproducible** after the canonical Profile/O11 cutover. The old broad realtime repository must not be restored alongside the canonical stream.

## Guardrails

- Do not add a second `users` realtime source beside `CanonicalSupabaseProfileDataStream`.
- Do not use `.from(...).stream(...)` and an explicit Postgres channel for the same canonical table in parallel.
- Realtime callbacks remain invalidation-only; semantic parsing stays in canonical repositories/readers.
- PR #50 remains Draft/open/unmerged unless separately authorized.
