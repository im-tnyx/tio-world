# GitHub stack consolidation — Phase 3A units

**Status:** Validated
**Primary owner:** apps/core; App, Onboarding, Profile and Settings consumers
**Affected platforms:** Flutter phone; shared Flutter consumers
**Local branch:** codex/github-stack-consolidation

## Global UI / Design-System Guardrail

Follow AGENTS.md, apps/features/AGENTS.md and apps/core/lib/src/theme/README.md.
This is an API/module rename, not a visual task. Preserve rendered values,
layout, colors, typography, navigation, calculations and persistence semantics.
The older design-system task's normalization allowance does not apply here.

## 1. Discovery

Absorb only the effective PR #132 units lane into the existing checkout, based
on PR #152. Validate this new local composition and create one bounded local
commit only when scope, focused tests and analyze allow it.

- Foundation PR #152: 5d44c1abf8682247e5eabe1081ca905f722910ee.
- Units source PR #132: 2b82722b2097d3d81399f62f89b37eff304b6209.
- Units parent PR #131: d4e323ce7ef22cd2958756236f34f411bc87473d.
- Import model: effective parent-to-head net diff, not 58 transitional commits.
- Expected historical inventory: 46 rename-aware entries, including the units
  task record; this focused consolidation brief is the only additional path.

Non-goals: #124 workflow hygiene (Phase 3B), UI-preserve (later phase),
body_measurements, UI redesign, new feature work, worktrees, push, PR/Issue
changes, main changes, published history rewriting, branch deletion and cleanup.
No Supabase schema, data, hosted config, function, migration or production
mutation. Published historical branches stay untouched; this branch stays local.
User-owned attachments and other pre-existing untracked files stay untouched.

## 2. Codebase Exploration

Fresh fetch and live remote refs matched all three pinned source SHAs.
The consolidation branch did not exist locally or remotely. Tracked state was
clean; the existing untracked attachment directory was retained during switch.
The previous audits were read; the latest Phase 2 snapshot supersedes the older
26-branch/13-PR audit. Current source refs, not stale PR baseRefOid, govern import.

The effective diff moves core measurement capability to units and renames
MeasurementUnitPreferences / MeasurementConverters / MeasurementFormatters to
UnitPreferences / UnitConverters / UnitFormatters. Consumer changes are within
App, Core, Onboarding, Profile and Settings. Enums and persisted values remain
kg, lb, cm, ft_in, km, mi, ml, fl_oz; no stored-value migration is allowed.

Historical #136 Auth test fixes are already represented in #152 and will NOT
be imported again. Both Auth presentation test trees equal
490b0c317860b7583e69e4df221239e91cdfb01a.

## 3. Clarification

| Decision | Status | Rationale |
|---|---|---|
| Existing checkout only; no worktree | Approved | Explicit Phase 3A scope |
| Net units diff only | Approved | Preserve final source without old parent history |
| No duplicate Auth fixes | Verified | Exact test-tree equality |
| Defer hygiene/UI lanes | Required | One implementation slice |
| Local commit conditional on validation | Approved | No push or published-history change |

## 4. Architecture Design

Retain Core ownership of conversions, formats and unit preferences. Existing
controllers/repositories/mappers keep their roles and only consume the renamed
types. Shared enums, JSON keys/values, calculation constants, error behavior and
callbacks must remain unchanged. No permanent legacy adapters or exports.

Rejected: cherry-picking all 58 transitional commits; merging older Auth ancestry;
whole-file replacement from a stale tree; mixing workflow/UI lanes into this task.

GoalPace: import only _formatPace / _formatWeight units API hunks. Existing
_showGoalPaceInfoSheet / _showWarningModal implementations stay as in #152.

## 5. Implementation Plan

- [x] Read audit/instructions; verify pinned refs, clean tracked state and branch absence.
- [x] Create/switch local consolidation branch directly from #152.
- [x] Fresh byte-preserving units apply-check passed.
- [x] Apply only the effective units net diff; refresh historical task evidence.
- [x] Audit exact scope, retained #152 source, legacy API references and serialization.
- [x] Run focused tests, repository analyze and serialized full tests.
- [x] Run supported local Android Phone and Wear debug builds.
- [x] Review diff; required validation permits one bounded local commit.
- [x] Freeze this handoff at Phase 3A; commit/proof metadata belongs in the
  requested outside-repository execution report. Do not start Phase 3B.

## 6. Quality Review

### Validation Run

- Read-only net patch apply-check: PASS; four historical task Markdown trailing
  spaces will be removed during import.
- Focused tests: PASS, 75 total (Core 12, Onboarding 31, Profile 22,
  Settings 4, App/profile integration 6).
- Scope: 46 expected entries plus this brief; 0 unexpected/missing entries.
  All 44 resulting source/test blobs match the effective #132 source.
- Legacy standalone public API/import references in Dart: 0. Five Markdown
  files contain historical/provenance references; they are not runtime APIs.
- Unit enum file is byte-identical to the foundation; JSON keys/values and
  converters/formatters retain their behavior.
- GoalPace modal tail is byte-identical to the foundation. Protected latest
  Auth/Nutrition/Supabase/workflow/attachment paths have no diff.
- Flutter analyze --no-pub: PASS across all 15 declared Flutter packages.
- Dart analyze .: PASS for the pure Dart shared package.
- Serialized full Flutter tests: PASS, 1,136 tests across all 13 Flutter
  packages with test directories. Coaching and Welcome have no test directory.
- Serialized Dart tests: PASS, 30 tests in shared.
- Phone Android debug: PASS with flutter build apk --debug --no-pub.
- Wear Android debug: PASS with flutter build apk --debug --no-pub.
- Historical #152/#136 CI does not validate the new composition.

### Review Findings and Resolution

The Foundation preserves later Auth, Phone OTP, Email confirmation/progress,
Google linking guards/mismatch message and Nutrition controller/Other details.
Post-import content checks passed; no hosted/device acceptance is implied.

Local Flutter 3.44.6 / Dart 3.12.2 is available. Installed Melos 8.2.0 cannot
run this legacy Melos 2.9.0 workspace flow without an incompatible prompt.
Use the same declared-package Flutter/Dart commands serially with existing
resolved package configurations; do not upgrade/reconfigure shared tooling.
The foundation's Onboarding lockfile omits an already-declared local Progress
dependency. A strict offline lockfile preflight rejected that stale metadata;
the existing package configuration includes Progress, so --no-pub tests pass
without changing any tracked lockfile or dependency manifest.

Phone debug build reported an NDK version warning: project 27.0.12077973,
jni plugin 28.2.13676358. The build succeeded. Native configuration was not
changed; any follow-up is outside this units integration.

## 7. Final Handoff

Validated local source scope: 45 code/test entries from the audited units lane,
the refreshed historical units task record, and this focused brief: 47 total
rename-aware entries. No required source correction beyond #132 was needed.
The effective APIs are UnitPreferences, UnitConverters and UnitFormatters;
serialization, calculations and existing presentation contracts are unchanged.

No #124 templates, UI-preserve sheets, Welcome, Account Setup parity,
Supabase source/config, attachments or generated artifacts are in this diff.
All 75 focused tests, 15 Flutter-package analyzes, shared Dart analyze,
1,136 full Flutter tests, 30 Dart tests and both Android debug builds passed.
This validates the local Phase 3A composition, not hosted runtime acceptance,
release readiness, a new GitHub CI run or merge authorization.

The NDK warning remains recorded above. Global Melos was not changed; existing
resolved package configurations enabled the equivalent serial package commands.
No tracked lockfile, dependency manifest or native configuration changed.

Retain this task as the Phase 3A handoff until the next explicitly authorized
consolidation slice. Local commit SHA and final remote/state proof are recorded
in github-consolidation-phase-3a-units-2026-08-27.md outside the repository.

**Final status:** PASS — Phase 3A local source validation only; Phase 3B deferred.
