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
cd apps/mobile
flutter pub get
flutter analyze
flutter test
```

Backend:

```bash
pnpm lint
pnpm test
```

Docs-only:

```bash
git diff --check
```
