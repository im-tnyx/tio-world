# #694 Progress root shell top bar and fixed Log Weight action

**Status:** In progress; source and tests pending GitHub CI and independent reviewer. **NO MERGE**.
**Owner approval:** Owner report 2026-10-26, clarified fixed Nutrition parity and color. [GitHub #694](https://github.com/im-tnyx/tio-world/issues/694) is the bounded UI contract. Owner explicitly prohibits merge for current work session.
**Implementation owner:** `im-tnyx`, isolated `feat/issue-694-progress-shell-fixed-log-action`.
**Planning:** Linear [TNYX-119](https://linear.app/tnyx/issue/TNYX-119) In Progress (larger parent), [GitHub #692](https://github.com/im-tnyx/tio-world/issues/692) / open PR #695 separate Weight Log editor-footer slice; #693 UNKNOWN write recovery separate pre-release gate.
**Verified baseline:** `main@80db18965fdba53745d96e9bb97c0cc9ea465caa`. Root/feature AGENTS, Core theme README, shell source, Weight page and test, Nutrition Meal Diary fixed FAB pattern, #694 and Linear reviewed. Windows `G:\projects\Tio-World` not mounted; remote source and GitHub CI only.

## Scoped solution and risks
- **Top-bar geometry:** `apps/core/lib/src/ui/shell/presentation/shell/tio_shell.dart` currently maps `ShellTab.ai || ShellTab.progress` to null. Give Progress an ordinary Core-owned `AppBar`, mirroring other shell bars at `TioNavigationTokens.topBarHeight` (56dp), no fake streak or extra feature actions, preserving tab-neutral `AppBar` title and SafeArea.
- **Fixed bottom action:** Progress `ListView` currently embeds labelled `TioButton.supporting('Log Weight')` beside `History`. Replace it with a fixed `Stack/Positioned.fill/SafeArea/Align(bottomEnd)` action modelled after Nutrition's `MealDiaryPage`, using `TioButton.primary` `colors.primary/onPrimary` and a 56dp SizedBox. Keep label and pill style; never import Nutrition into Progress. Scroll list reserves the 56dp action + surrounding governed `TioSpacing.xl` + bottom safe inset; prevent action obscuring Timeline or Load more.
- **Timeline:** Rename only user-visible section title from `History` to `Timeline`; existing repository/history keys, DTOs, queries, pagination and chart semantics remain untouched.
- **Security:** No Auth/data changes. Preserve existing `_openLogWeight` session ownership and error gating. No SQL, Storage/RLS, watch, services/api, AI or navigation redesign.
- **Ownership/sequence:** PR #695 owns editor sheet and editor tests. This slice must not edit those files or depend on #695 and will be reviewed independently. Do not merge or enable auto-merge.
- **Validation remaining:** Flutter analyze/test exact HEAD, shell top-bar geometry across tabs/compact/large text, fixed button same viewport rect after scrolling, 56dp height and content clearance; independent reviewer and CI. Local device QA unavailable/not claimed.
