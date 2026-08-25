# Production Hardening — Avatar Storage Lifecycle

## Status

**AUDIT COMPLETE / IMPLEMENTATION REQUIRED.**

Fresh audit head:

```text
40cec5a7e76b862f259881ba83a18edda023a6e9
```

Owner tracker: #5 P1 item 12.

## Goal

Make Profile avatar replacement/removal orphan-safe while preserving `public.users.avatar_url` as the canonical pointer and Supabase Storage as the media owner.

## Fresh findings

### Current repository leaks replaced/deleted objects

`SupabaseProfileAvatarRepository` currently uploads each local avatar to a unique path:

```text
$userId/avatar_<timestamp>.<ext>
```

and writes its public URL to `public.users.avatar_url`.

However:
- replacing an avatar does not delete the previous owned Storage object;
- deleting an avatar only clears `users.avatar_url` and does not delete the owned Storage object;
- if the Account URL write fails after upload, the newly uploaded object is left orphaned.

### Current live Storage evidence

Connected project `oykupyiitspujzpwwvuj` has public bucket `avatars`, 10 MB limit, and image MIME allow-list. RLS already scopes INSERT/UPDATE/DELETE to the authenticated user's first folder segment.

Live audit found a user-owned object:

```text
959e0d0f-37c2-4155-b789-edb9920409e4/avatar_1786890218466.jpg
```

while that test account's canonical `users.avatar_url` currently points to a Google-hosted avatar URL. This is direct orphan evidence from the current/legacy lifecycle.

No production/test data was mutated during the audit.

### Current Supabase Storage guidance verified

Current Supabase docs confirm:
- Storage object deletion must use the Storage API `remove`, not direct SQL deletion;
- public buckets still enforce RLS for upload/update/delete;
- user-folder ownership via `storage.foldername(name)` is supported;
- overwriting frequently changed assets at one fixed path can serve stale CDN/browser content, so uploading a replacement to a new path is preferred.

Therefore this slice keeps unique-path uploads and adds ownership-safe cleanup rather than switching to a fixed-path overwrite.

## Implementation scope

- [ ] Extend the avatar Account gateway to read the current canonical `avatar_url` before mutation.
- [ ] Extend the Storage gateway with object removal through the Supabase Storage API.
- [ ] Recognize/delete only current-project `avatars` URLs whose first object-path segment exactly matches the authenticated `userId`.
- [ ] Never attempt Storage deletion for Google/external URLs or another user's path.
- [ ] Replacement: read previous URL → upload unique new object → write new canonical URL → remove previous owned object.
- [ ] If the canonical URL write fails after upload, best-effort remove the newly uploaded object and rethrow the original write failure.
- [ ] Delete: read previous URL → clear canonical URL → remove previous owned object.
- [ ] Cleanup after a successful canonical pointer change is best-effort and must not turn a successfully persisted new/cleared pointer into a false UI failure.
- [ ] Preserve current signed-out behavior and canonical `users.avatar_url` ownership.
- [ ] Add focused lifecycle/ownership/failure regressions.
- [ ] Full exact-head Flutter/Dart + Android CI before freeze.

## Out of scope

- Bulk historical orphan sweeper.
- Direct SQL deletion from `storage.objects`.
- Storage bucket/RLS rewrite unless new evidence proves it necessary.
- Google provider-avatar import policy.
- Account deletion full Storage cleanup (#5 item 14).
- Avatar visual redesign/crop/editor changes.
- DB/schema migration.

## Acceptance

- [ ] Replacing an owned Tio Storage avatar no longer leaves the previous referenced object behind when cleanup succeeds.
- [ ] Removing an owned Tio Storage avatar clears the canonical pointer and removes the object when cleanup succeeds.
- [ ] External/provider URLs are cleared/replaced without any Storage delete attempt.
- [ ] Another user's Storage path can never be deleted by this repository.
- [ ] Failed Account pointer write cleans up the newly uploaded object best-effort and preserves the original failure.
- [ ] Cleanup failure after a successful pointer write/clear does not report the pointer mutation as failed.
- [ ] Storage deletion uses the Storage API only.
- [ ] No DDL/migration.
- [ ] Exact-SHA CI green.

## Guardrails

- Unique paths stay intentional for cache correctness.
- Never parse an arbitrary URL into a delete path unless it matches this Supabase project's public `avatars` URL prefix and current user folder.
- Never delete external Google/provider media.
- PR #50 remains Draft/open/unmerged unless separately authorized.
