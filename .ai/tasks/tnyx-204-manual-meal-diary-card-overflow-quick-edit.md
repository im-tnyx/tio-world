# TNYX-204 — Manual Meal Diary card overflow and Quick Edit

**Status:** Final accessibility implementation validated; non-self-referential PR handoff reconciliation in progress\
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
**Repository state last verified:** 2026-09-13, clean at required starting PR head `5c8ab420136408ecba6ddec5302bfb74be52f5f8` after a fresh remote fetch\
**Branch:** `tnyx/tnyx-204-n20c-2-manual-meal-diary-card-overflow-quick-edit-activation`\
**Validated implementation SHA before this accessibility pass:** `2d64ae88c8c52f2a05bbd1a9a585b814baa78cf2`\
**Observed working-tree state:** Clean after accessibility implementation commit `687733c0`; this task brief is the only docs-only reconciliation change that follows it.\
**Observed committed files:** See Final Handoff changed-file groups below.\
**PR / tracker:** GitHub Draft PR [#263](https://github.com/im-tnyx/tio-world/pull/263) is open; Linear `TNYX-204` is `In Review` (confirmed live 2026-09-13, not merely "will move to"); dependency `TNYX-203` is `Done` and GitHub PR `#262` is merged. Current authoritative relation is `TNYX-204` **blocks `TNYX-209`** (`TNYX-209` then gates `TNYX-205`) — the PR body's earlier "blocks TNYX-205" note was stale and is corrected in this pass.\
**Current implementation state:** The previously validated runtime behavior remains intact. This owner-authorized pass only removes the duplicate meal-card tap semantics node, adds focused semantic-action regression coverage, corrects the stale history-view class comment, and reconciles handoff metadata without changing approved card geometry or product behavior.\
**Relevant execution surface:** Meal Diary selected-day cards/section headers, Meal Diary Settings, `MealDiaryDisplayPreferences` model/repository/controller, Quick Add editor, canonical `MealLogRepository.readById`/`updateManual`, existing Core `TioAnchoredPopup`, and the Add Food sheet route\
**Starting PR head SHA for this pass:** `5c8ab420136408ecba6ddec5302bfb74be52f5f8` (7 commits ahead of `main`, 0 behind; pushed; exact-head GitHub CI `Analyze and test` was `completed/success`)\
**Validated implementation SHA for this pass:** `687733c06307700bc19e2c3bec4dd1856b10d0ec` — local required validation passed, and exact-head GitHub Flutter CI run `34738315964` completed successfully.\
**Current PR head after handoff reconciliation:** Read from live GitHub PR [#263](https://github.com/im-tnyx/tio-world/pull/263). This tracked brief intentionally does not predict or duplicate the SHA of the docs-only commit that contains this metadata; the PR body/checks are authoritative for that final publication head.\
**Validation remaining:** No source validation remains. The final docs-only reconciliation head must still be pushed and receive exact-head Flutter CI SUCCESS before owner merge review; that live-only outcome belongs in PR metadata rather than another self-referential tracked commit.\
**Current blocker:** None in the implementation. Owner merge review remains gated on the live final PR head and its exact-head CI.\
**Open review finding IDs:** None. TNYX-204-RF5 is resolved at `687733c0`. TNYX-204-R5 remains an accepted out-of-scope data limitation, not an implementation blocker. TNYX-208 stays canceled/absorbed and was not reopened. TNYX-209 was not started in this pass.\
**Current sequence (owner lock, confirmed live 2026-09-13):** `TNYX-204 → TNYX-209 (N20C-3 Quick Add nutrition amount range & precision policy) → TNYX-205 (N11A) → TNYX-206 (N3A) → TNYX-207 (N5D)`.\
**Next exact action:** After the live final PR head reports exact-head CI SUCCESS, stop for the owner's merge decision. Do not merge here and do not start TNYX-209.

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
| One `showMealSectionNutrition` switch controls the whole trailing Calories + Protein section-header group; no separate per-nutrient toggles | Approved | Owner explicitly folded the previously planned N14B section-header visibility preference into this open PR on 2026-09-12, locking one switch rather than two | Owner |
| Extend existing `MealDiaryDisplayPreferences`/repository/controller; no second preference store, no schema-version bump | Approved | TNYX-198's canonical model/repository/controller already own device-local Meal Diary presentation state; the new field is additive and the existing `showMealTimes`/`mealNotesEnabled`/`showMealNotePreview` shape/version-1 contract does not need to change to add it safely | Owner / Source truth |
| Section title 14px `labelLarge` → 16px `titleMedium` (weight explicitly kept w700); real `TioSpacing.sm` gap between title and divider | Approved | Owner device review found the title visually weak relative to the card/header composition and found the divider touching the title directly; fix stays local to this one Text/Row composition, no global typography or token change | Owner |

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
- [x] Remove the duplicate whole-card tap semantics node without changing card geometry or pointer behavior.
- [x] Add focused semantics-tree and semantic-action regression coverage proving exactly two independent actions: card Edit and `Meal actions`.
- [x] Re-run affected/consuming package validation and record the concrete implementation SHA without predicting the docs-only reconciliation commit; final publication SHA/CI remain live PR metadata.

## 6. Quality Review

### Validation Run

```text
cd apps/features/nutrition
flutter analyze   -> No issues found! (32.5s)
flutter test      -> All tests passed (676 tests)
```

Final accessibility pass, using the verified installed Flutter 3.44.6 SDK
through its tool snapshot because the local `flutter.bat` wrapper was blocked
on its machine-local lock:

```text
focused semantics regression test                          -> PASS
cd apps/features/nutrition && dart analyze lib test        -> No issues found!
cd apps/features/nutrition && flutter test --no-pub        -> All tests passed (695 tests)
cd apps/app && dart analyze lib test                       -> No issues found!
cd apps/app && flutter test --no-pub                       -> All tests passed (319 tests)
GitHub Flutter CI at implementation SHA 687733c0           -> SUCCESS (run 34738315964)
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
| TNYX-204-RF1 | P2 | Resolved | If a Quick Edit sheet closed with no result, the Diary skipped invalidating the original date even when the underlying write may already be durable (an ambiguous transport outcome) | PR #263 review at `dccaf341` | `meal_diary_page.dart:_openQuickEdit` now always invalidates the original date once the sheet closes and the page is still mounted, before branching on whether it returned an updated entry. Fresh inspection also found the literal reviewer scenario ("user dismisses the uncertain sheet") is already prevented by pre-existing `PopScope(canPop: !_draftLocked)` + `TioEditorSheet.canDismiss: !_draftLocked` — outcome-unknown genuinely cannot be dismissed. The real reachable path is retry-then-conflict (the ambiguous write lands, the same-facts retry then conflicts against the revision it already advanced, conflict is not a locked state, and the reader can dismiss without reapplying); the fix and its regression test target that path |
| TNYX-204-RF2 | P2 | Resolved | Date-move invalidation was implemented but had no assertion proving both the original and destination dates actually refresh | PR #263 review at `dccaf341` | Added a regression test that moves a real entry's consumed date through the actual `CupertinoDatePicker`/footer control into a different day and, using an explicitly held `ProviderContainer` listener on the destination date (an `autoDispose` family provider, so an unwatched instance would refetch fresh regardless of whether the code path exists), proves a second read happens only because of the explicit invalidate |
| TNYX-204-RF3 | P2 | Resolved | Owner device review: the Add Food sheet's bottom system nav area showed a different background than the sheet, while Quick Add's matching area was correct | PR #263 review-fix pass | `showMealDiaryAddFoodSheet`'s outer `SafeArea` insets content above the system nav area before `TioSheet`'s own Material paints, leaving that gap to the transparent modal route background. `TioEditorSheet` avoids this by painting its Material first and keeping `SafeArea` inside it. Fixed locally in `add_food_sheet.dart` only: a `ColoredBox(color: context.tioColors.surface)` now sits behind the existing `SafeArea`, filling the gap with the same governed role `TioSheet` paints. No Core change. Verified the added regression test actually fails without the fix (stashed and reran) before restoring it |
| TNYX-204-ME1 | N/A | Implemented | Owner-approved micro-extension: fold N14B section-header nutrition visibility into this still-open PR | Linear 2026-09-12 | Added one boolean, `showMealSectionNutrition` (default true), to the existing `MealDiaryDisplayPreferences` model/repository/controller — no second preference store. `_Section`'s `hasSummary` now gates on `preferences.showMealSectionNutrition && (calories or protein known)`, so OFF removes the whole trailing group and the divider/title reclaim the width; individual `MealDiaryMealCard` calories/protein are untouched. One governed `Show section nutrition` toggle added to Meal Diary Settings, reusing the existing feature-owned toggle row — no new Core component, no separate Calories/Protein rows |
| TNYX-204-RF4 | P3 | Resolved | Preference decoder treated an explicit JSON `null` for `showMealSectionNutrition` the same as the key being absent, so a malformed `"showMealSectionNutrition": null` payload silently hydrated as the legacy shape (defaulting only that field to true) instead of failing closed | Final review-fix pass at `439fb903` | `read()` now checks `decoded.containsKey('showMealSectionNutrition')` before inspecting the raw value, so a genuinely absent key still defaults true (unchanged legacy behavior) while a present key — bool or otherwise, including explicit `null` — is validated as a real bool or the whole payload fails closed to full defaults, consistent with the other three fields. No schema-version change, no second preference key |
| TNYX-204-ME2 | N/A | Implemented | Owner-approved final polish: Meal Diary section title was visually weak (14px `labelLarge`) and touched the divider directly (no real gap existed despite a `TioSpacing.sm` width reservation in the layout math) | Owner device review 2026-09-13 | Title now uses `textTheme.titleMedium` (governed 16px) with `fontWeight: TioFontWeight.w700` preserved explicitly (titleMedium's own default is w600). A real `const SizedBox(width: TioSpacing.sm)` now sits between the title and the divider; the existing `ConstrainedBox(maxWidth: constraints.maxWidth - TioSpacing.sm)` reservation is unchanged and now correctly corresponds 1:1 to that one real gap widget rather than reserving space nothing consumed. Verified the divider stays a positive width and no overflow occurs at 320dp/390dp, a 24-character (policy-max) category name still ellipsizes safely, and the ON/OFF trailing-summary flush-right/reclaimed-width behavior from TNYX-204-ME1 is unaffected. Calorie/protein header icon/text sizes, card typography, and category display names are untouched |

| TNYX-204-RF5 | P2 | Resolved | The actionable Meal Diary card exposed the same card tap through both the outer `Semantics.onTap` and `TioCard`'s internal `InkWell`, so assistive technology received a duplicate whole-card action beside the intended `Meal actions` action | Final accessibility audit at starting head `5c8ab420` | The feature-owned card now follows the existing `TioSelectableCard` semantics-ownership precedent: one outer node owns the card action and deliberately represents the visible meal/time/nutrition/note text, the internal tappable visual subtree is excluded, and `Meal actions` remains a separate sibling node. A focused `tester.ensureSemantics()` test proves exactly two tap nodes, semantic dispatch isolation, and preserved physical taps. No Core or geometry change |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/tnyx-204-manual-meal-diary-card-overflow-quick-edit.md`, `docs/screens/meal-diary.md` — scope, decisions, runtime truth, validation and handoff.
- `apps/core/assets/svg_icon/apple.svg`, `apps/core/assets/svg_icon/ic_protine.svg`, `apps/core/lib/src/theme/tokens/primitive/tio_size.dart` — governed header assets and 120dp geometry token.
- `apps/core/lib/src/ui/components/pickers/tio_anchored_popup.dart`, `apps/core/lib/src/theme/README.md`, `apps/core/test/ui/tio_anchored_popup_placement_test.dart` — trailing-edge anchored popup placement contract and tests.
- `apps/features/nutrition/lib/src/meal_diary/**` — rich card, Edit-only action popup and canonical Quick Edit routing/date invalidation.
- `apps/features/nutrition/lib/src/meal_logging/**` — create/edit editor modes and optimistic edit controller.
- `apps/features/nutrition/lib/src/domain/repositories/manual_meal_log_update_repository.dart` — explicit capability dispatch required by the activated update flow.
- `apps/features/nutrition/test/meal_diary/**`, `apps/features/nutrition/test/meal_logging/**` — geometry, action, canonical edit, conflict and retry coverage.

Review-fix pass (this bounded follow-up commit only):

- `apps/features/nutrition/lib/src/meal_diary/presentation/pages/meal_diary_page.dart` — `_openQuickEdit` always invalidates the original date once the sheet closes and mounted, before branching on the result (TNYX-204-RF1).
- `apps/features/nutrition/lib/src/meal_logging/presentation/widgets/add_food_sheet.dart` — `ColoredBox(color: context.tioColors.surface)` behind the existing `SafeArea` so the sheet's surface visually continues through the bottom system inset (TNYX-204-RF3).
- `apps/features/nutrition/test/meal_logging/quick_add_edit_flow_test.dart` — two new widget tests: ambiguous-outcome-then-conflict dismissal still refreshes the original date (TNYX-204-RF1); a genuine cross-date move invalidates both dates, proven against a held `ProviderContainer` listener rather than relying on `autoDispose` GC (TNYX-204-RF2).
- `apps/features/nutrition/test/meal_logging/meal_diary_add_food_flow_test.dart` — one new widget test asserting the bottom-inset fill color/extent (TNYX-204-RF3); confirmed to fail without the fix by temporarily stashing it and rerunning.
- No `apps/core` files changed in this pass.

Micro-extension (section nutrition visibility, this bounded follow-up commit only):

- `apps/features/nutrition/lib/src/meal_diary/domain/models/meal_diary_display_preferences.dart` — adds `showMealSectionNutrition` (default true) to the constructor, field, `copyWith`, equality, hashCode, `toString`.
- `apps/features/nutrition/lib/src/meal_diary/data/shared_preferences_meal_diary_display_preferences_repository.dart` — read() treats an absent `showMealSectionNutrition` key as the pre-existing legacy shape (defaults true) and only fails closed when the key is present with the wrong type; write() persists the new boolean; schema stays version 1 (additive, backward-compatible).
- `apps/features/nutrition/lib/src/meal_diary/presentation/controllers/meal_diary_display_preferences_controller.dart` — `setShowMealSectionNutrition(bool)` reuses the existing serialized/optimistic `_select`/`_persist` write path.
- `apps/features/nutrition/lib/src/meal_diary/presentation/pages/meal_diary_settings_page.dart` — one `Show section nutrition` toggle row, same feature-owned composition as the other three rows.
- `apps/features/nutrition/lib/src/meal_diary/presentation/widgets/meal_diary_history_view.dart` — `_Section`'s `hasSummary` now requires `preferences.showMealSectionNutrition` in addition to a known calorie/protein aggregate.
- `apps/features/nutrition/test/meal_diary/data/meal_diary_display_preferences_repository_test.dart`, `.../presentation/meal_diary_display_preferences_controller_test.dart`, `.../presentation/meal_diary_display_preferences_page_test.dart`, `.../meal_diary_history_view_test.dart` — default/round-trip/backward-compat/malformed-type coverage, setter + failed-write rollback, one-switch Settings UI + toggle behavior, and header ON (both/calories-only/protein-only)/OFF rendering with individual-card nutrition proven unchanged.
- `docs/screens/meal-diary.md`, `docs/screens/meal-diary-display-preferences.md` — document the new preference and its section-header-only boundary.
- No `apps/core` files changed in this pass.

Final review-fix pass (this bounded follow-up commit only):

- `apps/features/nutrition/lib/src/meal_diary/data/shared_preferences_meal_diary_display_preferences_repository.dart` — `read()` now distinguishes an absent `showMealSectionNutrition` key (legacy shape, defaults true) from a present key of any kind including explicit JSON `null` (must be a real bool or the payload fails closed); stale "three values" doc comment corrected to "four" (TNYX-204-RF4).
- `apps/features/nutrition/lib/src/meal_diary/presentation/widgets/meal_diary_history_view.dart` — section title moved from `textTheme.labelLarge` (14px) to `textTheme.titleMedium` (16px, weight explicitly kept at w700); a real `SizedBox(width: TioSpacing.sm)` now sits between the title and the divider, with the existing `ConstrainedBox` width reservation unchanged since it now maps 1:1 to that one real gap (TNYX-204-ME2).
- `apps/features/nutrition/test/meal_diary/data/meal_diary_display_preferences_repository_test.dart` — explicit-JSON-`null` regression test, distinct from the existing missing-key test.
- `apps/features/nutrition/test/meal_diary/meal_diary_history_view_test.dart` — new `section header title polish` group: 16px/w700 style assertion, exact `TioSpacing.sm` gap measurement, positive divider width + no overflow at 320dp and 390dp, and a policy-max 24-character category name still ellipsizing safely. Verified all title/gap assertions fail without the fix (temporarily reverted, reran, restored).
- No `apps/core` files changed in this pass.

Final accessibility pass (this bounded follow-up commit only):

- `apps/features/nutrition/lib/src/meal_diary/presentation/widgets/meal_diary_meal_card.dart` — assigns the whole-card accessibility action to one feature-owned semantics node, deliberately represents the excluded visible subtree in its label, and keeps `Meal actions` as the separate top-right sibling without moving it.
- `apps/features/nutrition/lib/src/meal_diary/presentation/widgets/meal_diary_history_view.dart` — corrects the stale TNYX-199 read-only class comment to the current Quick Edit callback boundary.
- `apps/features/nutrition/test/meal_diary/meal_diary_history_view_test.dart` — proves the card and overflow are exactly two independent tap semantics nodes; semantic card activation edits once, semantic overflow activation only opens the popup, and physical card/overflow taps remain intact.
- No `apps/core`, `apps/app`, Supabase, schema, persistence, or approved card-geometry file changed in this pass.

### Actual Behavior

Manual MealLog cards now render the approved 120dp leading media composition, time scrim, clean nutrition details and near-edge overflow. The fallback icon is centered at 40dp and remains visually secondary. Card tap and the popup's only action, `Edit`, both open the reused editor as `Quick Edit`; `Save Changes` updates the same canonical ID with optimistic revision safety and refreshes affected Diary dates without moving the selected date. Meal Diary Settings now also exposes one `Show section nutrition` toggle; turning it off removes the section header's trailing Calories + Protein group (divider/title reclaim the width) while leaving individual card calories/protein untouched, and an older stored preference payload without the new field still hydrates correctly with the new field defaulting to ON — while a payload carrying an explicit `null` for that field now correctly fails closed instead of silently passing. The Meal Diary section title (e.g. "Lunch") now renders at the governed 16px heading size with a real 8dp gap before the divider, which no longer touches the title.

The card now exposes one accessible whole-card Edit action plus one separate
`Meal actions` action. Its accessible label includes the visible meal name,
time, nutrition details and note state; the internal InkWell no longer creates
a duplicate action. Pointer behavior and all approved geometry remain intact.

### Known Limitations

- The owner-provided direction is verbal; no reference image is attached to TNYX-204 in Linear.
- Real meal media remains unavailable in the current runtime contract; this slice intentionally uses the fallback icon.
- No quantity/serving field exists anywhere in the nutrition runtime contract, so the reference's `Quantity` row is not rendered. See TNYX-204-R5.

### Final Status

`REVIEW` — accessibility implementation is validated at `687733c0`; live PR metadata owns the final docs-reconciled head and exact-head CI gate before the owner's merge decision.
