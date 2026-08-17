# Profile Photo Screen

**Surface:** Phone full-screen Profile child
**Current route:** `/profile/avatar`
**Primary owner:** `apps/features/profile`
**Status:** The route, 1:1 preview surface, fallback, Back behavior, and action
slots are implemented. Image selection, private Storage, deletion, and download
are not implemented.

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
- With no photo, the square shows the shared `TioAvatarSize.extraLarge` fallback,
  whose centralized semantic size is 160dp.
- The full-screen fallback is intentionally unframed for every plan tier.
- The current app route has no media repository or image, so Edit, Delete, and
  Download are visibly disabled. It never pretends that an operation succeeded.
- Back returns to Profile and system Back follows the same route stack.

## Future Media Actions

- Edit requests image selection/capture through a Profile-owned controller.
- Delete requires explicit confirmation, removes only the user's owned object,
  and handles retry/offline state.
- Download requires a real source object, platform permission handling where
  applicable, success/failure feedback, and no exposure of private signed URLs.

## Data And Privacy Boundary

Profile media belongs in the private Supabase `profile` Storage bucket only after
the approved Storage policy, object path, ownership check, signed access, cleanup,
and repository contract exist. Client code must never receive service-role keys.

## Acceptance Criteria

- The Profile 80dp avatar opens this route.
- The preview remains 1:1 on compact and standard phone widths.
- Missing media shows a truthful fallback and no destructive action is enabled.
- Real actions remain disabled until their handlers and data source exist.
- Back returns to Profile without changing bottom-navigation state.
- Screen-reader labels identify the photo and each available action.

## Related

- [Profile](profile.md)
- [Supabase strategy](../SUPABASE_STRATEGY.md)
- [Reusable avatar architecture](../ARCHITECTURE.md#reusable-profile-avatar)
