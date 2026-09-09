# Issue #238 — Profile image upload success feedback

**Status:** In progress
**Primary owner:** `apps/app` profile composition
**Affected platforms:** Flutter Android and iOS phone app

## Owner Approval and Scope Boundary

**Trigger:** Unapproved product-visible UI/UX change — a new user-facing confirmation message.
**Approval status:** Approved
**Approval evidence:** GitHub #238 specifies the exact copy, the three entry points, and the acceptance criteria. Owner instruction of 2026-09-10 authorised implementing #238 as a separate small slice off fresh `main`.
**Approved product/UI/data-shape boundaries:** One transient confirmation, `Profile image updated successfully.`, after a successful avatar upload/replace, on the app's existing bottom snack-bar surface. No other visual change.
**Explicit non-changes:** No cropper (#201). No image-picker parameter change. No upload bytes, storage path, repository API, provider-invalidation, navigation or delete/remove change. No Supabase, bucket, policy or schema change. No `apps/core` change. No overlap with #173 / PR #237.

## Active Handoff

**Planning owner:** Owner
**Implementation owner:** Claude
**Review owner:** Owner (+ Codex automated review)
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-10
**Branch:** `tnyx/issue-238-profile-image-success-feedback`
**Base:** `main` `8f0b11ebbbe2d5b58ef961e28117ea7cff93298b`
**HEAD SHA:** `b3749f21a6f0e51ff1607e0480d7df6d35f39ded` plus this brief
**Observed working-tree state:** Dirty with unrelated pre-existing work, preserved untouched
**Observed uncommitted/dirty files:** `pubspec.lock` (modified), `.ai/tasks/tnyx-54-nutrition-ia-readiness.md` (untracked)
**PR / tracker:** GitHub #239, closes GitHub #238
**Current implementation state:** Helper, three call-site migrations, 12 focused tests and PR complete; task brief added after Codex P1
**Relevant execution surface:** `apps/app/lib/app/profile/`, `apps/app/lib/app/router.dart`
**Validation completed at SHA:** `b3749f21` — analyze 16/16 clean, tests 14/14 packages / 2224 passed, `git diff --check` exit 0
**Validation remaining:** Exact-head CI after this brief is pushed
**Current blocker:** None
**Open review finding IDs:** R1 resolved by this brief
**Next exact action:** Push brief, confirm exact-head CI, owner review

## Global UI / Design-System Guardrail

Read before implementation: `AGENTS.md`, `apps/core/lib/src/theme/README.md`, and the current app-wide transient-feedback usage. No new visual contract was introduced; the change reuses the app's existing plain snack-bar presentation and adds no core token, component or theme API.

## 1. Discovery

### User Outcome

After uploading or replacing a profile photo, the user sees confirmation that it saved, instead of the flow appearing to finish silently.

### Success Criteria

- Gallery upload shows `Profile image updated successfully.`
- Camera upload shows the same message.
- Replacing an existing image shows the same message.
- Picker cancel shows nothing.
- Upload failure shows nothing.
- The message is emitted only after `uploadAvatarImage(...)` completes successfully.
- `profileDataProvider` invalidation is unchanged.
- No duplicated snack-bar styling across the three entry points.

### Scope

- `apps/app/lib/app/profile/profile_avatar_upload.dart` (new)
- `apps/app/lib/app/profile/profile_settings_route.dart`
- `apps/app/lib/app/router.dart`
- `apps/app/test/profile/profile_avatar_upload_test.dart` (new)

### Non-Goals

Cropper implementation, avatar storage/bucket/policy change, delete/remove confirmation change, profile page redesign, backend/schema change, any `apps/core` change.

## 2. Codebase Exploration

### Verified Evidence

- Source inspected at `origin/main` `8f0b11eb`: three avatar upload compositions exist — `router.dart:816` (Profile page), `router.dart:868` (Avatar preview/replace), `profile_settings_route.dart:91` (Profile Settings). All three ran the **byte-identical** sequence: pick → null-return → `readAsBytes` → repository lookup → `uploadAvatarImage` → `ref.invalidate(profileDataProvider)`. None emitted feedback.
- `ImagePicker()` was constructed inline at each of the three sites, so picker cancellation was not substitutable and therefore not testable.
- Transient-feedback audit: **no shared or governed presenter exists.** Six raw `ScaffoldMessenger.of(context).showSnackBar` sites, in two different shapes — a plain `SnackBar(content: Text(...))` in `profile_settings_page.dart:262`, and a decorated floating variant with icon/`slate800`/2s in `avatar_preview_page.dart:67`.
- `apps/app` has no package-local `AGENTS.md`; root `AGENTS.md` applies.
- No existing test covered avatar upload from the composition layer.

### Existing Pattern to Follow

`profile_settings_page.dart` save confirmation — plain `ScaffoldMessenger` snack bar, theme defaults, no local styling. Provider overrides for route tests follow `apps/app/test/profile/profile_settings_route_test.dart`.

### Tests or Validation Already Present

`apps/app/test/profile/profile_settings_route_test.dart` covers route rendering states only. Repository-level upload behaviour is covered in `apps/features/profile/test/data/supabase_profile_avatar_repository_test.dart`. Neither covers the composition sequence or feedback.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Extract the full pick→upload→invalidate→confirm sequence into one helper rather than adding the message at three sites | Approved | The three blocks were byte-identical. Three copies of the message means three chances to drift and a fourth entry point silently missing it. #238 explicitly forbids three local recipes. | Owner (#238 scope) |
| Reuse the plain `ScaffoldMessenger` snack bar rather than introducing a presenter | Approved | Audit found no governed presenter and two competing shapes. Inventing a third recipe, or migrating the app to a notification framework for one message, both exceed this issue. | Owner (#238 scope) |
| Move picking behind `profileImagePickerProvider` | Approved | "Picker cancel shows no success message" is an acceptance criterion; with `ImagePicker()` constructed inline it is unprovable. Smallest seam that makes the criterion testable. | Claude, recorded here |
| Do not implement or design cropping | Approved | #201 owns pick → crop → upload. The helper only removes existing duplication and leaves that path free. | Owner (#238 non-goals) |
| Confirmation placed after the upload `await`, not after invalidation only | Approved | A message before completion would promise a save that had not happened. Ordering is pinned by test and mutation-checked. | Owner (#238 acceptance) |

## 4. Architecture Design

### Chosen Approach

One app-level helper owns the sequence; the three compositions become one-line delegations.

### Ownership and Data Flow

```text
ProfilePage / AvatarPreviewPage / ProfileSettingsPage  (onPickImage)
  -> pickAndUploadProfileImage            apps/app composition
     -> profileImagePickerProvider        pick, or null on cancel
     -> ProfileAvatarRepository.uploadAvatarImage
     -> ref.invalidate(profileDataProvider)
     -> ScaffoldMessenger snack bar       only after a successful upload
```

### Alternative Rejected

Extracting only the post-upload tail (`upload → invalidate → confirm`) and leaving picking inline. Rejected because it would keep the picker duplicated three times and leave the picker-cancel acceptance criterion unprovable, while still touching all three files.

### Failure and Accessibility States

- Upload throws: no message, error propagates to the existing caller behaviour unchanged.
- Picker cancelled: no upload, no invalidation, no message.
- Avatar repository unavailable: existing `StateError` preserved, no message.
- Widget unmounted mid-upload: `context.mounted` guard suppresses the message rather than throwing.
- The snack bar is the framework's own, so its existing screen-reader announcement behaviour is unchanged.

## 5. Implementation Plan

- [x] Audit the three upload compositions and the app-wide feedback pattern.
- [x] Add `profile_avatar_upload.dart` with the message constant, picker provider and helper.
- [x] Migrate `router.dart` Profile page and Avatar preview call sites.
- [x] Migrate `profile_settings_route.dart` call site.
- [x] Remove the now-unused `image_picker` import from `router.dart`.
- [x] Add 12 focused tests, including structural tests that no entry point rebuilds the sequence.
- [x] Mutation-check the ordering and invalidation tests.
- [x] Run analyze/tests across the workspace.
- [x] Open PR #239.
- [x] Add this task brief (Codex P1).

## 6. Quality Review

### Validation Run

```text
At b3749f21:
  analyze  16/16 packages  clean
  tests    14/14 packages  2224 passed
  apps/app 317 passed (305 baseline + 12 new)
  git diff --check  exit 0

Mutation checks (production file temporarily altered, then restored):
  removed ref.invalidate(profileDataProvider)
    -> "a successful upload still invalidates the profile" FAILS  (as intended)
  moved the confirmation before the upload await
    -> "the confirmation waits for the upload future to complete" FAILS
    -> "a failed upload says nothing and surfaces the error"     FAILS

Toolchain limitation, recorded rather than hidden:
  the installed melos is v8 and does not load this repo's v6-style melos.yaml,
  so `melos analyze` / `melos test` could not run by name. The per-package
  commands they execute (flutter analyze / flutter test) were run instead
  across all 16 packages.

Exact-head CI after this brief: pending at time of writing.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| R1 | P1 | Resolved | No `.ai/tasks/` brief accompanied the source change, so required evidence, scope, decisions, validation and handoff were unrecorded (AGENTS.md L51-L61) | `b3749f21` | This file. Raised by Codex review on PR #239; the same gap was flagged in the implementation report before review. |

## 7. Final Handoff

### Changed Files

- `apps/app/lib/app/profile/profile_avatar_upload.dart` (new)
- `apps/app/lib/app/profile/profile_settings_route.dart`
- `apps/app/lib/app/router.dart`
- `apps/app/test/profile/profile_avatar_upload_test.dart` (new)
- `.ai/tasks/issue-238-profile-image-upload-success-feedback.md` (this brief)

### Actual Behavior

A successful avatar upload or replace, from any of the three entry points, refreshes the profile and then shows `Profile image updated successfully.` on the app's existing bottom snack-bar surface. A cancelled picker uploads nothing and says nothing. A failed upload says nothing and propagates its error as before.

### Known Limitations

- The app still has no governed transient-feedback presenter; this slice reuses the existing plain snack bar rather than creating one. Consolidating the six `ScaffoldMessenger` sites is separate work and is noted, not attempted.
- Feedback is asserted through the composition layer and structural source checks rather than three full route harnesses; `router.dart` is not independently pumped.

### Final Status

`REVIEW`
