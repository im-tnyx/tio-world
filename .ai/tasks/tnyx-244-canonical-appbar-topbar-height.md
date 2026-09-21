# TNYX-244 — Canonical AppBar / topbar height ownership

**Status:** In progress  
**Primary owner:** `apps/core`  
**Affected platforms:** Flutter phone app

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice  
**Approval status:** Approved  
**Approval evidence:** Owner requested an `AGENTS.md`-governed audit first, then explicitly authorized advancing the tracked work on 2026-09-21.  
**Approved product/UI/data-shape boundaries:** Pixel-preserving design-system ownership only. Existing 56dp AppBar/topbar geometry must remain unchanged.  
**Explicit non-changes:** No AppBar redesign, no color/elevation/title/action/layout change, no OnboardingTopBar change, no navigation behavior change, no persistence/Supabase/backend work, no #183 or #208 scope.

## Active Handoff

**Planning owner:** ChatGPT  
**Implementation owner:** ChatGPT  
**Review owner:** Not assigned  
**Implementation ownership state:** Active  
**Ownership transition:** Not applicable  
**Repository state last verified:** GitHub `main` at `bf130c697e34b89c5177c4d9056b4b1e2dbade61`; no matching open PR or implementation branch existed before this branch was created. This execution surface writes directly through the GitHub connector and has no local checkout, so local `git status --short --branch` is not available; no local working-tree state is claimed.  
**Branch:** `tnyx/tnyx-244-core-ui-canonical-appbartopbar-height-ownership`  
**HEAD SHA:** `bf130c697e34b89c5177c4d9056b4b1e2dbade61` before this task-file commit  
**Observed working-tree state:** Not applicable to remote GitHub connector execution  
**Observed uncommitted/dirty files:** Not observable / not applicable  
**PR / tracker:** GitHub #189 · Linear TNYX-244  
**Current implementation state:** Fresh audit complete; task brief created before production source mutation.  
**Relevant execution surface:** `apps/core/lib/src/theme`, Core shell topbars, focused Core/app tests  
**Validation completed at SHA:** Audit/search evidence only at `bf130c69`; no source validation yet  
**Validation remaining:** Focused tests, Core/app analyze/tests as applicable, `git diff --check`, exact-head GitHub CI  
**Current blocker:** None  
**Open review finding IDs:** None  
**Next exact action:** Add the canonical topbar-height token and wire the Core theme + shell topbars without touching feature AppBar files.

## Global UI / Design-System Guardrail

Read before implementation:

- `.ai/tasks/design-system-token-consolidation.md`
- `.ai/tasks/material-3-expressive.md`
- `apps/core/lib/src/theme/README.md`
- `docs/UX_UI_SYSTEM.md`

This is a visual-ownership migration, not a visual change.

```text
pixels before == pixels after
56dp before   == 56dp after
```

## 1. Discovery

### User Outcome

Give the app one Tio-owned canonical topbar/AppBar height contract instead of relying on Flutter's implicit `kToolbarHeight` default or repeating 56dp across consumers.

### Success Criteria

- One canonical `TioNavigationTokens.topBarHeight` exists.
- It aliases existing `TioSize.dp56`.
- Bare production AppBars resolve the governed 56dp value through `TioTheme`.
- `TioShellTopBar` and `TioShellStatusTopBar` use the same token.
- No feature/app screen gets an explicit duplicated 56dp `toolbarHeight`.
- No rendered geometry changes.

### Scope

- `apps/core/lib/src/theme/tokens/components/tio_navigation_tokens.dart`
- `apps/core/lib/src/theme/tio_theme.dart`
- `apps/core/lib/src/ui/shell/presentation/widgets/tio_shell_top_bar.dart`
- `apps/core/lib/src/ui/shell/presentation/widgets/tio_shell_status_top_bar.dart`
- focused Core/app tests
- `apps/core/lib/src/theme/README.md`

### Non-Goals

- Onboarding's separate 48dp `OnboardingTopBar`
- AppBar colors/elevation/title/actions/layout
- feature-specific AppBar refactors
- route/navigation behavior
- #183 / TNYX-139
- #208 / TNYX-152
- Supabase/backend/persistence

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected:
  - `TioNavigationTokens`
  - `TioTheme`
  - `TioShellTopBar`
  - `TioShellStatusTopBar`
  - `TioSize`
  - geometry contract tests
  - shell topbar tests
  - Core theme README
- Existing pattern to follow:
  - `TioNavigationTokens.bottomBarHeight = TioSize.dp62`
  - `TioTheme.navigationBarTheme.height = TioNavigationTokens.bottomBarHeight`
- Tests or validation already present:
  - `apps/core/test/theme/primitive_geometry_contract_test.dart`
  - `apps/app/test/app/tio_shell_top_bar_test.dart`

Fresh current-main inventory:

```text
29 production Dart AppBar(...) call sites
27 production Dart files containing AppBar(...)
2 Core shell-wrapper AppBars
27 bare AppBar call sites across 25 non-wrapper Dart files
0 production toolbarHeight overrides
0 appBarTheme definitions
2 direct kToolbarHeight references
```

The direct Flutter-height references are only in:

```text
apps/core/lib/src/ui/shell/presentation/widgets/tio_shell_top_bar.dart
apps/core/lib/src/ui/shell/presentation/widgets/tio_shell_status_top_bar.dart
```

`TioSize.dp56` already exists and is tested as exactly `56.0`.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Canonical semantic owner is `TioNavigationTokens.topBarHeight` | Made | Topbar geometry is reusable navigation chrome; `TioNavigationTokens` already owns bottom-bar height and topbar leading width | Owner-approved audit |
| Physical owner remains `TioSize.dp56` | Made | Existing governed primitive already matches current Flutter default exactly | Design-system contract |
| Govern bare AppBars globally via `ThemeData.appBarTheme.toolbarHeight` | Made | Avoids duplicating the same value in 25 files and keeps one canonical owner | Audit |
| Keep shell PreferredSize contract explicit | Made | Reusable shell topbars are `PreferredSizeWidget`s and must not reference Flutter's constant directly | Audit |
| No visible geometry change | Frozen | This is ownership cleanup only | Owner |

## 4. Architecture Design

### Chosen Approach

```text
TioSize.dp56
    ↓
TioNavigationTokens.topBarHeight
    ↓
TioTheme.appBarTheme.toolbarHeight
    ↓
all bare AppBar consumers

TioNavigationTokens.topBarHeight
    ↓
TioShellTopBar / TioShellStatusTopBar preferredSize
```

Where practical, the shell widgets should also pass the token to their inner `AppBar.toolbarHeight` so their reusable component contract remains self-contained and cannot diverge from their `PreferredSizeWidget` height.

### Ownership and Data Flow

```text
TioSize primitive
→ TioNavigationTokens semantic component contract
→ TioTheme / reusable shell components
→ app + feature consumers
```

### Alternative Rejected

Adding `toolbarHeight: TioNavigationTokens.topBarHeight` independently to all 27 bare AppBar call sites.

Reason: mechanically duplicates a global invariant across 25 files, increases future churn, and contradicts the one-owner design-system rule.

### Failure and Accessibility States

No state behavior changes. Existing AppBar semantics, focus order, actions, title behavior and compact-width behavior must remain unchanged.

## 5. Implementation Plan

- [ ] Add `TioNavigationTokens.topBarHeight = TioSize.dp56`.
- [ ] Set `ThemeData.appBarTheme.toolbarHeight` from that token in `TioTheme`.
- [ ] Replace both direct `kToolbarHeight` shell preferred-size references with the token.
- [ ] Keep shell internal AppBar height aligned to the same token.
- [ ] Extend geometry contract tests.
- [ ] Add focused theme/AppBar regression coverage proving bare AppBar = 56dp.
- [ ] Extend shell tests to prove preferred/actual toolbar height = canonical token.
- [ ] Document the topbar-height ownership contract in the Core theme README.
- [ ] Search current branch for direct production `kToolbarHeight` and feature-level `toolbarHeight` duplication.
- [ ] Run applicable formatting/analyze/tests and `git diff --check`.
- [ ] Open a bounded draft PR linked to GitHub #189 / TNYX-244 after local/source validation evidence exists.

## 6. Quality Review

### Validation Run

```text
Not run yet. No production source has been mutated before this task brief.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| | | | | | |

## 7. Final Handoff

### Changed Files

Task brief only at this checkpoint.

### Actual Behavior

No runtime behavior change yet.

### Known Limitations

This execution surface does not expose a local checkout, so local working-tree state and local commands cannot be claimed. GitHub branch/source state and GitHub CI remain verifiable remotely.

### Final Status

`PARTIAL` — audit and tracker/task setup complete; bounded implementation is next.
