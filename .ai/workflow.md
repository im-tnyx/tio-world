# Workflow

Use docs to freeze ownership before building large feature areas.

## Current Development Flow

1. Check current source and canonical docs.
2. Confirm feature ownership.
3. Add or update the smallest useful module/screen/package slice.
4. Keep UI scaffolding minimal.
5. Move data behind repositories when persistence is needed.
6. Add Supabase tables only when the real data shape is known.
7. Run validation.
8. Update docs when behavior or architecture changes.
9. Update ADRs when durable architecture decisions change.
10. Update changelog/progress docs when module boundaries, data flow, navigation policy, or engineering practice changes.

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
