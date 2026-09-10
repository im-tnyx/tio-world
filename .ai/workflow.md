# Workflow

Use docs to freeze ownership before building large feature areas.

## Current Development Flow

1. Read the root `AGENTS.md` and any applicable nested `AGENTS.md` before changing repository files.
2. Reconcile the current Linear issue, linked GitHub issue/PR, active `.ai/tasks/*` brief, current source/config, and canonical docs when those trackers exist. Call out stale/conflicting state instead of silently choosing one snapshot.
3. Confirm feature ownership.
4. Add or update the smallest useful module/screen/package slice.
5. Keep UI scaffolding minimal.
6. Move data behind repositories when persistence is needed.
7. Add Supabase tables only when the real data shape is known.
8. Run validation.
9. Update docs when behavior or architecture changes.
10. Update ADRs when durable architecture decisions change.
11. Update changelog/progress docs when module boundaries, data flow, navigation policy, or engineering practice changes.

Tracker roles are intentionally distinct:

- Linear owns current planning, sequencing, dependencies, and acceptance tracking.
- GitHub Issues/PRs own backlog/code-change/review history.
- `.ai/tasks/*` owns compact active execution handoff.
- Runtime source/config remains authoritative for current executable behavior; canonical docs/ADRs remain authoritative for intended architecture and product rules.

A tracker or planning item existing does not authorize implementation by itself. Apply the Owner Approval and bounded-slice rules from `AGENTS.md` and `.ai/FEATURE_DEVELOPMENT.md`.

## Feature Development Workflow

Use this seven-phase workflow for every user-facing feature, cross-package change, navigation change, persistence change, or design-system change. Small documentation-only corrections may use the lightweight workflow instead.

1. **Discovery**: write the desired user outcome, scope, non-goals, and success criteria in a task brief.
2. **Codebase exploration**: inspect the relevant runtime source, tests, configuration, ownership docs, and existing patterns. Record only verified evidence.
3. **Clarification**: resolve decisions that affect data ownership, persistence, privacy, platform behavior, compatibility, or product scope before coding.
4. **Architecture design**: state the owner packages, data flow, routes, state boundaries, alternatives considered, and chosen approach.
5. **Implementation**: make small vertical-slice changes that preserve the approved ownership and out-of-scope boundaries.
6. **Quality review**: run the smallest meaningful analysis/tests, review accessibility and failure states, and inspect the diff for boundary or security regressions.
7. **Final handoff**: record the changed files, behavior, validation evidence, known limitations, and final status.

Start from [tasks/TEMPLATE.md](tasks/TEMPLATE.md). Keep the feature brief current while work is active; move it to the archive only after it is validated or superseded.

## Source Of Truth Order

When code and docs conflict:

1. Runtime source/config wins for actual behavior.
2. Root README and contributor docs win for repository direction.
3. Platform-local docs win for implementation details.
4. Feature-local docs win for feature ownership details.
5. This `.ai` directory is only a concise orientation layer.

Tracker text is execution context, not a replacement for this source-of-truth order. When Linear, GitHub, or a task brief is stale against current source/docs, record and reconcile the mismatch before implementation.

## Do Not Start Without Explicit Need

Do not create large future areas before a slice needs them:

- Full onboarding rebuild
- Health integrations
- Recovery
- Billing / Entitlement
- Community
- Challenges
- AI Coach runtime
- Full Supabase schema
- Apple Watch full feature parity
- Wear OS advanced telemetry

Plan them in docs first, then implement vertical slices.

## Validation Defaults

Flutter/mobile:

```bash
melos bootstrap
melos analyze
melos test
```

Single Flutter app:

```bash
cd apps/app
flutter pub get
flutter analyze
flutter test
```

Supabase: run the approved feature's migration/RLS/security checks. Future protected backend: run the selected runtime's documented checks after that workspace exists.

Docs-only:

```bash
git diff --check
```
