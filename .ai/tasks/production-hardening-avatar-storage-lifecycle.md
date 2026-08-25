# Production Hardening — Avatar Storage Lifecycle

## Status

**COMPLETE / FROZEN.**

Fresh audit head:

```text
40cec5a7e76b862f259881ba83a18edda023a6e9
```

Accepted source/test checkpoint:

```text
a49605481aa3f712bd7f623ffe83c7aa22a3f355
Flutter CI #1920 / run 32821216282 ✅
Android Native CI #332 / run 32821216283 ✅
```

Owner tracker: #5 P1 item 12.

## Goal

Make Profile avatar replacement/removal orphan-safe while preserving `public.users.avatar_url` as the canonical pointer and Supabase Storage as the media owner.

## Fresh findings

### Reproduced lifecycle gap

The pre-fix repository uploaded every local avatar to a unique user-scoped path and wrote its public URL to `public.users.avatar_url`, but did not remove replaced/deleted Storage objects and could leave a newly uploaded object orphaned if the Account pointer write failed.

### Live Storage evidence

Connected project `oykupyiitspujzpwwvuj` has public bucket `avatars`, 10 MB limit, and image MIME allow-list. RLS already scopes INSERT/UPDATE/DELETE to the authenticated user's first folder segment.

Audit found a historical/test user-owned object:

```text
959e0d0f-37c2-4155-b789-edb9920409e4/avatar_1786890218466.jpg
```

while that account's canonical `users.avatar_url` currently points to a Google-hosted avatar URL. This confirmed real orphan evidence. It was intentionally not deleted through SQL; Supabase requires Storage object deletion through the Storage API.

### Supabase guidance applied

Current Supabase docs confirm:
- object deletion must use Storage API `remove`, not direct SQL deletion;
- public buckets still enforce RLS for upload/update/delete;
- user-folder ownership via `storage.foldername(name)` is supported;
- frequently updated assets should prefer new paths over fixed-path overwrite to avoid stale CDN/browser content.

Unique-path uploads therefore remain intentional.

## Accepted implementation

- [x] Avatar Account gateway reads current canonical `avatar_url` before mutation.
- [x] Storage gateway removes objects through Supabase Storage API `remove`.
- [x] Storage cleanup resolves a delete path only when the URL matches this project's public `avatars` URL prefix and the first object folder exactly matches the authenticated user ID.
- [x] External Google/provider URLs never produce a Storage delete path.
- [x] Another user's Storage URL never produces a delete path.
- [x] Replacement order is previous pointer read → unique upload → new pointer write → best-effort previous-owned-object cleanup.
- [x] If the new pointer write fails, the newly uploaded object is best-effort removed and the original write failure is rethrown with its stack trace.
- [x] Delete order is previous pointer read → canonical pointer clear → best-effort previous-owned-object cleanup.
- [x] Cleanup failure after a successful pointer write/clear is logged but does not create a false UI failure for an already-persisted canonical state.
- [x] Signed-out upload remains fail-closed; signed-out delete remains a no-op per existing contract.
- [x] No bucket/RLS/DB migration was required.

## Focused regression

```text
apps/features/profile/test/data/supabase_profile_avatar_repository_test.dart
```

Coverage includes:
- replacement cleanup ordering;
- external-provider replacement safety;
- pointer-write rollback cleanup;
- post-pointer cleanup failure semantics;
- owned-avatar delete cleanup;
- external delete safety;
- signed-out behavior;
- exact project/bucket/user-folder URL ownership parsing;
- cross-user and cross-project delete rejection.

## Acceptance

- [x] Replacing an owned Tio Storage avatar removes the previous referenced object when cleanup succeeds.
- [x] Removing an owned Tio Storage avatar clears the canonical pointer and removes the object when cleanup succeeds.
- [x] External/provider URLs are cleared/replaced without any Storage delete attempt.
- [x] Another user's Storage path cannot be deleted by this repository.
- [x] Failed Account pointer write cleans up the newly uploaded object best-effort and preserves the original failure.
- [x] Cleanup failure after a successful pointer write/clear does not report the pointer mutation as failed.
- [x] Storage deletion uses the Storage API only.
- [x] No DDL/migration.
- [x] Exact-SHA CI green.

## Out of scope / retained evidence

- No bulk historical orphan sweeper was added.
- The known live test orphan was not removed because the connected database tool does not expose a safe Storage object-delete operation and direct SQL deletion is explicitly unsupported for physical object cleanup.
- Account deletion full Storage cleanup remains #5 item 14.
- No avatar visual redesign/crop/editor change.

## Guardrails

- Unique paths remain intentional for cache correctness.
- Never derive a delete path from an arbitrary URL unless exact project/bucket/current-user ownership is proven.
- Never delete external Google/provider media.
- PR #50 remains Draft/open/unmerged unless separately authorized.
