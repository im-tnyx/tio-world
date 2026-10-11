# GitHub #524 — Routine 3-dot anchored popup card

**Status:** In progress; exact-head CI and manual review pending
**Owner Approval:** Approved visible refinement, 2026-10-11: user confirmed 3-dot trigger placement and explicitly required the opened menu to be a **popup card**, not a bottom sheet.
**Primary owner:** `apps/features/workout`; Core reusable UI consumed through public `package:tio_core/core.dart`.
**Affected platforms:** Flutter phone Program Detail. No other platforms.

## Current source and tracker evidence
- Owner's clean synchronized local `main@83e6fb813fc64b13b5bacc9863f67ab9ee9b8cbc`; remote main independently matched before branching. This GitHub-connected session cannot execute on the owner's Windows worktree, so no claim of locally executed Git/Flutter.
- PR #525 merged and introduced `RoutineMetadataCard` with default Flutter `PopupMenuButton<String>` displaying one real `Edit` action.
- Core already exports `TioAnchoredPopup` publicly, with `OverlayPortal` + elevated `TioCard`, edge-aware anchoring and outside dismissal. The existing `MealLogActionsPopup` in Nutrition demonstrates one-action anchored Edit pattern. Reuse Core rather than cloning an overlay manager.
- [GitHub #524](https://github.com/im-tnyx/tio-world/issues/524) remains OPEN because the full reference Play/Picture/Delete capabilities are not shipped; [GitHub #526](https://github.com/im-tnyx/tio-world/issues/526) continues gating those capabilities; broad [Linear TNYX-267](https://linear.app/tnyx/issue/TNYX-267) remains Backlog/blocked by TNYX-266/TNYX-81.
- Related docs-only PR #523 stays independent; do not mix its W4A archive diff into this task.

## Approved bounded change
1. Keep exactly the current right-side Routine 3-dot, title, static fallback icon, separate Routine cards, Program Detail add icon and Library expand behavior.
2. Replace the stock `PopupMenuButton` presentation with existing Core **`TioAnchoredPopup`**, anchored to 3-dot and rendered as a floating elevated `TioCard`, with compact governed spacing/typography, accessible 48dp target, expanded semantics and outside dismiss.
3. The popup contains only **Edit** for now, invoking the current Rename Routine editor. No fake or disabled `Play`/`Change Picture`/`Delete` until the owner-approved capability contracts in #526 are delivered.
4. Add/adjust focused widget tests for anchored card (not stock PopupMenu), outside dismissal, Edit action, no unshipped options, dark theme/compact viewport. Update canonical Program UI doc to distinguish this reviewed refinement from merged runtime.

**Non-goals:** new Core API/design token, second overlay implementation, Exercise/Set builder, private Routine image storage, Workout Start, Routine deletion/RLS/schema/RPC, Program/Library geometry changes, production writes, app release, merge/branch cleanup.

## Validation and handoff
- **Branch:** `tnyx/issue-524-routine-popup-card`, based on protected `main@83e6fb813fc64b13b5bacc9863f67ab9ee9b8cbc`.
- **Implementation owner:** current GitHub connection session for this narrow UI correction.
- **Review owner:** manual read-only review after implementation (the author's own review is not independent Codex/human approval; quota limitation must be recorded).
- **Implementation ownership state:** Active.
- **Observed worktree state:** user-reported clean main, not independently inspected on Windows; remote GitHub baseline confirmed.
- **Next gate:** exact-head Flutter Analyze/Test + attribution, review findings/scope, separate explicit `Go merge`. Do NOT merge on this task's UI request.
