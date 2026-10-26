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
