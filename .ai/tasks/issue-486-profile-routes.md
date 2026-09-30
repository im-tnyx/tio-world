# GitHub #486 — Profile + Profile Avatar route extraction

**Status:** In progress
**Primary owner:** `apps/app` routing composition
**Affected platforms:** Flutter Android + iOS

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner said `Go` on 2026-09-30 after the fresh post-#485 current-main review identified Profile + Profile Avatar as the next bounded router slice.
**Approved product/UI/data-shape boundaries:** Behavior-preserving extraction of the two existing route registrations into `routing/routes/profile_routes.dart`, plus focused route-composition regression coverage.
**Explicit non-changes:** No visual change, cropper/upload redesign, Profile completion ownership move, Profile Settings behavior change, Account/Daily Wellness/Body/Splash change, persistence/Supabase/Storage/schema/RLS/API change.

## Active Handoff

**Planning owner:** ChatGPT / repository architecture workflow
**Implementation owner:** ChatGPT
**Review owner:** Codex after PR creation
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** GitHub `main@9ee75d8994de4f8348563191f68a07d2a845c24a`
**Branch:** `tnyx/issue-486-profile-routes`
**HEAD SHA:** `792c0b215dc1029cb2706174c0d8e961e0fcb89f` after route + focused test implementation
**Observed working-tree state:** Connector-only execution; local worktree is unavailable and no local cleanliness claim is made.
**Observed uncommitted/dirty files:** Not observable through the GitHub connector.
**PR / tracker:** Draft PR #487; GitHub #486; parents #357/#260; Linear TNYX-201
**Current implementation state:** Profile + Profile Avatar registrations moved into existing `profile_routes.dart`; root direct registrations/helper import removed; focused route navigation test added; upload-helper source assertion updated to the new composition owner.
**Relevant execution surface:** `apps/app/lib/app/router.dart`, `apps/app/lib/app/routing/routes/profile_routes.dart`, Profile app-composition helpers, focused app route tests
**Validation completed at SHA:** Current-main read-only audit only.
**Validation remaining:** hosted Flutter CI; exact-head Codex review; final merge-readiness audit.
**Current blocker:** None.
**Open review finding IDs:** None.
**Next exact action:** Validate exact PR #487 head with hosted Flutter CI and Codex review; fix only in-scope findings before Ready.

## 1. Discovery

### User Outcome

Keep Profile and Profile Avatar behavior identical while reducing root `router.dart` catch-all ownership by grouping their registrations with the already-extracted Profile Settings route.

### Success Criteria

- Root router no longer directly registers Profile or Profile Avatar.
- Existing `profile_routes.dart` owns Profile, Profile Avatar, and Profile Settings registrations.
- Completion reminder, avatar frame, navigation, upload/delete, initials/back behavior stay identical.
- Existing app-composition helper ownership is not silently changed.
- Hosted CI + exact-head Codex are clean before merge.

### Scope

- Move the two `GoRoute` blocks.
- Inject/reuse existing app providers/helpers directly from the app route module.
- Add/adjust focused app-route tests only where current coverage does not lock the moved composition behavior.
- Remove only root imports/references proven unused by the move.

### Non-Goals

- GitHub #201 reusable cropper/upload consolidation.
- Moving `profile_completion.dart` or `profile_avatar_upload.dart` into `apps/features/profile`.
- Profile Settings refactor.
- UI/copy/layout/theme changes.
- Account/Wellness/Body/Splash extraction.
- Supabase/Storage/schema/RLS/API changes.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: root + feature `AGENTS.md`, `MODULE_OWNERSHIP.md`, GitHub #357/#260, Linear TNYX-201, current root router, existing `profile_routes.dart`, Profile feature tests, GitHub #201/#238.
- Existing pattern to follow: route modules under `apps/app/lib/app/routing/routes/` own app-level composition while feature pages remain feature-owned.
- Current feature-level tests cover `ProfilePage` and `AvatarPreviewPage`; app route-level composition coverage is currently lighter.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Move both Profile + Profile Avatar registrations together | Approved | Same feature owner, same provider/avatar composition seams, existing Profile route module already exists | App routing |
| Keep `profile_completion.dart` app-owned for this slice | Approved | TNYX-201 marks it as a separate ownership-audit candidate; moving it now widens scope | App architecture |
| Keep `profile_avatar_upload.dart` unchanged | Approved | GitHub #201 owns future reusable crop/upload consolidation | App architecture |
| Preserve one root `GoRouter` | Approved | Canonical #357 invariant | App routing |

## 4. Architecture Design

### Chosen Approach

Extend the existing `buildProfileRoutes` route module to register the current Profile launcher and Profile Avatar blocks, using the same providers and app-composition helpers they use today. Keep Profile feature pages unchanged.

### Ownership and Data Flow

```text
apps/app router assembly
  -> buildProfileRoutes(...)
    -> app composition providers/helpers
      -> ProfilePage / AvatarPreviewPage / ProfileSettingsRoute
```

### Alternative Rejected

Moving completion reminder or avatar upload workflow into the feature package during this route extraction would mix ownership redesign with mechanical route modularization and conflict with separately tracked #201/TNYX-201 follow-ups.

### Failure and Accessibility States

No new state or UI. Preserve all current loading, avatar fallback, confirmation/feedback, delete and navigation behavior.

## 5. Implementation Plan

- [x] Inspect exact route/helper/test dependencies.
- [x] Move Profile + Profile Avatar registrations into `profile_routes.dart`.
- [x] Remove only proven-unused root imports/references.
- [x] Add/adjust focused route-level regression coverage.
- [x] Audit exact diff for scope and route uniqueness.
- [x] Open Draft PR #487.
- [ ] Run hosted CI + Codex gate.

## 6. Quality Review

### Validation Run

```text
Static branch audit at `792c0b215dc1029cb2706174c0d8e961e0fcb89f`:
- 5 changed paths total: task brief, root router, Profile route module, focused route test, upload-helper source assertion
- root direct Profile registrations: 0
- root direct Profile Avatar registrations: 0
- `profile_routes.dart`: exactly one Profile, one Profile Avatar, one Profile Settings registration
- root router no longer calls `pickAndUploadProfileImage`
- Profile route module calls the shared upload helper at both active Profile/Avatar entry points
- `router.dart` reduced from 974 to 862 lines

Local Flutter commands were not run because connector-only execution has no local worktree/toolchain. Hosted CI remains required.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|

## 7. Final Handoff

### Changed Files

- `.ai/tasks/issue-486-profile-routes.md`
- `apps/app/lib/app/router.dart`
- `apps/app/lib/app/routing/routes/profile_routes.dart`
- `apps/app/test/app/profile_routes_test.dart`
- `apps/app/test/profile/profile_avatar_upload_test.dart`

### Actual Behavior

No intended behavior change. Profile and Profile Avatar keep the same paths, root navigator, canonical Profile provider reads, completion/reminder behavior, plan-derived avatar frame, navigation callbacks, shared pick/upload helper, delete/invalidation behavior, initials fallback and back/pop behavior. Only app route-registration ownership moved into the existing Profile route module.

### Known Limitations

Local worktree and local Flutter commands are unavailable in connector-only execution; hosted CI will be the runtime validation source.

### Final Status

`PARTIAL`
