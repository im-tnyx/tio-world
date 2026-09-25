# #350 — Universal top-bar title gap token

**Status:** In progress
**Primary owner:** `apps/core`
**Affected platforms:** Flutter phone app

## Owner Approval and Scope Boundary

**Trigger:** Unapproved product-visible UI/UX change
**Approval status:** Approved
**Approval evidence:**
- 2026-09-25: while reviewing the Library and Exercises screens, the owner called the back-button-to-title gap the biggest top-bar issue. They asked for one universal token, checked on every screen, as a separate task.
- 2026-09-26: the owner answered "GO" to the #350 proposal (one token installed through the theme).
- 2026-09-26: after seeing the 16dp result the owner asked for a smaller gap. From a rendered 16/12/8dp comparison they chose **8dp**.

**Approved product/UI/data-shape boundaries:**
- On standard AppBars with a leading back/close button, the visible icon-to-title gap drops from 32dp to 8dp: the title starts at 48dp instead of 72dp.
- The value lives in one token installed through `TioTheme`.
- The Exercises search field pads its end so it stays out of the close action's slot.

**Explicit non-changes:**
- Top-bar height (56dp, TNYX-244/#346).
- Back-icon position (16dp from the edge).
- `TioShellTopBar` and `TioShellStatusTopBar`, which have their own leading width and an explicit `TioSpacing.lg` title inset.
- `OnboardingTopBar`.
- Colors, typography, icons and actions.
- Per-screen `titleSpacing`.
- Navigation, persistence and backend.
- #24 (compact input).

## Active Handoff

**Planning owner:** Current task agent
**Implementation owner:** Current task agent
**Review owner:** Not assigned
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-26; branch created from `main` at `48d91f469882aeeef16f1d24bbdc8d36263d3906` with a clean tree
**Branch:** `tnyx/issue-350-top-bar-title-spacing`
**HEAD SHA:** `48d91f46` plus uncommitted slice changes
**Observed working-tree state:** Only this slice's files modified
**Observed uncommitted/dirty files:** This slice's files only
**PR / tracker:** GitHub #350. No Linear issue exists: the workspace hit its free issue limit on 2026-09-25, and the Linear MCP connector is unauthorized in this session.
**Current implementation state:** Implementation and local validation are complete.
**Relevant execution surface:** `apps/core/lib/src/theme`, `apps/core/test/theme`, `apps/features/workout/lib/src/presentation/library/exercises/exercises_page.dart`
**Validation completed at SHA:** Local runs on the working tree (see Validation Run)
**Validation remaining:** CI at the PR head
**Current blocker:** None
**Open review finding IDs:** None
**Next exact action:** Commit, push and open the PR linked to #350.

## Global UI / Design-System Guardrail

Read before implementation:
- `apps/core/lib/src/theme/README.md` (App bar and topbar height)
- `.ai/tasks/tnyx-244-canonical-appbar-topbar-height.md`

This is an approved visual change limited to the leading-to-title gap. Everything else on each top bar must render unchanged.

## 1. Discovery

### User Outcome

On every standard top bar the back button and the title sit close together, and one token controls the gap.

### Success Criteria

- `TioNavigationTokens.topBarTitleGap` is `TioSpacing.sm` (8dp).
- `TioNavigationTokens.topBarTitleSpacing` derives from the gap: `gap - TioSpacing.lg`, which is -8dp.
- `TioTheme` installs the spacing through `appBarTheme.titleSpacing`, and no screen sets its own `titleSpacing`.
- A standard AppBar with a back button keeps its icon at 16dp and draws the title 8dp after the icon.
- Shell top bars are unchanged.

### Scope

- `apps/core/lib/src/theme/tokens/components/tio_navigation_tokens.dart`
- `apps/core/lib/src/theme/tio_theme.dart`
- `apps/core/lib/src/theme/README.md`
- `apps/core/test/theme/primitive_geometry_contract_test.dart`
- `apps/core/test/theme/tio_theme_app_bar_contract_test.dart`
- `apps/features/workout/lib/src/presentation/library/exercises/exercises_page.dart` (search-field end padding)

### Non-Goals

See Explicit non-changes.

## 2. Codebase Exploration

### Verified Evidence

- Before this slice `TioTheme` set only `appBarTheme.toolbarHeight`. `titleSpacing` fell back to Flutter's 16dp, so with the 56dp leading slot the title started at 72dp: 32dp after the 24dp icon, which spans 16–40dp.
- `apps/**/lib` on `48d91f46` has 33 production `AppBar(` call sites in 29 files:
  - 2 are the Core shell wrappers. Both set `automaticallyImplyLeading: false`. `TioShellStatusTopBar` sets `titleSpacing: TioSpacing.lg` explicitly, and `TioShellTopBar` has no title, so neither is affected.
  - 28 standard AppBars pass an explicit leading widget: `BackButton`, or an `IconButton` on Forgot Password.
  - 3 standard AppBars are title-only (App Preferences, Theme, Calendar). They are pushed routes, so Flutter adds an implied `BackButton`.
- No production AppBar sets `titleSpacing`, `leadingWidth` or `centerTitle`, and no standard AppBar exists without a leading widget.
- The only AppBar title that fills its slot is the Exercises search field. Every other title is `Text`.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Visible gap 8dp (`TioSpacing.sm`) | Made | Chosen from a rendered 16/12/8dp comparison after the 16dp draft | Owner |
| Token expresses the visible gap; the theme spacing is derived from it | Made | A later change is one readable dp value | Task agent |
| Install once through `ThemeData.appBarTheme.titleSpacing` | Made | Same one-owner pattern as `topBarHeight` (TNYX-244) | Owner ("GO") |
| Exercises search field pads its end by `-topBarTitleSpacing` | Made | Negative spacing also widens the title slot on the trailing side. Without the padding the field reached 8dp into the close action's slot, 4dp from the X icon | Task agent, visible in renders |
| AppBar without a leading widget | Made | None exists. The README requires such a bar to use `TioShellStatusTopBar` or pass an explicit governed `titleSpacing` | Task agent, documented for owner review |

## 4. Architecture Design

### Chosen Approach

```text
TioSpacing.sm (8dp visible gap)
    ↓
TioNavigationTokens.topBarTitleGap
    ↓  − TioSpacing.lg (icon inset inside Flutter's 56dp leading slot)
TioNavigationTokens.topBarTitleSpacing (−8dp)
    ↓
TioTheme.appBarTheme.titleSpacing
    ↓
all standard AppBar consumers
```

### Ownership and Data Flow

Core token → Core theme → every feature/app AppBar through `Theme`. The one feature change is the Exercises search field's end padding, which is expressed with the same token.

### Alternative Rejected

- **Per-screen `titleSpacing`:** duplicates one invariant across 27 files.
- **Shrinking `leadingWidth`:** moves the back icon toward the screen edge and shrinks the leading slot below its 56dp width.

### Failure and Accessibility States

- No semantics, focus-order or hit-target change; the leading slot stays 56dp.
- A text title long enough to ellipsize can end up to 8dp further right than before. That point is still inside the trailing action's 12dp icon padding.

## 5. Implementation Plan

- [x] Add `topBarTitleGap` and the derived `topBarTitleSpacing`.
- [x] Install the spacing in `TioTheme`.
- [x] Extend the geometry contract test, and add a test for the icon position and the gap.
- [x] Document the contract in the Core theme README.
- [x] Pad the end of the Exercises search field.
- [x] Render the baseline, the 16dp draft, the gap options and the 8dp result.
- [x] Analyze and test `core`, `app`, `workout`, `settings`, `nutrition`, `profile` and `auth`.
- [ ] Commit, push, open the PR.

## 6. Quality Review

### Validation Run

```text
Temporary renders (uncommitted harnesses, deleted after use), 390dp, light + dark:
- Library at 8dp: title moved from x=72 to x=48; back icon, actions, body unchanged
- Exercises at 8dp: same title move; search/filter actions unchanged
- Exercises search at 8dp: field x=48..342, close icon x=354..378 (8dp left gap, 12dp to the X); height unchanged
- Gap options 16/12/8dp rendered for the owner's choice

At the final 8dp working tree:
flutter analyze --no-pub: No issues found in core, app, workout, settings, nutrition, profile, auth
flutter test --no-pub: all passed
  core 326, app 379, workout 157, settings 236, nutrition 873, profile 68, auth 159
git diff --check: clean
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| | | | | | |

## 7. Final Handoff

### Changed Files

See Scope, plus this brief and the `.ai/tasks/README.md` row.

### Actual Behavior

- Every standard AppBar draws its title 8dp after the back/close icon.
- The value is governed by `TioNavigationTokens.topBarTitleGap`.

### Known Limitations

- The 31 standard AppBars were not each rendered on their own. The check relies on:
  - the structural inventory above: every one inherits the theme value through the same 56dp leading slot, with no overrides;
  - renders of the Library and Exercises bars.

### Final Status

`IN PROGRESS`
