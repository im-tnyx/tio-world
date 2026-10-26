# Progress Weight Timeline — #700

**Status:** In progress (stacked PR, no merge).  
**Approval:** 2026-10-26 explicit owner message with two image references approving a visual Timeline refresh.  
**Implementation owner:** GitHub `im-tnyx`; no source edits by the separate reviewer account.  
**Scope:** Progress-owned Flutter presentation only, month grouping, weight/change chips, honest Today/New low, optional persisted note. Source remains A1 owner-scoped paginated History.  
**Base:** `fix/issue-694-697-progress-chart-action@8b168879ad3a7c1684d7cc1d6b93fa544356febb` (PR #698), which depends on unmerged #695. Child `feat/issue-700-progress-weight-timeline`.  
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
