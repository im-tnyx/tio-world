# TNYX-204 — Manual Meal Diary card overflow and Quick Edit

**Status:** Ready for review\
**Primary owner:** `apps/features/nutrition`\
**Affected platforms:** Flutter phone app (`apps/features/nutrition`, consumed by `apps/app`)

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice; approved product-visible UI/UX change\
**Approval status:** Approved\
**Approval evidence:** Owner explicitly requested TNYX-204 implementation on 2026-09-12, supplied the corrected implementation brief, selected Option C for time, and supplied two card reference images locking the near-edge top-right overflow geometry. The corrected richer card direction supersedes the older compact single-row direction.\
**Approved product/UI/data-shape boundaries:** Replace the current compact read-only Meal Diary card composition with a richer leading-media/content/overflow composition; use a truthful fallback icon when no runtime meal image exists; expose only a working `Edit` action; make card tap and overflow `Edit` open the same Quick Add edit flow; preserve section headers/totals while adding the owner-specified existing `apple.svg` calorie glyph and supplied protein glyph to header totals only; keep selected-date behavior intact; support light, dark, and compact layouts.\
**Explicit non-changes:** No Supabase schema, migration, RLS, RPC, Storage, or live-data mutation; no meal media persistence; no detailed Meal Editor; no delete/move/duplicate actions; no invented disabled menu items; no new public Core API unless implementation evidence proves it unavoidable; no unrelated TNYX-203 changes.

## Active Handoff

**Planning owner:** Codex `/root`\
**Implementation owner:** Codex `/root`\
**Review owner:** Unassigned\
**Implementation ownership state:** Complete\
**Ownership transition:** Not applicable\
**Repository state last verified:** 2026-09-12, after creating the task branch from clean synchronized `main`\
**Branch:** `tnyx/tnyx-204-n20c-2-manual-meal-diary-card-overflow-quick-edit-activation`\
**Implementation SHA:** `e92a45b8d0de616dbc46f2055476172b8e831351`\
**Observed working-tree state:** Clean after the implementation commit; accidental package lockfile drift was removed before publication.\
**Observed committed files:** See Final Handoff changed-file groups below.\
**PR / tracker:** GitHub Draft PR [#263](https://github.com/im-tnyx/tio-world/pull/263) is open; Linear `TNYX-204` remains `In Progress` until exact-head CI passes; dependency `TNYX-203` is `Done` and GitHub PR `#262` is merged.\
**Current implementation state:** Complete. The owner-approved rich card, header glyphs, anchored Edit-only popup, Quick Add edit mode, canonical read/update flow, conflict/ambiguous-outcome handling, affected-date invalidation, and final 40dp fallback-icon polish are implemented and locally validated.\
**Relevant execution surface:** Meal Diary selected-day cards, Quick Add editor, canonical `MealLogRepository.readById`/`updateManual`, and existing Core `TioAnchoredPopup`\
**Validation completed at SHA:** `e92a45b8d0de616dbc46f2055476172b8e831351` — `apps/core` analyze + 293 tests, `apps/features/nutrition` analyze + 676 tests, `apps/app` analyze + 319 tests, `git diff --check`\
**Validation remaining:** Exact-head CI after publication; workspace `melos` remains unavailable as recorded below\
**Current blocker:** Workspace `melos` is unavailable in the current shell. Full per-package validation was run instead for every affected/consuming package. This is a local tooling limitation, not a TNYX-204 defect.\
**Open review finding IDs:** None. TNYX-204-R5 is an accepted out-of-scope data limitation, not an implementation blocker.\
**Next exact action:** Push this handoff update, verify exact-head Draft PR CI, then reconcile Linear `TNYX-204` to `In Review`.

## Global UI / Design-System Guardrail

The validated design-system task and `apps/core/lib/src/theme/README.md` were read before UI planning. The implementation will consume `package:tio_core/core.dart`, reuse `TioCard`, `TioAnchoredPopup`, `TioEditorSheet`, `TioButton`, runtime semantic colors, and governed geometry. This feature-owned card composition does not justify a new Core component or feature token catalog.

## 1. Discovery

### User Outcome

Manual Meal Diary entries remain readable on compact widths, expose a discoverable vertical overflow action, and can be corrected through a truthful Quick Edit flow without creating a second persistence path.

### Success Criteria

- Each existing manual MealLog card renders a visually secondary centered fallback food icon in its fixed leading media area, a flexible content area, and a top-trailing vertical `more_vert` action without horizontal overflow.
- The visible overflow glyph sits near the card's extreme top-right edge like the supplied reference, while its accessible hit target remains at least the governed `TioSize.dp48` without adding arbitrary padding.
- A real meal image is rendered only if an existing runtime contract supplies one. The audited current contract does not, so this slice renders the governed fallback only.
- Only `Edit` is shown in the anchored popup, and it works.
- Card tap and popup `Edit` resolve the same canonical row through `readById(id)` and open the same editor state.
- Create mode remains `Quick Add` / `Log Meal`; edit mode becomes `Quick Edit` / `Save Changes`.
- Update preserves canonical identity, manual mode/provenance, note, archived source category when unchanged, and uses `expectedRevision` through `updateManual`.
- Category choices remain active-only, while an archived current category remains selectable as the unchanged current value.
- Conflict reloads the latest canonical row, tells the user, and requires deliberate reapplication. An ambiguous outcome freezes the exact attempted facts and retries/reconciles with the same expected revision.
- A successful date/category/time edit refreshes both old and new local-date reads without changing the user's selected date.
- Existing Meal Diary section headings, totals, preference behavior, loading/empty/error states, and visual themes remain intact.

### Scope

- Meal Diary history card composition and its interaction callback.
- Feature-owned `MealLogActionsPopup` built on Core `TioAnchoredPopup`.
- Quick Add editor create/edit mode support and the smallest feature-owned edit controller/state needed for canonical update semantics.
- Page/provider invalidation wiring and focused tests.
- TNYX-204 task/tracker reconciliation and current Meal Diary documentation after behavior is validated.

### Non-Goals

- Detailed itemized meal editing, AI/photo/search capture, delete, move, duplicate, archive, or arbitrary contextual actions.
- Meal image acquisition, URL/storage fields, upload UI, or placeholder data represented as real media.
- Supabase changes or a parallel repository contract.
- Redesigning Meal Diary headers, totals, calendar, Add Food sheet, or navigation.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: `apps/features/nutrition/lib/src/meal_diary/presentation/widgets/meal_diary_history_view.dart`, `meal_diary_history_providers.dart`, `meal_diary_page.dart`, Quick Add editor/controller source, manual update repository contract and Supabase adapter, `apps/shared/lib/src/nutrition/meal_log_entry.dart`, `docs/screens/meal-diary.md`, Core theme/component guidance, and existing Meal Category glyph usage.
- Existing pattern to follow: `TioAnchoredPopup` for a floating anchored action card; `TioCard.onTap` for the card action; canonical repository reads/updates rather than reconstructing durable state from the lossy Diary read model.
- Tests or validation already present: Meal Diary history provider/widget/page tests, Quick Add editor/controller tests, manual update repository contract/adapter tests, and Core anchored-popup tests. Exact additions are selected during implementation.
- Current time source: `MealDiaryEntryReadModel.loggedLocalDateTime`, reconstructed from `consumedAt.toUtc() + consumedUtcOffsetMinutes`; timezone-id-only rows omit time rather than guessing.
- Current time geometry: the time label is the first child of the card's outer `Row`, before the flexible detail column. The approved leading media area necessarily displaces this slot.
- Current media truth: canonical `MealLogEntry`, `NutritionSnapshot`, Meal Diary read model, and the manual MealLog migration contain no meal image/media reference. `captureSource.photo` is provenance only. Therefore Quick Add/manual entries cannot truthfully show a real image in this slice.
- Available governed fallback: Nutrition already maps unknown/custom meal categories to `Icons.restaurant_outlined`; using that existing food glyph with semantic theme colors avoids inventing an asset or media contract.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Richer card supersedes Linear's older compact single-row direction | Approved | Explicit corrected owner brief is newer and more specific | Owner |
| No real meal image in TNYX-204 | Made | Runtime/domain/database contract has no media reference; provenance is not an image | Source truth |
| Use `Icons.restaurant_outlined` as fallback | Approved | Existing Nutrition fallback glyph plus semantic colors is the narrowest governed choice; the final owner polish keeps it centered and secondary at 40dp | Owner |
| Time at the bottom of the fixed leading media/icon area | Approved | It keeps right-side content clean and overlaps the media area, so time alone does not increase card height. The same slot can later use a readable chip/scrim over a real runtime image without changing layout ownership. | Owner |
| Earlier options A/B | Superseded | Title-below and nutrition-trailing placements were explicitly rejected by the owner | Owner |
| Overflow glyph near the extreme top-right card edge | Approved | Supplied references keep the visible dots close to the edge; a governed 48dp hit target must not pull the glyph inward | Owner |
| Screen inset, card inset and card gap all stay `TioSpacing.lg` (16) | Approved | Owner decided 2026-09-12 after the conflict below was surfaced. This supersedes TNYX-115's earlier `TioSpacing.md` (12) horizontal card-padding refinement, which was written against the superseded compact single-row card and its `EdgeInsets.all(TioSpacing.lg)` card padding. The richer card carries no card padding at all; its content column owns the inset. | Owner |
| Macro total glyphs in section headers only | Approved | Render existing Core `apple.svg` before calories and the owner-supplied protein SVG before grams; card detail rows stay text-only | Owner |
| Fallback food glyph polish | Approved | Keep the approved 120dp media/card geometry unchanged and reduce the centered muted `Icons.restaurant_outlined` from 48dp to governed `TioSize.dp40` so it remains visually secondary | Owner |

## 4. Architecture Design

### Chosen Approach

Keep display composition in Meal Diary presentation, with time occupying the bottom of the fixed leading media/icon stack instead of adding a new vertical row. Add a feature-owned anchored `MealLogActionsPopup`, and extend the existing Quick Add editor into explicit create/edit modes. The page always calls `readById(id)` immediately before edit so the lossy card model never becomes update truth. A feature controller coordinates `updateManual`, conflict reload/reapply, ambiguous retry/reconcile, and date invalidation while reusing existing repository contracts.

### Ownership and Data Flow

```text
Meal Diary card or popup Edit
  -> MealDiaryPage edit coordinator
  -> MealLogRepository.readById(id)
  -> Quick Add editor in edit mode
  -> feature edit controller
  -> MealLogRepository.updateManual(expectedRevision)
  -> invalidate old and new MealLogLocalDate providers
```

### Alternative Rejected

- Expanding `MealDiaryEntryReadModel` into an editable persistence snapshot: rejected because it would duplicate canonical row state and still risks stale updates.
- Adding image/media fields or a placeholder URL: rejected because TNYX-204 explicitly forbids schema/media persistence and the runtime contract has no image truth.
- Rendering unavailable overflow actions: rejected because visible dead actions misrepresent capability.
- Building a bespoke popup with `MenuAnchor`: rejected because Core already owns the anchored popup behavior.

### Failure and Accessibility States

- The whole card and `Edit` menu item expose clear button semantics and reach the same action.
- Popup dismiss remains accessible through Core semantics; compact width must not clip the action.
- Not-found closes or refuses editing with a truthful message.
- Conflict shows the latest canonical values and requires deliberate reapplication; user input is not silently written over newer data.
- Outcome-unknown keeps the attempted update facts immutable for a safe same-revision retry/reconciliation.
- Save remains disabled/in-flight-safe according to the editor/controller state; errors do not fabricate success or change the selected date.

## 5. Implementation Plan

- [x] Obtain the owner time-placement decision and update this brief: Option C approved.
- [x] Move Linear TNYX-204 to `In Progress` and replace/annotate the stale single-row card direction.
- [x] Add the richer responsive card and feature-owned `MealLogActionsPopup` using governed Core contracts.
- [x] Route card tap and popup `Edit` to one canonical edit entry point.
- [x] Add Quick Add create/edit presentation state and canonical update controller behavior.
- [x] Invalidate old/new date reads while preserving the selected date.
- [x] Add focused tests for geometry, actions, create/edit copy, canonical read, preservation, conflict, ambiguous retry, and date invalidation.
- [x] Run focused and applicable Flutter validation, review the diff, and update task/docs/tracker handoff.
- [x] Create a Draft PR only after the implementation and validation handoff is accurate: [#263](https://github.com/im-tnyx/tio-world/pull/263).

## 6. Quality Review

### Validation Run

```text
cd apps/features/nutrition
flutter analyze   -> No issues found! (32.5s)
flutter test      -> All tests passed (676 tests)
```

Measured after the final geometry correction at compact viewports, with light
and dark both exercised by the suite:

```text
card/media height   120dp fixed; time scrim remains inside the media bounds
fallback glyph       40dp centered, muted semantic color
overflow glyph       12dp visible inset with a governed 48dp target
section summary      flush with the content edge; divider absorbs the middle
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| TNYX-204-D1 | P1 | Resolved | Time placement was not uniquely determined after introducing the approved leading media slot | `34c34893b8c164561607ac652df534fa79f2f330` | Owner approved Option C: bottom overlay inside the fixed media/icon area |
| TNYX-204-R1 | P1 | Resolved | Time rendered as an opaque rounded pill, reading as a separate control rather than part of the media surface | working tree | Replaced with a bottom-up `mediaBackground` gradient scrim spanning the full media width; same slot works unchanged once a real image exists |
| TNYX-204-R2 | P1 | Resolved | A short section title under-used its loose flex share, so the slack landed after the summary and pushed the trailing cluster off the content edge | working tree | Title and rule now share one tight `Expanded` region; the rule absorbs the middle and the summary stays intrinsic and flush right |
| TNYX-204-R3 | P2 | Resolved | Overflow glyph sat 16dp from the card top and 12dp from the end, reading as inset rather than cornered | working tree | Target pulled over the card's own top padding; the visible glyph now keeps one 12dp inset from both card edges with the 48dp target intact |
| TNYX-204-R4 | P2 | Resolved | Fallback glyph used the `nutrition` domain accent and dominated the media slot | working tree | Uses `textSecondary`; final owner polish reduces the centered glyph from 48dp to governed `TioSize.dp40` without changing the 120dp media/card geometry |
| TNYX-204-R5 | P2 | Accepted limitation | Owner's reference card shows a `Quantity` detail row, rendered only when a quantity exists | working tree | Reference reads `meal.servingSize`. Tio has no equivalent: no quantity/serving/portion field on `MealLogEntry`, `NutritionSnapshot`, `ManualMealLogCreate`, the Quick Add capture form, or `MealDiaryEntryReadModel`. The row is omitted rather than faked, which is also the owner's stated rule. A future field needs separate approval |
| TNYX-204-R6 | P1 | Resolved | Card composition had drifted from the owner reference: an inset 80dp media tile with all-round corners read as a nested mini-card | working tree | Reference located at `Tnyx-hub/apps/flutter/features/nutrition/lib/src/presentation/meal_diary/widgets/nutrition_meal_card.dart`. Card padding is now zero and the 120dp media fills the card's own leading corner with only that side rounded, matching the reference's flush media and fixed 120dp card height |
| TNYX-204-R7 | P1 | Resolved | A short section title left slack that kept the trailing summary off the content edge, and flex ratios traded that for a gap before the rule | working tree | Title now takes its natural width, capped by `LayoutBuilder` at the inner width less the rule's gap, so the rule absorbs the middle and shortens first while a maximum-length category name ellipsizes instead of overflowing |
| TNYX-204-R8 | P1 | Resolved | The overflow popup opened far from its control on trailing-edge anchors | working tree | `TioAnchoredPopup` fitted a leading-aligned card against `maximumWidth` rather than its actual width, which dragged a trailing anchor's card ~111dp off it. Core now pins the card's trailing edge to the control's when leading alignment would need clamping. Leading-side anchors are unchanged; README and focused Core placement tests added |
| TNYX-204-R9 | P2 | Resolved | Card lived as a private class inside the history view | working tree | Extracted to feature-owned `MealDiaryMealCard`, matching the reference repo's own widget-per-card layout. It takes formatted strings and emits actions, so it holds no read model, preferences, or formatting policy |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/tnyx-204-manual-meal-diary-card-overflow-quick-edit.md`, `docs/screens/meal-diary.md` — scope, decisions, runtime truth, validation and handoff.
- `apps/core/assets/svg_icon/apple.svg`, `apps/core/assets/svg_icon/ic_protine.svg`, `apps/core/lib/src/theme/tokens/primitive/tio_size.dart` — governed header assets and 120dp geometry token.
- `apps/core/lib/src/ui/components/pickers/tio_anchored_popup.dart`, `apps/core/lib/src/theme/README.md`, `apps/core/test/ui/tio_anchored_popup_placement_test.dart` — trailing-edge anchored popup placement contract and tests.
- `apps/features/nutrition/lib/src/meal_diary/**` — rich card, Edit-only action popup and canonical Quick Edit routing/date invalidation.
- `apps/features/nutrition/lib/src/meal_logging/**` — create/edit editor modes and optimistic edit controller.
- `apps/features/nutrition/lib/src/domain/repositories/manual_meal_log_update_repository.dart` — explicit capability dispatch required by the activated update flow.
- `apps/features/nutrition/test/meal_diary/**`, `apps/features/nutrition/test/meal_logging/**` — geometry, action, canonical edit, conflict and retry coverage.

### Actual Behavior

Manual MealLog cards now render the approved 120dp leading media composition, time scrim, clean nutrition details and near-edge overflow. The fallback icon is centered at 40dp and remains visually secondary. Card tap and the popup's only action, `Edit`, both open the reused editor as `Quick Edit`; `Save Changes` updates the same canonical ID with optimistic revision safety and refreshes affected Diary dates without moving the selected date.

### Known Limitations

- The owner-provided direction is verbal; no reference image is attached to TNYX-204 in Linear.
- Real meal media remains unavailable in the current runtime contract; this slice intentionally uses the fallback icon.
- No quantity/serving field exists anywhere in the nutrition runtime contract, so the reference's `Quantity` row is not rendered. See TNYX-204-R5.

### Final Status

`REVIEW`
