# GitHub #571 — Parallel Flutter CI (bounded implementation)

**Status:** In progress — exact-head CI and independent review pending
**Primary owner:** Repository CI / this issue-specific GitHub branch
**Affected platforms:** Flutter phone/Wear packages, pure Dart shared package, GitHub Actions only

## Owner Approval and Scope Boundary
**Trigger:** None (CI-only maintenance); explicit owner Go to start: 2026-10-16.
**Approval:** Scoped implementation of [GitHub #571](https://github.com/im-tnyx/tio-world/issues/571).
**In scope:** Flutter CI YAML, one fail-closed shard script, this task handoff/index; no product/runtime changes.
**Out of scope:** Commit attribution guard, branch protection/rulesets, app source/tests, mobile visuals, Supabase, backend, new toolchain versions, merge.

## Verified preflight
- Base: main at 7f05def96a5ee5d79db07ea050ae78ce46e77cb5 (PR #570 merged). No open PRs reported before branching.
- Root AGENTS.md, .ai/workflow.md, .ai/tasks/TEMPLATE.md, .github/PUSH_TEMPLATE.md, docs/development/TESTING_GUIDE.md and live CI YAML inspected.
- main branch metadata reports protected=true and required_status_checks: Commit attribution guard with source App ID 5032971. Dedicated branch-protection detail GET returned 403; no policy change is requested. The old Analyze and test check is not listed as required but its name is preserved.
- Existing Flutter CI contains one sequential quality job; 16 Melos packages, 15 Flutter + 1 pure Dart. Exactly 13 Flutter packages currently have test/; coaching and welcome must remain analyzed.
- Prior successful Flutter CI #38846102786: approximately 10m08s wall time; not proof of package-level timing.
- No dedicated matching Linear issue found; GitHub #571 is the active narrowly scoped tracker. Historical .ai/tasks/flutter-ci-foundation.md does not override runtime YAML.

## Design and implementation
- Analyze job performs the unchanged Flutter and pure Dart analyzers and runs pure Dart tests.
- Three independent matrix test shards (fail-fast false) execute every existing Flutter test-bearing package exactly once: app-workout=4; nutrition-onboarding=4; core-wear=5. Groups are preliminary, to be rebalanced only after observed timings.
- scripts/ci/flutter-test-shards.sh is the single package assignment registry: it verifies real Flutter package test/ directories (including nested apps/features/** packages) against assigned paths before tests and fails on missing, newly added or duplicate assignments.
- Each test-bearing package uses the existing flutter pub get followed by flutter test --no-pub. An individual package failure does not mask skipped siblings; the shard fails after attempting all packages.
- Final job keeps exact former display name Analyze and test; needs both analysis job and complete matrix; if always(); only success/success passes. Failure, skipped or cancelled dependency cannot produce a green final gate.
- Keep current stable git-clone setup, Melos 2.9.0, read-only permissions, concurrency semantics and path filters (with shard-script trigger added). Do not touch the trusted App attribution workflow.

## Validation evidence
- Locally parsed YAML structure and bash -n shell syntax: pass (isolated fixture, not hosted GitHub).
- 13 mock Flutter test packages across the same repository layout verified exactly once; 26 total mocked flutter pub get/test invocations: pass.
- Newly added coaching/test fixture fails closed: pass.
- Forced Workout flutter test failure makes shard exit non-zero while remaining packages still run: pass.
- **Not yet verified:** hosted exact-head Flutter CI, actual Flutter SDK/tests, check run status/source, three timing runs, independent review.

## Active Handoff
**Planning owner:** GitHub #571; Linear companion not created.
**Implementation owner:** GitHub branch ci/issue-571-parallel-flutter, single CI slice.
**Review owner:** Independent reviewer pending.
**Implementation ownership state:** Active.
**Repository state last verified:** main 7f05def96a5ee5d79db07ea050ae78ce46e77cb5.
**Branch:** ci/issue-571-parallel-flutter.
**Local working-tree state:** No checked-out repository; GitHub API edits. A standalone sandbox fixture was used to check shell behavior.
**Current blockers:** Exact-head hosted CI, review, and three comparable timing runs required before claiming speed target.
**Next exact action:** Check Draft PR #573 exact-head GitHub CI and independent review; record three comparable timing runs when available; do not merge without owner instruction.

## Final handoff
**Changed paths:** .github/workflows/flutter-ci.yml; scripts/ci/flutter-test-shards.sh; this task and .ai/tasks/README.md.
**Current status:** REVIEW pending hosted evidence.
