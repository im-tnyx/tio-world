# GitHub #538 — Routine Set Type bottom-sheet color parity

**Status:** In progress — Draft PR #574; owner-approved Rest button removal and selectable-option follow-up now require new exact-head CI/review.
**Primary owner:** Workout feature presentation (this branch only)
**Affected platforms:** Flutter Android/iOS phone Routine Create/Edit
**GitHub:** #538; Draft PR #574; follow-up to merged PR #570
**Linear:** TNYX-81 (parent W4 remains Backlog / blocked by TNYX-78 and TNYX-80)

## Owner Approval and Scope Boundary

**Trigger:** Product-visible UI change already owner-approved in 2026-10-16 conversation, with explicit `Go` after read-only audit.
**Approved outcome:** Set Type selection bottom sheets display the *same* Normal/Warm Up/Failure/Drop semantic badge colors as Set rows for both Create and Edit.
**In scope:** feature-owned reusable Set badge presentation; replace plain/missing leading indicators with existing Core `TioSelectableCard` option rows in both selection sheets; preserve contextual Normal numbering, selection check and accessibility; remove Edit-only `Rest & set details` by explicit follow-up owner decision; add focused widget/integrity regressions.
**Explicit non-changes:** Set data model, UUID, save/update/auth, rep-range/Delete semantics, *persisted* per-Set Rest data or replay, Core token contracts, shared domain, Supabase SQL/RPC/RLS/deploy, app routing, Watch, AI, exercise cards, other bottom sheets. Only the deprecated Rest editing entrypoint is intentionally removed, not the saved Rest values.

## Active Handoff

**Implementation owner:** This GitHub-connected session; only branch `tnyx/issue-538-set-type-sheet-color-parity`.
**Review owner:** Independent Codex exact-source review completed without major issues at `18bc0ffa`; owner device QA remains required.
**Base source:** `main@42af17a67e84f744ed07cfbc5e66d1fe19f67b41` (merged #570 at `7f05def9`, merged #573 at `42af17a6`).
**Current observed state:** GitHub API source only; Windows worktree and local Flutter SDK unavailable in this session. No claim of local `git status`, `melos`, device rendering or hosted Supabase verification.
**Tracked drift:** #538 text and old #538/#539 stacked PR handoff reflect 2026-10-13 pre-#551 state; present source on main already has durable `RoutineSetType` and sheets. `docs/screens/routine-library.md` still describes merged #570 as Draft. Reconcile only touched documentation relevant to this slice.

## Discovery and Source Evidence

- `create_routine_page.dart::_selectSetType` displays plain leading `1/W/F/D` text, with `1` even when a prospective Normal number is higher.
- `edit_routine_page.dart::_selectSetType` displays no leading type indicator; Edit retains separate `Rest & set details`.
- `routine_set_input_row.dart::_fields` uses `surfaceVariant` 38dp filled, `TioInputTokens.radius` and `textPrimary/primary, warning, danger, info` semantic foreground with >=4.5:1 fallback.
- `routine_set_input_row_test.dart` already protects filled badge geometry and contrast; Create/ Edit page tests cover sheet selection but not its visual semantic parity.
- Reuse `TioEditorSheet` and `showTioEditorSheet` from Core. No new global token/component needed: sheet type visuals are Workout-owned.

## Architecture Decision

Extract the identical existing 38dp Set badge rendering and contrast computation into a small Workout presentation widget consumed by the inline Set row and both Set Type sheet option leading slots. Render leading badges as `ExcludeSemantics` so ListTile labels remain the accessible names. Keep existing option keys, checkmarks, guards and result handling. A candidate Normal badge uses the count of Normal Sets before the selected Set plus one, matching the on-row numbering that would result from conversion.

**Rejected:** independently duplicating semantic switch/contrast logic in Create and Edit, introducing new Core color tokens, implementing premature Rest Timer/Notes behavior, or altering the Set persistence contract.

## Owner screenshot refinement (2026-10-16)

**New explicit approval:** Screenshot shows outlined selectable Set Type rows and visible W/F/D colors. Keep the 38dp filled badge from the shared inline Set row inside each selection option, and use the existing Core `TioSelectableCard` for the outlined selected/unselected surface. Preserve the selection result/check, context-aware Normal numbering, focus, semantics and compact/large-text behavior. Do not clone the reference's pixel geometry, add a new selection color system, or introduce a `More` feature.

**Additional owner decision:** Remove the existing `Rest & set details` action from Edit's `Select Set Type` sheet. The current Edit-only advanced editor is reached exclusively through this action; eliminate its dead entrypoint and rewrite affected integration regressions to exercise the existing inline Reps/Weight/Rep Range editor. Current persisted per-Set `restSeconds` must survive every type/inline edit and Update, but the old Rest editing entrypoint is intentionally no longer offered until the independently planned W4B2 Rest Timer/Notes slices (GitHub #532 / Linear TNYX-81) are approved and implemented. **Do not implement any Rest Timer or Notes UI/data here**. Keep `Remove Set` and existing selected Set actions.

## Owner visual correction — compact outlined variant and Delete icon (2026-10-16)

**Explicit approval evidence:** Owner supplied `IMG_0615.jpeg` and observed the current outlined option rows are too tall, the Delete row lacks the red trash icon and its outline should reuse the Core reusable card's **outlined variant**. Scope stays within Draft PR #574.

**Measured source cause:** Existing `TioSelectableCard` enforces `TioCardTokens.padding = TioSpacing.lg` (16dp per side), so its 38dp Set badge drives an approximately 70dp option height. This global selectable contract has no padding override, and changing it would break unrelated screens.

**Chosen smallest solution:** In Workout-owned `RoutineSetTypeOption`, use existing Core `TioCard(variant: TioCardVariant.outlined, padding: EdgeInsets.symmetric(horizontal: TioSpacing.md, vertical: TioSpacing.sm), onTap: ...)`. Verified rendered option height = 38dp badge + 8dp top/bottom padding + 1dp top/bottom outlined borders = **56dp** (Flutter CI #38873916682 discovered the 2dp difference; no production UI change needed), preserving 48dp minimum usable touch area and allowing growth for text scale. Keep semantic button + selected announcements, existing selected checkmark, Normal/W/F/D badge colors/contrast and stable option keys. Add shared `RoutineRemoveSetOption` composition using the **same** outlined card and 56dp control surface, leading semantic `colors.danger` **trash icon** and unchanged Remove Set action/keys. Use `Icons.delete_outline` and no extra `More` action. Create and Edit must render the same visual pattern.

**Rejected:** altering the shared Core `TioSelectableCard` fixed padding or introducing a new Core card/token variant; rebuilding a bespoke hard-coded outlined `Container`; altering modal shell, Set persistence, Remove Set semantics, or separately planned Rest Timer/Notes.

**Validation needed:** exact-head Flutter CI, compact 320dp light/dark/Tio Dark/high-contrast and text-scale widget assertions, 56dp compact painted card geometry, Core variant usage, red trash icon, tap/action/selected semantics, remove-last-Set contract and no unrelated regressions. This screenshot is a design reference, not evidence of current PR code running on-device.

**2026-10-16 actual CI evidence:** Flutter CI #38873916682 analyzed successfully, but Workout shard had eight failures all for the *test-only* wrong 54dp expected height (actual 56dp from Core's 1dp top/bottom outlines; 616 Workout tests passed). The production compact outlined control is correct. Correct the tests and task/docs to 56dp, rerun exact final-head CI; do not claim success until it finishes.

## Verified source-review checkpoint (2026-10-16)

- GitHub source HEAD `18bc0ffaca94f207c4bee534416f6fb0f32a92d2`: Flutter CI [#38870234939](https://github.com/im-tnyx/tio-world/actions/runs/38870234939) **SUCCESS**, covering analyze (Flutter/Dart), Dart tests, 3 Flutter test shards, and fail-closed `Analyze and test` aggregate.
- Codex independent review receipt on exact `18bc0ffa`: **no major issues**, 0 open review threads; GitHub changed-file/ancestry audit: 10 intended files, 10 commits ahead / 0 behind at source checkpoint.
- Post-source documentation-only status corrections must receive their **own** exact-head CI/review before release; preceding source CI is not claimed for a newer commit.
- No Windows SDK/device tests or local git state verified. Owner device QA and explicit separate merge approval remain pending.

## Validation / Merge Gate

- [ ] Test bottom-sheet label and indicator for all four types, both Create/Edit and selected-state check.
- [ ] Confirm 38dp shape/color/contrast and contextual Normal number in compact light/dark/high-contrast, and no unwanted row visual diff.
- [ ] Preserve Set identity, on-type change and Remove Set; confirm the removed Edit-only advanced-details entrypoint is absent while existing `restSeconds` remains unchanged through inline editing and Update.
- [x] Flutter/Dart Analyze + Flutter/Dart tests passed at source HEAD `18bc0ffa`; recheck exact final docs-only HEAD.
- [x] Independent Codex source review at `18bc0ffa`: no major issues / 0 open threads.
- [ ] Exact final HEAD review, parent ancestry/changed-file audit, physical-device owner QA before explicit `Go merge`.

**No merge or deployment authorized by implementation Go.**
