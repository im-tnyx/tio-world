# Profile Photo Screen

Document Status: Canonical Live Doc
Last Verified: 2026-09-27
Owner: `apps/features/profile`
Truth Boundary: Authoritative for the Profile Photo screen product contract, ownership, and documented current/target behavior; runtime source wins for actual shipped behavior and trackers own delivery status.

**Surface:** Phone full-screen Profile child
**Current route:** `/profile/avatar`
**Primary owner:** `apps/features/profile`
**Status:** The route, preview/fallback, Back behavior, image selection/upload, and deletion are implemented through Profile-owned composition and Supabase avatar persistence. Download remains unimplemented.

## Purpose

Let the user inspect and later manage the Profile photo without putting media
logic in Home, the app shell, or Settings.

## Current Content And Behavior

- Top app bar with Back on the left and Edit, Delete, and Download actions on the
  right.
- One maximum-size 1:1 preview surface centered in the available screen below the
  app bar; on portrait phones it uses the full available width.
- A real `ImageProvider` fills the square with `BoxFit.cover` when supplied.
- If the supplied image cannot be decoded, the screen returns to the shared
  unframed fallback and announces that the Profile photo is unavailable.
- With no photo, the square uses the shared avatar fallback behavior while the
  preview surface itself remains screen-sized through `customDimension`.
- `TioAvatarSize.extraLarge` remains a reusable 160dp semantic size, but the
  current full-screen preview does not use it as its runtime dimension.
- The full-screen fallback is intentionally unframed for every plan tier.
- The app route supplies Profile-owned upload and delete handlers. Upload writes to the existing Supabase `avatars` bucket and refreshes canonical Profile data; delete removes the owned object/pointer and invalidates Profile data. Download remains unavailable because no download handler exists.
- Back returns to Profile and system Back follows the same route stack.

## Remaining Media Actions

- Edit/upload and Delete are current actions and must preserve truthful pending/success/failure handling and user-object ownership checks.
- Download remains future work and requires a real source object, platform permission handling where applicable, success/failure feedback, and an approved privacy/access contract.

## Data And Privacy Boundary

The current implementation uses the existing public Supabase `avatars` bucket. Objects are written under the authenticated user's folder; Storage policies restrict authenticated writes/updates/deletes to that owned path, while reads/public URLs are public by current migration design. `public.users.avatar_url` stores the current pointer.

This public bucket is a current compatibility/implementation exception and must not be copied as the default for sensitive health/fitness media. Moving Profile photos to private signed access requires a separately approved migration and client/repository transition. Client code must never receive service-role keys.

## Acceptance Criteria

- The Profile 100dp avatar opens this route.
- The preview remains 1:1 on compact and standard phone widths.
- Missing media shows a truthful shared fallback within the screen-sized preview.
- Edit/upload and Delete are enabled only when their real handlers/repository are available; Download remains unavailable until a real download contract exists.
- Back returns to Profile without changing bottom-navigation state.
- Screen-reader labels identify the photo and each available action.

## Related

- [Profile](profile.md)
- [Supabase strategy](../data/SUPABASE_STRATEGY.md)
- [Reusable avatar architecture](../architecture/ARCHITECTURE.md#reusable-profile-avatar)
