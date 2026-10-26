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

- Dependent **draft PR [#701](https://github.com/im-tnyx/tio-world/pull/701)** created on 2026-10-26, initial code head `34753b2c8c819bf8ef2b8dee3dd867b38a154840`.
- GitHub compare against immediate parent #698 `8b168879ad3a7c1684d7cc1d6b93fa544356febb`: ahead 3 / behind 0, merge-base equals parent, six Progress-owned paths only. Parent #698 and grandparent #695 remain open and unmerged.
- Existing Core card used, no new design-system tokens; Today highlight now rendered outside the opaque card. Minimal nullable-record guard was hardened after initial push.
- **Actual validation:** Source/branch/PR/diff inspection through GitHub API. No Flutter/Dart SDK in this execution container (`command -v flutter`, `command -v dart` produced none), no mounted Windows checkout, no device visual QA. Exact-head GitHub Action runs: 0, because existing Flutter workflow only auto-triggers pull requests against `main`. No reviewer approval or independent completed review verified.
- **Final status:** `PARTIAL` — proposed code and test cases exist, execution/CI, independent review and device acceptance remain unavailable. Do not merge or declare PASS. After #695 then #698 merge, reconcile this child branch to `main` and rerun exact-head gates.

## 2026-10-26 review + compact-card checkpoint

- PR #701 rebased by reconciliation merge onto merged `main`; scoped six-file diff, without dropping PR #698's optional-fallback P2 fix/regression. Root owner requested **smaller Timeline card height**, without changing screen structure or missing/owner-scoped Weight truth.
- Codex reviewed `99328c8` and found one P2 unit-test failure: fractional `-0.8` delta equality; replace only the matcher with `closeTo(-0.8, 0.001)`. Do not round production weight deltas to satisfy a test.
- Compact cards: Core `TioCard` retained, vertical padding `lg → sm`, Today dot aligned inline with date, recorded time remains below, inter-card gap `sm → xs`. Keep notes untruncated, Change/New low badges, global kg/lb, Today border, pagination, and pinned Log Weight. Add baseline widget geometry regression (<80dp), preserving text/weight and action visibility.
- Validation: GitHub read/review/source audit only before this patch; Flutter CI, reviewer disposition, and device screenshots pending. Older base/stack statements in prior checkpoints are historic, not live planning.
