# Coding Rules

Follow the existing repository style before introducing new patterns.

## Flutter / Dart

- Keep features modular and vertically sliced.
- Keep widgets dumb.
- Prefer immutable state.
- Keep routing, dependency injection, and bootstrap code thin.
- Keep feature logic inside the owning feature or package.
- Prefer existing widgets, theme tokens, routing helpers, and package patterns.
- Avoid unnecessary abstractions.
- Keep changes small and reviewable.

## Recommended Flutter Stack

Preferred mobile defaults:

- State management: `riverpod` / `flutter_riverpod`.
- Routing: `go_router`.
- Networking: `dio`.
- Models: `freezed` + `json_serializable` where useful.
- Local database: `drift` or `isar`, chosen per actual need.
- Secure storage: `flutter_secure_storage`.
- Monorepo tooling: `melos`.

Do not introduce competing libraries without a clear reason.

## Domain Boundaries

- Domain entities should not depend on Flutter widgets or platform UI APIs.
- Shared Dart packages belong in `packages/*` only when multiple features or app layers need them.
- Do not duplicate business rules across feature modules.
- Do not invent backend APIs, Supabase tables, RPCs, or sync contracts without a feature slice that needs them.

## Watch Boundaries

- Wear OS is built in Flutter (`apps/wear`) to share design system tokens, logic, and state.
- Apple Watch app should stay native Swift + SwiftUI.
- Watch apps focus on fast, battery-aware, glanceable actions.

## Data Rules

- No service keys, admin keys, keystores, private keys, or secrets in client code.
- No generated/cache/build artifacts in commits.
- Hardcoded sample data is temporary and must not become source of truth.
- Persistent data should move behind repositories as each feature slice is implemented.

## Validation

For Flutter runtime changes, prefer:

```bash
flutter pub get
flutter analyze
flutter test
```

For monorepo package changes, prefer:

```bash
melos bootstrap
melos analyze
melos test
```

For backend changes, run the relevant package checks, for example:

```bash
pnpm install
pnpm lint
pnpm test
```

For docs-only changes, at minimum run:

```bash
git diff --check
```
