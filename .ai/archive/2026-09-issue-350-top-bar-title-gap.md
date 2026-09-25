# #350 — Universal top-bar title gap (`TioAppBar`)

**Status:** Validated
**Completion date:** 2026-09-26
**Primary owner:** `apps/core`
**Affected platforms:** Flutter phone app (Android and iOS)

## Owner Approval and Scope Boundary

**Trigger:** Unapproved product-visible UI/UX change
**Approval status:** Approved
**Approval evidence:**
- 2026-09-25: while reviewing the Library and Exercises screens, the owner called the back-button-to-title gap the biggest top-bar issue. They asked for one universal token, checked on every screen, as a separate task.
- 2026-09-26: the owner answered "GO" to the #350 proposal (one token).
- 2026-09-26: after seeing the 16dp result the owner asked for a smaller gap. From a rendered 16/12/8dp comparison they chose **8dp**.
- 2026-09-26: after Codex review of PR #354 (findings F1–F3 below) the owner chose:
  - **A — a core `TioAppBar` with 8dp**, over a theme-only 12dp variant, from a rendered comparison;
  - **iOS titles start-aligned like Android**.

**Approved product/UI/data-shape boundaries:**
- On standard top bars with a leading back/close button, the visible icon-to-title gap drops from 32dp to 8dp, so the title starts at 48dp instead of 72dp.
- The gap lives in one token.
- On iOS the standard bars' titles become start-aligned instead of centered.
- Standard screens use `TioAppBar`.

**Explicit non-changes:**
- Top-bar height (56dp, TNYX-244/#346).
- Back-icon position (16dp from the edge).
- The title's trailing inset: 16dp before actions or the edge, as on `main`.
- A leading-less bar's 16dp title inset.
- `TioShellTopBar`, `TioShellStatusTopBar` and `OnboardingTopBar`.
- Colors, typography, icons and actions.
- Navigation, persistence and backend.
- #24 (compact input).

## Active Handoff

**Planning owner:** Current task agent
**Implementation owner:** Current task agent
**Review owner:** Codex auto-review on PR #354 (findings F1–F7); task agent self-review
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-26, after the PR #355 post-merge sync. GitHub `main`, `origin/main` and local `main` are all at `bea89d16198fde9e1a425c7ed3c34f5a256f07cd`.
**Branch:** `tnyx/issue-350-top-bar-title-spacing` (merged and deleted locally and remotely at the owner's request)
**HEAD SHA:** Merged PR head `ebaf1ad89316492fff3c9b5b764d056631bcf592`. It was squash-merged to `main` as `03bb578a6f5a15f62c7fc5508253655baad02125`; the merge tree `6341dbcf` is identical to the reviewed head.
**Observed working-tree state:** Not applicable (slice complete)
**Observed uncommitted/dirty files:** Not applicable (slice complete)
**PR / tracker:**
- GitHub #350 and PR #354.
- No Linear issue: the workspace hit its free issue limit on 2026-09-25, and the Linear MCP connector is unauthorized in this session.
**Current implementation state:**
- `TioAppBar` rework for F1–F6 is implemented and committed.
- The theme no longer installs `titleSpacing`.
- All 31 standard AppBars are migrated.
**Relevant execution surface:**
- `apps/core/lib/src/ui/components/navigation/tio_app_bar.dart`
- `apps/core/lib/src/theme`
- the 27 migrated screen files
**Validation completed at SHA:** `a7b42530`: local package runs (see Validation Run) and CI. The final head `ebaf1ad8` changed only this brief; CI passed there too (Analyze and test, Attribution guard runner, Commit attribution guard).
**Validation remaining:** None
**Current blocker:** None
**Open review finding IDs:** None. F1–F6 are fixed in code, with their threads answered and resolved. F7 (stale handoff) is fixed by this record.
**Next exact action:** None for this slice.

## Global UI / Design-System Guardrail

Read before implementation:
- `apps/core/lib/src/theme/README.md` (App bar and topbar height)
- `.ai/tasks/tnyx-244-canonical-appbar-topbar-height.md`

This is an approved visual change, limited to:
- the leading-to-title gap;
- iOS title alignment on standard bars.

Everything else on each top bar must render unchanged.

## 1. Discovery

### User Outcome

On every standard top bar the back button and the title sit close together, and one token controls the gap. It works on every platform and in every route context.

### Success Criteria

- `TioNavigationTokens.topBarTitleGap` is `TioSpacing.sm` (8dp).
- `topBarTitleSpacing` is derived from it: `gap - TioSpacing.lg`, which is -8dp.
- `TioAppBar` applies the derived spacing only when a leading widget exists (explicit, or implied by a poppable route or a drawer). The part of the title over the leading slot ignores pointers, so the leading button keeps its whole tap target while interactive titles are hit where they are painted.
- Without a leading widget the title stays 16dp from the edge.
- The title always stays 16dp clear of the actions or the trailing edge.
- `centerTitle` is false, so iOS matches Android.
- Every standard screen uses `TioAppBar`. `TioTheme` installs no `titleSpacing`, and no screen sets one.
- Shell top bars are unchanged.

### Scope

- Core:
  - `apps/core/lib/src/ui/components/navigation/{tio_app_bar.dart,navigation.dart}`
  - `apps/core/lib/src/theme/tokens/components/tio_navigation_tokens.dart`
  - `apps/core/lib/src/theme/README.md`
  - `apps/core/test/ui/components/tio_app_bar_test.dart`
  - `apps/core/test/theme/primitive_geometry_contract_test.dart`
- The 27 screen files whose 31 `AppBar(` calls become `TioAppBar(`: app router, profile settings route, and the auth, workout, settings, nutrition and profile pages. The only change in each is the constructor name.

### Non-Goals

See Explicit non-changes.

## 2. Codebase Exploration

### Verified Evidence

- Before this slice the title started at 72dp: `TioTheme` set only `appBarTheme.toolbarHeight`, so `titleSpacing` fell back to Flutter's 16dp after the 56dp leading slot. That is 32dp after the 24dp icon, which spans 16–40dp.
- `apps/**/lib` on `48d91f46` has 33 production `AppBar(` call sites in 29 files:
  - 2 are the Core shell wrappers, and they are unchanged.
  - The other 31 standard AppBars use only `title`, `leading`, `automaticallyImplyLeading`, `actions`, `backgroundColor`, `elevation` and `scrolledUnderElevation`. That is exactly the `TioAppBar` API.
- Title-only bars (App Preferences, Theme, Calendar) have no leading widget when opened directly on a route that cannot pop. The router tests do this: `app_mode_router_test.dart` sets `initialPath` and calls `router.go(AppRoutes.themeSettings.path)`.
- On iOS, Flutter centres an AppBar title when the bar has fewer than two actions, unless `centerTitle` is set.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Visible gap 8dp (`TioSpacing.sm`) | Made | Chosen from a rendered 16/12/8dp comparison | Owner |
| Core `TioAppBar` instead of a theme-wide `titleSpacing` | Made | A theme value cannot depend on whether a leading widget exists, and it widens the trailing side (F1, F3). Chosen over a theme-only 12dp variant (48dp leading slot) from a render | Owner |
| iOS titles start-aligned | Made | Consistent gap on both platforms (F2) | Owner |
| Token expresses the visible gap; `titleSpacing` is derived | Made | A later change is one readable dp value | Task agent |
| Keep `main`'s 16dp trailing inset | Made | The only intended change is on the leading side | Task agent |

## 4. Architecture Design

### Chosen Approach

```text
TioSpacing.sm (8dp visible gap)
    ↓
TioNavigationTokens.topBarTitleGap
    ↓  − TioSpacing.lg (icon inset inside Flutter's 56dp leading slot)
TioNavigationTokens.topBarTitleSpacing (−8dp)
    ↓
TioAppBar
  - with a leading widget: titleSpacing −8dp; the title's first 8dp is cleared for pointers and accessibility bounds, so the leading target is intact and hits match paint
  - without one: titleSpacing 16dp
  - title end padding: 16dp − titleSpacing, which keeps the 16dp trailing inset
  - centerTitle: false
    ↓
every standard screen
```

### Ownership and Data Flow

Core token → core `TioAppBar` → feature and app screens through `package:tio_core/core.dart`. The screens only swap the constructor.

### Alternative Rejected

- **Theme-wide negative `titleSpacing`:** the first version of this PR. Codex found three problems with it: F1, leading-less titles past the edge; F2, no effect on iOS centred titles; F3, a widened trailing bound.
- **Theme-only 48dp leading slot with 12dp gap:** moves the icon 4dp toward the edge, still puts leading-less titles on the edge, and the owner preferred 8dp.
- **Per-screen `titleSpacing`:** repeats one invariant across 27 files.

### Failure and Accessibility States

No semantics, focus-order or hit-target change. The leading slot stays 56dp, and the title keeps `AppBar`'s ellipsis and header semantics.

## 5. Implementation Plan

- [x] `topBarTitleGap` token and the derived `topBarTitleSpacing`.
- [x] `TioAppBar` with the leading-aware spacing, the trailing inset and `centerTitle: false`.
- [x] Remove the theme-wide `titleSpacing` and revert the Exercises end padding.
- [x] Migrate the 31 standard AppBars.
- [x] `TioAppBar` tests:
  - height;
  - gap with an explicit leading widget and with an implied back button;
  - leading-less inset;
  - trailing inset with and without actions and leading;
  - all `TargetPlatform`s.
- [x] README contract.
- [x] Analyze/test all affected packages; renders.
- [x] Commit, push, reply to the Codex threads, re-request review.
- [x] Merge PR #354, post-merge sync, delete the branch.

## 6. Quality Review

### Validation Run

```text
First version (theme-wide -8dp), superseded:
- analyze clean, all package tests passed

TioAppBar rework (final working tree):
- flutter analyze --no-pub: No issues found in core, app, workout, settings, nutrition, profile, auth
- flutter test --no-pub, all passed:
  - core 339 (341 after the F4 fix), including tio_app_bar_test (16 after F4) over all TargetPlatforms
  - after F4, all seven packages were re-run: analyze clean, all tests passed
  - after F5, all seven packages were re-run: analyze clean; core 342 (tio_app_bar_test 17), app 379, workout 157, settings 236, nutrition 873, profile 68, auth 159
  - after F6, all seven packages were re-run: analyze clean; core 345 (tio_app_bar_test 20), app 379, workout 157, settings 236, nutrition 873, profile 68, auth 159
  - app 379, workout 157, settings 236, nutrition 873, profile 68, auth 159
- git diff --check: clean
- Temporary renders (harness deleted), 390dp, light + dark:
  - Library: title at x=48, 8dp after the back icon; back icon, action and body unchanged
  - Exercises search: field x=48..326, back icon 16..40, close icon 354..378; trailing edge same as main
  - Leading-less bar: title at x=16
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| F1 | P2 | Fixed | Theme-wide −8dp spacing puts titles of leading-less bars (title-only pages opened directly) past the start edge | `a62ae8db` | `TioAppBar` applies it only with a leading widget; test "insets the title from the edge without a leading widget" |
| F2 | P2 | Fixed | On iOS, short titles are centred, so the gap does not apply | `a62ae8db` | `centerTitle: false` (owner); test over all `TargetPlatform`s |
| F3 | P2 | Fixed | Negative spacing widens the trailing bound; long titles without actions clip past the edge | `a62ae8db` | Title end padding keeps the 16dp trailing inset; tests with and without actions and leading |
| F4 | P2 | Fixed | With −8dp `titleSpacing`, the title box overlaps the leading slot and takes the back button's taps in the 48–52dp strip (and could focus the Exercises search field) | `db563158` | `TioAppBar` lays the title out after the leading slot and applies the negative spacing as a paint-only shift (`Transform.translate`, `transformHitTests: false`, RTL-mirrored). The test "leaves the leading button its whole tap target" fails on `db563158` and passes now; there is also an RTL gap test. The paint-only shift was replaced for F5 |
| F5 | P2 | Fixed | The paint-only shift from the F4 fix separates an interactive title's hit coordinates from its painted position (the Exercises search caret lands about 8dp off, and an invisible 8dp strip past the field hits it) | `b5ae7bbe` | Back to a real −8dp `titleSpacing` (hits match paint), plus a private `_LeadingTapClearance` that makes only the title's first 8dp (the overlap with the leading slot) ignore pointers, RTL-mirrored. The test "hits an interactive title where it is painted" fails on `b5ae7bbe` (12 vs 20) and passes now; the RTL test also taps the back button |
| F6 | P2 | Fixed | `_LeadingTapClearance` only changed pointer hit testing; the title's semantics rect still overlapped the back button's by 8dp, so TalkBack/VoiceOver touch exploration could pick the title or search field there | `f1727c11` | The clearance also clips its child's semantics (`describeSemanticsClip`, RTL-aware), and `TioAppBar` adds AppBar's header semantics inside it (`excludeHeaderSemantics: true` plus the same `header`/`namesRoute`). The two accessibility-bounds tests (text and interactive title) fail on `f1727c11` (48 vs ≥52) and pass now; a header-semantics test was added |
| F7 | P2 | Fixed | The Active Handoff still named `a62ae8db`, listed uncommitted rework and gave commit as the next action | `a7b42530` | Handoff refreshed to the committed state, the validation anchor `a7b42530` and resolved findings |

## 7. Final Handoff

### Changed Files

See Scope, plus this brief and the `.ai/tasks/README.md` row.

### Actual Behavior

- Every standard screen uses `TioAppBar`.
- With a back/close icon, the title starts 8dp after it on every platform.
- Without one, the title is inset 16dp.
- The trailing inset is unchanged.
- `TioNavigationTokens.topBarTitleGap` governs the gap.

### Known Limitations

- The 31 screens were not each rendered on their own. The check relies on:
  - `TioAppBar` geometry tests;
  - the constructor-only migration;
  - renders of the Library and Exercises bars.

### Final Status

`PASS`: merged via PR #354 (`03bb578a`) on 2026-09-25T20:28:19Z (UTC). The gate was a matching head `ebaf1ad8`, green CI, 0 unresolved threads, and Codex "Didn't find any major issues" after findings F1–F7 were fixed. GitHub #350 closed on merge. Linear was not updated: no issue exists (free issue limit), and the connector is unauthorized.
