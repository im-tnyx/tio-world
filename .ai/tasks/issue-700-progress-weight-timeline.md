# Progress Weight Timeline — #700

**Status:** In review (PR #701 against main; do not merge without explicit owner instruction).
**Approval:** 2026-10-26 explicit owner message with two image references approving a visual Timeline refresh.
**Implementation owner:** GitHub `im-tnyx`; no source edits by the separate reviewer account.
**Scope:** Progress-owned Flutter presentation only, month grouping, weight/change chips, honest Today/New low, optional persisted note. Source remains A1 owner-scoped paginated History.
**Base:** `main@8fabf524a67bf13131225974d4d01288a6588b41` (merged PR #698), reconciled at `99328c88bd412ed851394ea7bfe9b3293a9e4ac8`. Child `feat/issue-700-progress-weight-timeline`.
**Trackers:** GitHub #700, Linear TNYX-119 In Progress. Root/feature AGENTS, canonical Progress docs/Core README and repo workflow read.

## Discovery
- Current `ProgressWeightPage` uses one flat `TioCard` per History entry; A1 history is newest-first stable-id and pages at 30. `ProgressWeightDashboardReader` retains future-dated rows in History but excludes them from eligible Current/chart. The user's reference has date/status column, prominent kg, delta badges, month sections, Today/New low.
- Existing UI Core `TioCard`/Tio colors/sizing suitable; screenshot's purple color theme and unverified 'Trend' numbers must not be copied.

## Architecture/decisions
- New presentation projection uses only currently loaded owner-scoped History, captured UTC time and `hasMore`. For each entry show signed difference to immediately preceding older actual instant; same-instant and missing previous display no delta.
- 'New low' requires complete History page coverage and strict lower weight than all older eligible entries; never claim all-time record while older pages exist. Today requires measured date's local day match and no future.
- Month headings based on measurement's local month/year, preserve actual order/IDs; Tio theme colors for attention, and benefit/harm color only when canonical Lose/Gain direction is known.
- Rejected: fabricating Trend smoothing, new backend queries/schema, modifying Core or Nutrition visuals, duplicate weight source.
- Keep PR #698's fixed Log Weight, compact chart and #695's editor sheet untouched; no Edit/Delete, Photos, Supabase or extra features.
- Source/test/doc only, tracked isolated branch. Windows checkout/Flutter SDK not available from current connected tools.

## Validation and gates
Focused projection tests for same-time/missing comparison, future Today, partial history low, plus widget checks for month groups, note, global lb, genuine New low. Require exact-HEAD Flutter tests/analyze, independent review, phone visual/compact/text-scale checks; cannot claim these until run. GitHub Actions PR workflows target base main only, so stacked child PR does not auto-run Flutter CI. **No merge** until owner explicit Go merge and all applicable gates pass.

## Review handoff checkpoint

- PR #701 now targets `main`, not the original stacked parent. Parent PRs #695 and #698 are merged; reconciliation commit `99328c8` preserved #698's optional-fallback P2 fix and test.
- Exact-head GitHub Actions launched only after targeting `main` and pushing new changes. Reconcile the newest commit's CI and independent review results before any merge.
- Source/docs were inspected remotely. Local checkout, Flutter/Dart execution and physical Android/iOS screenshot verification were not available from this execution environment. Do not claim visual QA.
- **Gate:** Not merge-ready until Flutter CI, Codex P2 disposition and applicable visual/layout checks are verified; owner separately prohibited merging in this slice.

## 2026-10-26 review + compact-card checkpoint

- PR #701 rebased by reconciliation merge onto merged `main`; scoped six-file diff, without dropping PR #698's optional-fallback P2 fix/regression. Root owner requested **smaller Timeline card height**, without changing screen structure or missing/owner-scoped Weight truth.
- Codex reviewed `99328c8` and found one P2 unit-test failure: fractional `-0.8` delta equality; replace only the matcher with `closeTo(-0.8, 0.001)`. Do not round production weight deltas to satisfy a test.
- Compact cards: Core `TioCard` retained, vertical padding `lg → sm`, Today dot aligned inline with date, recorded time remains below, inter-card gap `sm → xs`. Keep notes untruncated, Change/New low badges, global kg/lb, Today border, pagination, and pinned Log Weight. Add baseline widget geometry regression (<80dp), preserving text/weight and action visibility.
- Validation: GitHub read/review/source audit only before this patch; Flutter CI, reviewer disposition, and device screenshots pending. Older base/stack statements in prior checkpoints are historic, not live planning.

## Exact-head CI repair (following `370811e`)

- GitHub Flutter analyze (on `370811e`) flagged one `unnecessary_non_null_assertion` in the strictly-older delta projection. Removed redundant `!`; nonnull guard is retained.
- Progress widget shard exposed a pre-existing brittle expectation: Current summary **and** Timeline now both display `160.9 lb`. Replaced global single-text assertion with Timeline-card descendant assertion so the test checks the intended owner UI, not a duplicate count.
- Docs hygiene failure on `370811e` traced to markdown trailing spaces; corrected at `56ffabe`, whose docs hygiene check passed. All Flutter CI gates must re-run on the latest code HEAD; neither this note nor earlier runs count as validation.

## Owner card-height correction + Codex accessibility guard (2026-10-26)

- Owner observed variable Timeline card heights; corrected within the approved Timeline UI slice. All rows use a consistent 80dp height at the normal 390dp/1x viewport, irrespective of Today, badge or note. Longer notes have a one-line preview with the full saved note retained via Tooltip (no data loss).
- For narrow widths/accessibility text sizes, all cards in that viewport grow to the same taller shared height. Badge actions relocate below measurements rather than truncating lb/kg and user-entered weights. Small-screen/large-text physical layout remains to be QA-tested.
- Added widget regressions covering equal-height mixed cards and larger text with New low + lb; prior baseline height test now asserts exact 80dp. Continue exact-HEAD Flutter CI and independent Codex review; no merge.

## 2026-10-26 exact-head Flutter CI repair audit

- Confirmed HEAD `d84fd32a` failed Flutter CI run `40321469602` in `Test Flutter (core-wear)`: Progress shard 131 passed / 1 failed. Aggregate `Analyze and test` failure is downstream; Flutter/Dart analysis and other two Flutter shards passed.
- Root exception in the new 1.8x text widget test: chart date-label `Row` at `progress_weight_page.dart:461` overflowed horizontally by 158px. Make both date labels flexible, retaining full text through wrapping and baseline normal-scale alignment.
- The same test assumed both Timeline cards are mounted simultaneously, but the older record is below the lazy ListView viewport. Verify two row heights sequentially after scrolling, not via a false global count.
- Latest Codex P2 identified a Today-border 2dp width mismatch between Timeline badge stacking and fixed-height decisions near 337dp. Use a shared width predicate, reserve that inset consistently for every card, and add a narrow Today/non-Today equal-height/overflow regression. At standard 390dp/1x, 80dp same-height contract remains untouched.
- Scoped to existing approved #700 Progress UI/test repair. No schema/Auth/RLS/Storage change; TNYX-119 remains In Progress. GitHub source edits are committed by existing `im-tnyx` implementation owner only. Linear `get_agent_context` was unavailable (tool not found), while `get_issue(TNYX-119)` succeeded.
- Exact new commit Flutter CI, independent review, and physical Android/iOS screenshot QA still require verification; **do not merge** without separate owner instruction.

## 2026-10-26 independent review P2 performance fix

- Independent `im-tio` review on exact HEAD `92a1ba59` reported a real P2: the synchronous Timeline projection used nested full-History scans per row, `O(n²)`, while pagination can grow indefinitely. This is a code-performance issue, not an infrastructure problem.
- Replaced per-row suffix search and `priorOrConcurrentWeights` allocations with a reverse `O(n)` pass over canonical `measuredAt DESC, id DESC` History, grouped by the exact measurement instant. The closest strictly older eligible entry is used for delta; older eligible minima and equal-time minimum/tie count govern the conservative `New low` badge. Future records and incomplete pagination never create phantom lows.
- Added 6,000 timestamp-group/12,001-row regression covering ordering, sibling differences, earlier delta, future exclusion and incomplete pagination, plus a tied same-instant minimum negative-path regression.
- Previous exact-head Flutter run `40323286661` on `92a1ba59` was SUCCESS in all Flutter analysis/shards and Docs Hygiene; that success does **not** validate this new commit. Exact-new-HEAD checks and independent re-review remain required. Do not merge without an explicit owner merge instruction.

## 2026-10-26 Owner-approved graph and range menu extension (same PR, no merge)

- Owner explicitly requested graph-focused Weight summary, **separate Current / selected `N DAY CHANGE` / `RATE OF CHANGE` Tio cards** and, after read-only Core/Nutrition audit, gave `Go` to replace the material `PopupMenuButton` with existing Nutrition-style `MenuAnchor + TioCard.elevated + MenuItemButton`. Owner previously prohibited opening another PR unless #701 was merged first, and has not authorized merge. Therefore the extension stays in the existing PR #701 review branch; its old approval/CI status **must be revalidated** after the new commit.
- No new design system component. Changed only Progress page, read-only dashboard projection, focused widget/model tests, canonical Progress doc and handoff. Existing `TioCard`, `MenuAnchor`, theme tokens and fixed Log Weight action are preserved.
- Rate = signed actual newest-minus-oldest eligible selected-window kg change multiplied by seven and divided by elapsed measured days. Require two distinct instants; `null` shows unknown instead of fabricating rate. Unit follows global kg/lb. A real equal-weight interval yields zero, not unknown.
- Verification gates: latest HEAD Flutter CI, menu selection/dismissal, chart/stat separation, narrow/accessibility, exact range semantics, independent re-review and Android/iOS light/dark layout. Physical QA and formal independent approval remain **unverified**. No merge.

## 2026-10-26 exact-head CI test-only correction

- HEAD `f061034c` Docs Hygiene passed; Flutter Analyze failed only because the new widget test referred to unexported `ProgressWeightRange` as a generic type argument while asserting absence of `PopupMenuButton`. The reusable elevated `TioCard`, three `MenuItemButton` options and selected range behavior are already asserted. Removed this redundant compile-time assertion rather than importing a private presentation type solely for a negative test.
- All Flutter CI checks must rerun on the resulting HEAD. No approval or merge.

## 2026-10-26 new stats extension: Timeline lazy-list regression

- On `b1adc7a5`, exact-head Flutter Analyze/Dart succeeded. The core-wear shard's 140/141 Progress tests showed one existing large-text Timeline test assumed its first card was mounted at initial scroll offset. The newly approved three cards correctly push Timeline below the fold at 390dp/1.8x; this is an invalid test visibility assumption, not license to reduce/change the approved cards.
- Adjusted the test to `scrollUntilVisible('Today')`, then measure that card's own full lb value and later the strictly older card; preserves accessibility and equal-height assertions. New exact-head CI is required; **no claim of PASS until it completes**.

## Device QA correction: wheel and record calculation

Owner-reported Android QA: weight wheel lacks the original kg/lbs drum; restore existing Core three-drum `TioWeightWheel` with sheet-local unit selection, without changing global preference or canonical kg writes. Goal-directed record marker requires the newest eligible row, strict all-history proof and direction (`loseWeight` New low / `gainWeight` New high), none for Maintain/unknown. Approved further UI corrections and exact-ID History Delete will follow under same PR and must be revalidated before merge. Status REVIEW, not approved.

## 2026-10-26 same-PR device QA layout correction

- Graph target sentence removed and goal distance moved to independent horizontal TioCard; the value is derived from canonical current/target, never hard-coded from reference imagery. Smaller aligned stat cards (third spans full width on narrow phones), reduced chart padding. Weekly rate suppressed for intervals below seven elapsed days; actual range change retained. Timeline uniform baseline 72dp (narrow stack +40dp), Today border 0.75dp Core stroke, goal record beside the weight and not stacked into the delta badge; no markers when no active Lose/Gain goal.
- Pending: exact-ID History Delete action + security/session tests, CI, independent review/visual QA. No merge.

## 2026-10-26 exact History delete action

- Each Timeline card now has an explicit small delete icon for its immutable `BodyWeightEntry.id` and uses Core `showTioConfirmationBottomSheet` with destructive intent. Cancel/no-answer never touches data; confirmed calls existing owner/session-pinned `BodyRepository.deleteWeightLog(id)` once and refreshes real current/chart/History and app-owned Body caches. Missing/deleted row or exception is non-optimistic and shows a generic result without identifying the owner/weight in logs. Session and async generation checks suppress stale UI update. No direct Flutter-to-privileged API, new schema/RLS/Storage or delete-by-row-position.
- Device QA checkpoint: latest commit CI and independent review required; do not merge.

## 2026-10-26 CI lint gate

Flutter Analyze on `696b8f27` found one `curly_braces_in_flow_control_structures` info in the delete-confirmation handler. Corrected braces only. The prior check is not a PASS and new exact-head Flutter CI is required; review/merge still pending.

## Latest CI diagnostic corrections

Flutter Analyzer on `696b8f27` flagged one missing block-brace lint (fixed at `ba59d5fb`). The core-wear shard had 144/145 Progress tests successful; the only failure was a new goal marker test fixture missing mandatory `weeklyWeightChangeKg` for Lose Weight, not a production failure. Added the required test goal pace. Reduced timeline badge horizontal/vertical padding and date-to-weight gap to preserve full kg/lb text next to status and delete affordance. Exact-HEAD CI pending; no merge/review bypass.

## 2026-10-26 owner correction — pencil on Timeline, Delete inside Edit sheet

- Owner explicitly replaced per-card delete with an accessible pencil that opens an Edit Weight bottom sheet, and moved Delete to that sheet's pinned footer. Preserve same-PR scope and do not merge.
- Reuse the existing Progress-owned composition of `TioEditorSheet`, `TioWeightWheel`, Core DateTime picker and pinned footer rather than building a duplicate editor. Editing is addressed by the exact canonical UUID: `BodyWeightLogEdit(id, weightKg, measuredAt)`, with no new record or changed source/metadata. Existing private notes are displayed read-only: the current backend edit contract does not write note metadata, so Notes/Photo inputs are not enabled for edit.
- Deletion remains a separate Core destructive confirmation within the editor, invoking existing `BodyRepository.deleteWeightLog(id)` with caller session-generation checks; refreshing real owner-backed state on success/known absence. Validate cancellation, update identity, session invalidation and load/graph/Timeline refresh. Latest CI/re-review/device QA mandatory; not approved or merged.

## 2026-10-26 exact-HEAD edit-test import correction

On `0c39c74e`, Dart Analyze of production Progress code passed; the newly added edit sheet widget test referenced `BodyWeightEntry` without importing the public `tio_feature_progress/progress.dart` boundary, producing one `undefined_function` error. Added the missing public import. Exact new-head Analyze and tests, independent review and Android/iOS QA remain mandatory; not merged.
