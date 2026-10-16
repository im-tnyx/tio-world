# GitHub #538 — Routine Set Type bottom-sheet color parity

**Status:** In review — Draft PR #574; owner-approved 0.75dp picker outline trial implemented after prior 1dp CI, so new exact-head Flutter CI/review and owner device QA are required. Prior 1dp CI passed at `69c16e98`.
**Primary owner:** Workout feature presentation (this branch only)
**Affected platforms:** Flutter Android/iOS phone Routine Create/Edit
**GitHub:** #538; Draft PR #574; follow-up to merged PR #570
**Linear:** TNYX-81 (parent W4 remains Backlog / blocked by TNYX-78 and TNYX-80)

## Owner Approval and Scope Boundary

**Trigger:** Product-visible UI change already owner-approved in 2026-10-16 conversation, with explicit `Go` after read-only audit.
**Approved outcome:** Set Type selection bottom sheets display the *same* Normal/Warm Up/Failure/Drop semantic badge colors as Set rows for both Create and Edit.
**In scope:** feature-owned reusable 38dp Set badge; both Create/Edit pickers use existing Core `TioCard(variant: TioCardVariant.outlined)` with 12dp horizontal/8dp vertical content padding and validated 56dp rendered height (including border), accessible selected/check state, contextual Normal numbering, and matching outlined `Remove Set` action with danger-colored trash icon; remove the obsolete Edit-only `Rest & set details` entrypoint per owner approval; preserve stored Rest data, Set identity, and focused widget/integrity regressions. Do not revert to padding-fixed `TioSelectableCard` (its 70dp rows were owner-rejected).
**Explicit non-changes:** Set data model, UUID, save/update/auth, rep-range/Delete semantics, *persisted* per-Set Rest data or replay, Core token contracts, shared domain, Supabase SQL/RPC/RLS/deploy, app routing, Watch, AI, exercise cards, other bottom sheets. Only the deprecated Rest editing entrypoint is intentionally removed, not the saved Rest values.

## Active Handoff

**Implementation owner:** This GitHub-connected session; only branch `tnyx/issue-538-set-type-sheet-color-parity`.
**Review owner:** Codex reviewed compact production at `71c073c` without major issues and latest docs-only HEAD `b108ed48` with two P2 handoff findings now being corrected. Final exact-head re-review and owner physical-device QA remain required.
**Base source:** `main@42af17a67e84f744ed07cfbc5e66d1fe19f67b41` (merged #570 at `7f05def9`, merged #573 at `42af17a6`).
**Current observed state:** GitHub API source only; Windows worktree and local Flutter SDK unavailable in this session. No claim of local `git status`, `melos`, device rendering or hosted Supabase verification.
**Tracker reconciliation:** #538's original implementation/migration proposal and the older #538/#539 stacked handoff reflect the pre-#551 state. Current `main` already has durable `RoutineSetType` and Create/Edit selection behavior, and `docs/screens/routine-library.md` has been corrected to identify PR #570 as merged. This follow-up PR #574 only completes the documented picker visual parity and owner-approved obsolete Rest entrypoint removal; no database rollout or broader #538 acceptance is claimed.

## Discovery and Source Evidence

- `create_routine_page.dart::_selectSetType` displays plain leading `1/W/F/D` text, with `1` even when a prospective Normal number is higher.
- `edit_routine_page.dart::_selectSetType` displays no leading type indicator; Edit retains separate `Rest & set details`.
- `routine_set_input_row.dart::_fields` uses `surfaceVariant` 38dp filled, `TioInputTokens.radius` and `textPrimary/primary, warning, danger, info` semantic foreground with >=4.5:1 fallback.
- `routine_set_input_row_test.dart` already protects filled badge geometry and contrast; Create/ Edit page tests cover sheet selection but not its visual semantic parity.
- Reuse `TioEditorSheet` and `showTioEditorSheet` from Core. No new global token/component needed: sheet type visuals are Workout-owned.

## Architecture Decision

Extract the existing 38dp Set badge rendering and contrast computation into one Workout-owned presentation widget reused in inline Set rows and both sheet options. Compose the picker and Remove Set actions with Core `TioCardVariant.outlined`, compact 56dp painted geometry, and explicit button/selected/label semantics, retaining existing option keys, selected checkmarks, guards and result handling. A candidate Normal badge uses the count of Normal Sets before the selected Set plus one, matching the on-row numbering that would result from conversion.

**Rejected:** independently duplicating semantic switch/contrast logic in Create and Edit, introducing new Core color tokens, implementing premature Rest Timer/Notes behavior, or altering the Set persistence contract.

## Owner screenshot refinement (2026-10-16)

**Initial visual direction (superseded by compact-card refinement below):** The screenshot called for outlined selectable rows and visible W/F/D colors, initially prototyped using Core `TioSelectableCard`. The owner then rejected its oversized ~70dp rows. The final approved UI uses the existing Core `TioCardVariant.outlined` with custom presentation composition and measured 56dp height; selection/check, context-aware numbering, semantics and larger-text growth remain intact. Do not clone the reference's other geometry, add a new selection color system, or introduce a `More` feature.

**Additional owner decision:** Remove the existing `Rest & set details` action from Edit's `Select Set Type` sheet. The current Edit-only advanced editor is reached exclusively through this action; eliminate its dead entrypoint and rewrite affected integration regressions to exercise the existing inline Reps/Weight/Rep Range editor. Current persisted per-Set `restSeconds` must survive every type/inline edit and Update, but the old Rest editing entrypoint is intentionally no longer offered until the independently planned W4B2 Rest Timer/Notes slices (GitHub #532 / Linear TNYX-81) are approved and implemented. **Do not implement any Rest Timer or Notes UI/data here**. Keep `Remove Set` and existing selected Set actions.

## Owner visual correction — compact outlined variant and Delete icon (2026-10-16)

**Explicit approval evidence:** Owner supplied `IMG_0615.jpeg` and observed the current outlined option rows are too tall, the Delete row lacks the red trash icon and its outline should reuse the Core reusable card's **outlined variant**. Scope stays within Draft PR #574.

**Measured source cause:** Existing `TioSelectableCard` enforces `TioCardTokens.padding = TioSpacing.lg` (16dp per side), so its 38dp Set badge drives an approximately 70dp option height. This global selectable contract has no padding override, and changing it would break unrelated screens.

**Chosen smallest solution:** In Workout-owned `RoutineSetTypeOption`, use existing Core `TioCard(variant: TioCardVariant.outlined, padding: EdgeInsets.symmetric(horizontal: TioSpacing.md, vertical: TioSpacing.sm), onTap: ...)`. Verified rendered option height = 38dp badge + 8dp top/bottom padding + 1dp top/bottom outlined borders = **56dp** (Flutter CI #38873916682 discovered the 2dp difference; no production UI change needed), preserving 48dp minimum usable touch area and allowing growth for text scale. Keep semantic button + selected announcements, existing selected checkmark, Normal/W/F/D badge colors/contrast and stable option keys. Add shared `RoutineRemoveSetOption` composition using the **same** outlined card and 56dp control surface, leading semantic `colors.danger` **trash icon** and unchanged Remove Set action/keys. Use `Icons.delete_outline` and no extra `More` action. Create and Edit must render the same visual pattern.

**Rejected:** altering the shared Core `TioSelectableCard` fixed padding or introducing a new Core card/token variant; rebuilding a bespoke hard-coded outlined `Container`; altering modal shell, Set persistence, Remove Set semantics, or separately planned Rest Timer/Notes.

**Validation needed:** exact-head Flutter CI, compact 320dp light/dark/Tio Dark/high-contrast and text-scale widget assertions, 56dp compact painted card geometry, Core variant usage, red trash icon, tap/action/selected semantics, remove-last-Set contract and no unrelated regressions. This screenshot is a design reference, not evidence of current PR code running on-device.

## Owner thin-outline trial — 0.75dp (2026-10-16)

**Approval evidence:** Owner explicitly requested to **try 0.75dp** on Set Type selection outlines after verifying that the current Core `TioCardVariant.outlined` is 1.0dp. This is a reversible presentation-only experiment **within Draft PR #574**; it is not device QA acceptance or a merge instruction.

**Baseline:** Core `TioCardVariant.outlined` uses Flutter `Border.all(color: colors.outlineStrong)` with default 1.0dp; both Workout `RoutineSetTypeOption` and `RoutineRemoveSetOption` use that variant and are 56dp high at standard text scale.

**Chosen bounded implementation:** Add optional, **outlined-only** `outlinedBorderWidth` parameter to Core `TioCard`, defaulting to the unchanged existing `TioStroke.width1`. Both Workout selector option and Remove Set compositions pass the **existing** `TioCardTokens.borderThin` (`TioStroke.width075`, 0.75dp). Preserve `TioCardVariant.outlined` reuse, `colors.outlineStrong`, radius, content padding, selected check/semantics, action behavior and 38dp type badge. Expected nominal visual height 55.5dp (38dp + 16dp padding + 1.5dp stroke) versus previous 56dp; widget/CI must verify actual measurements. No global change to other Core cards.

**Ownership / tests:** Core owns the generic optional parameter and its default/override regression tests plus theme README contract; Workout owns both callers and 320dp light/dark/high-contrast widget tests. No new tokens, alternate card variants, Rest Timer/Notes, persistence/backend/router changes. Exact-head Flutter CI, independent review, owner device QA, and a separate final merge gate required. A prior `Go merge with gate` was held because physical-device acceptance remained unverified.

## Verified exact-source CI and review (2026-10-16)

- Initial UI-color-only source HEAD `18bc0ffa`: Flutter CI [#38870234939](https://github.com/im-tnyx/tio-world/actions/runs/38870234939) **SUCCESS**, with Codex no-major-issues review. **Historical only:** later owner-approved *production* code changes added the outlined options and removed the legacy Edit details action. The old CI must not be used to assert the new UI is validated.
- Compact Core outlined-card production at `71c073c` (same production code as the latest tested source): Codex reviewed **no major issues**. Flutter CI [#38873916682](https://github.com/im-tnyx/tio-world/actions/runs/38873916682) analyzed successfully; 616 Workout tests passed and eight new widget assertions failed solely because tests expected a 54dp card while Core actually paints 56dp (38dp badge + 8dp top/bottom padding + 1dp top/bottom outline border).
- Fully corrected *source and tests* at `c5e150f45423820c0e663c93db0ec171d6226c9d`: Flutter CI [#38874701233](https://github.com/im-tnyx/tio-world/actions/runs/38874701233) **SUCCESS**, including Flutter/Dart Analyze, Dart tests, three Flutter shards and fail-closed `Analyze and test` aggregate. The previously failing Workout tests passed. GitHub compare at checkpoint: 44 task-only commits ahead / 0 behind `main@42af17a6`, 12 changed files in scoped Workout presentation/tests and task/canonical docs.
- Codex on exact `c5e150f` found two documentation-only findings: [P3 literal escaped newline in the canonical screen doc](https://github.com/im-tnyx/tio-world/pull/574) and [P2 misleading docs-only handoff checkpoint](https://github.com/im-tnyx/tio-world/pull/574). Both are valid; correct them without production/test changes, then revalidate final docs-only HEAD and resolve/review the threads before merge.
- No local Windows git status/Flutter SDK tests, physical-device screenshot QA or deployed Supabase verification was available here. Owner device acceptance and explicit separate `Go merge` remain required.

## Validation / Merge Gate

- [x] All four type option badges, both Create/Edit modes, selected check, normal-only numbering and 38dp foreground contrast tested; compact outlined 56dp cards, red trash icon and 320dp theme/high-contrast/text-scale covered by widget tests at `c5e150f`.
- [x] Existing Set identity, Set Type change, Remove Set and last-Set contract remain; Edit old Rest details entrypoint absent and stored `restSeconds` preserved on inline input/Update/rejection, verified in Flutter widget tests at `c5e150f`.
- [x] Flutter/Dart Analyze + all Flutter/Dart tests and aggregate CI **SUCCESS** at `c5e150f`, exact tested code.
- [x] Independent Codex review of compact production changes at `71c073c` reported no major issues.
- [x] Flutter CI #38875397438 passed at docs-only `b108ed48`; earlier P2/P3 findings replied to and resolved, with 46 ahead/0 behind and 12 scoped paths verified at that checkpoint.
- [ ] Validate the new documentation-only P2 handoff remediation HEAD with exact-head CI, independent review, no unresolved findings and refreshed ancestry/paths.
- [ ] Validate the owner's **0.75dp** thin-outline trial on both picker option and Remove Set using `TioCardTokens.borderThin` while Core's default outlined width remains 1dp; verify expected 55.5dp height, theme/contrast, large text and unchanged actions under new exact-head CI/review.
- [ ] Owner physical-device QA (light/dark, compact width, text scale, selected state and Remove Set) and separately explicit `Go merge`.


**No merge or deployment authorized by implementation Go.**
