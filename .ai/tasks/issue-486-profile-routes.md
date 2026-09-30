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
**HEAD SHA:** branch created from `main@9ee75d8994de4f8348563191f68a07d2a845c24a`
**Observed working-tree state:** Connector-only execution; local worktree is unavailable and no local cleanliness claim is made.
**Observed uncommitted/dirty files:** Not observable through the GitHub connector.
**PR / tracker:** GitHub #486; parents #357/#260; Linear TNYX-201
**Current implementation state:** Task brief created; source mutation not started.
**Relevant execution surface:** `apps/app/lib/app/router.dart`, `apps/app/lib/app/routing/routes/profile_routes.dart`, Profile app-composition helpers, focused app route tests
**Validation completed at SHA:** Current-main read-only audit only.
**Validation remaining:** exact source/test diff audit; hosted Flutter CI; exact-head Codex review.
**Current blocker:** None.
**Open review finding IDs:** None.
**Next exact action:** Inspect exact Profile/Profile Avatar route dependencies and route-level test seams, then perform the two-registration extraction without changing helper ownership.

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

- [ ] Inspect exact route/helper/test dependencies.
- [ ] Move Profile + Profile Avatar registrations into `profile_routes.dart`.
- [ ] Remove only proven-unused root imports/references.
- [ ] Add/adjust focused route-level regression coverage.
- [ ] Audit exact diff for scope and route uniqueness.
- [ ] Open Draft PR; run hosted CI + Codex gate.

## 6. Quality Review

### Validation Run

```text
Not run yet. Connector-only execution cannot claim local Flutter analyze/test.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|

## 7. Final Handoff

### Changed Files

Pending implementation.

### Actual Behavior

Pending implementation.

### Known Limitations

Local worktree and local Flutter commands are unavailable in connector-only execution; hosted CI will be the runtime validation source.

### Final Status

`PARTIAL`
