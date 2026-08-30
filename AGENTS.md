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
- `supabase/*` (active, current): Auth, Postgres/RLS, Storage, migrations, and approved server functions.
- future `services/api`: the sole future protected-backend path (Node.js + TypeScript + Fastify), for AI coaching, advanced integrations, and long-running jobs once a concrete approved slice needs a protected server boundary. See ADR-0007. Do not introduce a `backend/*` namespace.
- `.github/*`: Contribution, issue, PR, push, and workflow guidance.
- `.ai/*`: Concise AI orientation files.
- `docs/*`: Canonical product and architecture documentation.

## Source Of Truth

Before code changes, inspect the actual repository and read the relevant source-of-truth docs:

1. `README.md`
2. `docs/README.md`
3. `docs/ARCHITECTURE.md`
4. `docs/MODULE_OWNERSHIP.md`
5. `docs/DEVELOPMENT_SETUP.md`
6. `docs/ROADMAP.md`
7. `docs/SUPABASE_STRATEGY.md` when Auth, data, Storage, backend, or Gemini behavior is in scope
8. `.ai/README.md`
9. `.ai/workflow.md`
10. `.ai/FEATURE_DEVELOPMENT.md` for feature work
11. `docs/PUSH_TEMPLATE.md`
12. `.github/PULL_REQUEST_TEMPLATE.md`

Runtime source/config wins for actual behavior. Product docs and ADRs win for intended architecture and product rules. If docs and runtime disagree, call out the stale doc clearly instead of silently guessing.

## Task Execution Protocol

For any user-facing feature, cross-package change, navigation change, persistence change, auth/session change, or design-system change:

Mandatory Owner Approval applies only before a new independently scoped product task/feature slice, an unapproved product-visible UI/UX change, or a Supabase table/column shape change. Normal implementation subtasks inside an already approved scope are not new-task triggers. See `.ai/FEATURE_DEVELOPMENT.md` for the canonical detailed contract.

- Before source changes, create or update one focused task brief under `.ai/tasks/` using `.ai/tasks/TEMPLATE.md`.
- Follow `.ai/workflow.md` in order: Discovery → Codebase Exploration → Clarification → Architecture Design → Implementation → Quality Review → Final Handoff.
- Keep only one implementation slice active at a time. Do not implement a large GitHub issue or epic as one broad change.
- Keep at most one active `Implementation owner` for a task slice. Only that owner may modify implementation/source files for the slice. Planning and review owners may inspect, reason, and update task/review governance records, but must not modify implementation/source files unless implementation ownership is explicitly transferred.
- Follow `.ai/tasks/README.md` for planned handoff, unexpected takeover, repository-state reconstruction, and ownership-transfer rules.
- GitHub Issues are backlog/tracking. `.ai/tasks` files are compact execution context and must not become transcript dumps.
- Each task brief must record verified evidence, exact in-scope/out-of-scope boundaries, non-goals, decisions, validation, and handoff status.
- Inspect `git status --short --branch` before implementation and preserve unrelated dirty/untracked work.
- Do not claim completion in a task file until the relevant validation actually ran.
- When a task is validated or superseded, follow `.ai/tasks/README.md` for handoff/archive behavior.

## Mobile Visual Safety

Architecture, backend, auth, routing, persistence, and token cleanup do **not** imply permission to redesign the phone UI.

- Preserve current rendered mobile geometry, spacing, typography, colors, component sizes, assets, and layout unless the active task explicitly approves a visual change.
- Token/refactor migrations must preserve the current computed runtime value by default.
- Do not replace a current value such as `7` with a nearby shared token such as `8` merely to remove a literal or satisfy a scale.
- Numeric similarity is not enough to justify a rendered-value change. Keep a value local/component-owned or introduce the correct semantic/component role only when ownership/reuse evidence supports it.
- Do not mechanically normalize raw UI literals to the nearest global token.
- If a rendered component is touched, record the baseline and validate the same state/viewport after the change. Prefer focused widget/golden/screenshot checks where practical, plus relevant light/dark and compact-width coverage.
- Treat an unexplained visual diff as a regression for non-visual tasks.
- Functional routing changes may change which screen is reached, but should not incidentally change how that screen looks.
- The presence of orphan/dead UI code is not permission to restore it to runtime. Verify current product intent and runtime usage before reconnecting removed UI.

## Repo Ownership

- `apps/app` owns the Flutter mobile app shell, routing, composition root, and mobile UI entry point.
- `apps/features/*` owns feature-level mobile UI, state, controllers, and presentation workflows.
- `apps/shared` owns shared Dart entities/value objects, API DTOs, workout/nutrition calculations, sync contracts, and core domain logic.
- `apps/core` owns reusable design system tokens, widgets, theme primitives, and routing contracts.
- `apps/wear` owns Wear OS Flutter UI, watch-specific navigation, and phone bridge sync integration.
- `apps/watchos` owns Apple Watch native UI, HealthKit integration, complications, and WatchConnectivity.
- `supabase/` (active, current) owns Supabase Auth, Postgres migrations, RLS policies, Storage boundaries, and approved Supabase functions.
- future `services/api` owns protected service endpoints, server-side coaching orchestration, Gemini/provider adapters, integrations, and long-running background work when Supabase functions are no longer sufficient. This is the only future protected-backend path (see ADR-0007); do not introduce a `backend/*` namespace.
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
- Before **any Flutter production UI change** in `apps/app`, `apps/features/*`, `apps/core`, or `apps/wear`, read `apps/core/lib/src/theme/README.md` and inspect the existing reusable UI/component surface under `apps/core` before writing local visual implementation. This applies even when the task is feature/app-shell work rather than an explicit design-system task.
- Consume shared UI through the public `package:tio_core/core.dart` boundary where available, and prefer an existing reusable core component before rebuilding an equivalent card, button, input, avatar, dialog, picker, sheet, navigation surface, or other shared pattern with raw Flutter primitives.
- When editing `apps/features/*`, also follow `apps/features/AGENTS.md`. Do not duplicate its shared UI rules inside individual feature packages unless that feature has genuinely unique product/domain instructions.
- Use `apps/core` for shared tokens and reusable widgets. Promote a new UI contract into core only when genuine cross-context reuse is evidenced; keep one-off feature/workflow composition with its owning feature while consuming governed core values.
- For changes that add, remove, rename, or materially change a public theme/token/context/config or reusable-component usage contract, update `apps/core/lib/src/theme/README.md` in the same change/PR.
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
- Privileged operations must stay in approved Supabase server functions or future `services/api`; never put them in client apps.
- Database tables should be introduced incrementally when a real feature slice needs them.
- Every client-accessible table needs RLS or equivalent access control.
- Hardcoded sample data is temporary UI scaffolding, not source of truth.

## Backend And AI Rules

- AI coaching logic and Gemini/provider credentials should be server-side unless docs explicitly say otherwise.
- Do not put model prompts, provider secrets, or admin credentials in client apps.
- Keep API contracts clear and versionable.
- Validate user-owned data access on the server.
- Prefer small, testable endpoints and explicit DTOs.
- Do not imply a Supabase/Postgres migration, RLS policy, RPC, or live schema change unless it is actually included.
- Supabase is active current infrastructure, not future work; a current Supabase schema/RLS/RPC change is allowed when a concrete active feature genuinely needs it and the bounded task approves it. Do not add Docker/local-database CI, paid Supabase environments, or extra RPC-hardening/verification infrastructure merely for speculative future-safety.
- `services/api` remains architecture-only (ADR-0007) until a separately approved implementation slice starts it. Documenting or planning it does not authorize writing backend code.

## Git And Push Workflow

Before commit, push, or PR creation:

1. Read `docs/PUSH_TEMPLATE.md`.
2. Confirm repository state with `git status --short --branch`.
3. Keep unrelated local changes out of the commit.
4. Run the applicable validation commands from `docs/PUSH_TEMPLATE.md`.
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

For Supabase changes, use the feature task's documented migration/RLS/security checks. For a future protected backend, use the selected runtime's documented commands; do not assume a backend toolchain before its first service slice is approved.

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
