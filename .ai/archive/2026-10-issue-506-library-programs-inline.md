# GitHub #506 — Inline Programs on Library

**Status:** Validated
**Completed:** 2026-10-08
**Merged PR:** #507
**Merge SHA:** `59ed303db083c30e2b8cabdcdd3a71b1613ad1f7`
**Reviewed head:** `8977e9398267c2da82120ea2ed2f330a44778fc1`
**Planning:** GitHub #475, Linear TNYX-81 / TNYX-267 / TNYX-83

## Outcome

PR #507 delivered the bounded Programs-on-Library presentation slice:

- persisted Programs render directly on Library;
- the Programs header keeps `/workout/programs` as optional secondary management;
- folder-plus reuses canonical Create Program;
- Library Program entries are plain header rows with presentation-only expand/collapse and 3-dot;
- 3-dot opens a Program-scoped Tio bottom sheet;
- the currently enabled action is persisted **Edit Program** rename through `ProgramRepository.rename()`;
- standalone `/workout/programs` keeps its prior grouped display-only geometry;
- Program detail and Program-owned Routine behavior remain W4/W6B-gated.

## Validation

Exact reviewed head `8977e9398267c2da82120ea2ed2f330a44778fc1`:

- scope audit: 44 ahead / 0 behind, exactly 13 owned paths;
- Flutter CI #3047: PASS after same-head rerun;
- Flutter/Dart analyze: PASS;
- Flutter/Dart tests: PASS;
- Codex exact-head review: no major issues;
- duplicate final Codex review: completed clean;
- unresolved review threads: 0;
- PR mergeable before merge.

The repository uses an App-backed required `Commit attribution guard`, but the available connector did not expose custom check-runs or live protection state. This archive does not claim an independently observed attribution-check PASS. GitHub accepted the squash merge with the reviewed head pinned.

## Post-Merge

- PR #507 merged as `59ed303db083c30e2b8cabdcdd3a71b1613ad1f7`;
- remote `main` matched that merge SHA immediately after merge;
- GitHub #506 closed as completed;
- GitHub #475 remains open and its current-runtime section was reconciled;
- TNYX-267 remains Backlog because broader W4/W6B capability is still pending.

## Deferred

Program detail, Program-owned Routine content/create, dotted Add new routine, Library-level default My Program behavior, Program lifecycle actions, and Your Plan remain separate capability slices.

## Canonical References

- [Library](../../docs/screens/library.md)
- [Programs](../../docs/screens/programs.md)
- [ADR-0015](../../docs/adr/0015-program-owned-routine-and-program-source-boundary.md)
- GitHub #475 / #506
- Linear TNYX-81 / TNYX-267 / TNYX-83
