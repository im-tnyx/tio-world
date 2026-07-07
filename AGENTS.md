# AGENTS.md

Repository: im-tnyx/tio-world

These instructions apply to AI coding agents working in this repository.

## Communication

- Respond in Hindi unless the user explicitly asks for English.
- Keep code, file names, folder names, APIs, classes, functions, commands, and technical terms in English.
- Be direct, practical, and production-focused.
- Explain tradeoffs clearly when architecture choices affect mobile, watch, backend, data, or AI behavior.

## Product Context

`tio-world` is the Flutter-first engineering home for TNYX / Tio, an AI-powered health, fitness, nutrition, workout, progress, wearable, and coaching product.

The intended platform strategy is:

- `apps/app`: Flutter Android + iOS phone app.
- `apps/wear`: Flutter Wear OS companion app.
- `apps/watchos`: Native Swift + SwiftUI Apple Watch app.
- `apps/shared`, `apps/core`: Shared Dart packages and core UI modules.
- `backend/*`: API, AI coach, jobs, database, and server-side integrations.
- `.github/*`: Contribution, issue, PR, push, and workflow guidance.
- `.ai/*`: Concise AI orientation files.
- `docs/*`: Canonical product and architecture documentation.

## Source Of Truth

Before code changes, inspect the actual repository and read the relevant source-of-truth docs:

1. `README.md`
2. `docs/README.md`
3. `docs/engineering-guidelines.md`
4. `docs/definition-of-done.md`
5. `docs/architecture.md`
6. `docs/adr/README.md`
7. `.ai/README.md`
8. `.ai/workflow.md`
9. `.github/PUSH_TEMPLATE.md`
10. `.github/PULL_REQUEST_TEMPLATE.md`

Runtime source/config wins for actual behavior. Product docs and ADRs win for intended architecture and product rules. If docs and runtime disagree, call out the stale doc clearly instead of silently guessing.

## Repo Ownership

- `apps/app` owns the Flutter mobile app shell, routing, composition root, and mobile UI entry point.
- `apps/features/*` owns feature-level mobile UI, state, controllers, and presentation workflows.
- `apps/shared` owns shared Dart entities/value objects, API DTOs, workout/nutrition calculations, sync contracts, and core domain logic.
- `apps/core` owns reusable design system tokens, widgets, theme primitives, and routing contracts.
- `apps/wear` owns Wear OS Flutter UI, watch-specific navigation, and phone bridge sync integration.
- `apps/watchos` owns Apple Watch native UI, HealthKit integration, complications, and WatchConnectivity.
- `backend/api` owns HTTP/API routes, auth-aware server endpoints, and client-safe contracts.
- `backend/ai-coach` owns server-side coaching orchestration, model prompts, guardrails, and AI response shaping.
- `backend/jobs` owns background workers, notifications, sync jobs, and scheduled tasks.
- `backend/db` owns schema, migrations, seed data, and database policies.
- `docs` owns canonical product and architecture docs.
- `.github` owns contribution, issue, PR, push, CI, and post-merge workflow docs.
- `.ai` owns concise AI orientation files.

## Architecture Rules

- Keep changes small, focused, and reviewable.
- Respect feature and package boundaries.
- Prefer existing patterns before adding new abstractions.
- Do not move feature business logic into app shell, routing glue, or shared UI components.
- Screens/widgets should render state and emit actions. Business decisions belong in controllers/notifiers/use cases/domain helpers.
- Keep backend, database, and AI assumptions out of Flutter screens.
- Do not invent APIs, schemas, workflows, or architecture that conflict with checked-in docs/source.
- Do not create large future modules until a real vertical slice needs them.
- Document durable architecture decisions in ADRs when module boundaries, data flow, platform strategy, or sync behavior changes.

## Flutter Mobile Rules

- Use standalone feature packages under `apps/features/*`.
- Prefer `Riverpod` for state management unless the repository documents a different standard.
- Prefer `go_router` for app routing unless the repository documents a different standard.
- Prefer immutable state and explicit action/event flows.
- Keep `build()` methods readable and free of heavy business logic.
- Use `apps/core` for shared tokens and reusable widgets.
- Do not hardcode repeated colors, spacing, typography, radii, or shadows in production UI.
- Use generated model code only when configured by the repo, and do not commit generated outputs unless the repo explicitly tracks them.

## Watch Rules

- Wear OS UI belongs in `apps/wear` using Flutter.
- Apple Watch UI belongs in `apps/watchos` using Swift + SwiftUI.
- Watch apps should stay lightweight, fast, and battery-aware.
- Watch features should focus on quick actions: start/pause workout, set input, rest timer, heart rate, steps, calories, offline active workout, and quick sync.
- Heavy analytics, AI coaching, long history, and complex charts should live on phone or backend.

## Data, Privacy, And Health Rules

- Treat health, nutrition, workout, biometric, auth, and subscription data as sensitive.
- Do not log secrets, tokens, private health data, real user data, or production credentials.
- Do not expose service-role keys, admin keys, private keys, keystores, signing files, or production secrets in client apps.
- Client apps may use only client-safe keys and APIs.
- Server-only operations must stay in `backend/*`.
- Database tables should be introduced incrementally when a real feature slice needs them.
- Every client-accessible table needs RLS or equivalent access control.
- Hardcoded sample data is temporary UI scaffolding, not source of truth.

## Backend And AI Rules

- AI coaching logic should be server-side unless docs explicitly say otherwise.
- Do not put model prompts, provider secrets, or admin credentials in client apps.
- Keep API contracts clear and versionable.
- Validate user-owned data access on the server.
- Prefer small, testable endpoints and explicit DTOs.
- Do not imply a Supabase/Postgres migration, RLS policy, RPC, or live schema change unless it is actually included.

## Git And Push Workflow

Before commit, push, or PR creation:

1. Read `.github/PUSH_TEMPLATE.md`.
2. Confirm repository state with `git status --short --branch`.
3. Keep unrelated local changes out of the commit.
4. Run the applicable validation commands from `.github/PUSH_TEMPLATE.md`.
5. List validations actually run in the PR.

For Pull Requests, follow `.github/PULL_REQUEST_TEMPLATE.md`.

After a PR merge, follow `.github/POST_MERGE_SYNC.md` before starting the next branch.

## Validation

Use the smallest meaningful validation for the changed area.

For Flutter mobile/package changes, prefer:

```bash
melos bootstrap
melos analyze
melos test
```

If working only inside `apps/app`, use:

```bash
cd apps/app
flutter pub get
flutter analyze
flutter test
```

For backend changes, use the documented package manager commands, commonly:

```bash
pnpm install
pnpm lint
pnpm test
```

For docs-only changes, at minimum run:

```bash
git diff --check
```

If validation cannot run, document the exact reason. Do not claim checks passed unless they actually ran.

## Never Commit

Never commit generated/cache/secrets or local machine state, including:

- `.env`, `.env.*`, local runtime config, or credential files
- service accounts, keystores, private keys, signing files, certificates
- APK, AAB, IPA, app archives, or local release artifacts
- `node_modules`, `.turbo`, `.next`, `dist`, `coverage`, or backend build outputs
- `.dart_tool`, `build`, generated Flutter/Dart caches, or local package caches
- `.gradle`, `.kotlin`, Android build outputs, or local Gradle caches
- Xcode `DerivedData`, `.xcuserdata`, local archives, or user schemes
- IDE user state, local paths, logs, screenshots with private data, or real user exports

## Agent Safety Rules

Agents must not:

- discard user changes without explicit instruction
- rewrite git history without explicit approval
- push unrelated changes
- hide failing validation
- claim PR creation if the tool was unavailable
- delete branches unless requested
- merge PRs unless explicitly told to proceed

Agents should:

- inspect nearby code before editing
- keep scope tight
- update docs when behavior or architecture changes
- report exact commands and outcomes
- ask only when genuinely blocked; otherwise make a safe, documented best effort
