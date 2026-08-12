# AI Context

This directory gives AI assistants and contributors a concise orientation to **TNYX / tio-world**.

It is intentionally short. It is not a replacement for canonical repository documentation.

## Start Here

Read these files before making architecture, module, data, or workflow decisions:

- [Current State](CURRENT.md)
- [Active Decisions](DECISIONS.md)
- [Implementation Status](IMPLEMENTATION_STATUS.md)
- [Feature Development Workflow](FEATURE_DEVELOPMENT.md)
- [Task Files](tasks/README.md)
- [Screen Catalog](../docs/screens/README.md)
- [Archive](archive/README.md)
- [Project Context](project-context.md)
- [Architecture Summary](architecture-summary.md)
- [Ownership Rules](ownership-rules.md)
- [Coding Rules](coding-rules.md)
- [UI Rules](ui-rules.md)
- [Supabase Rules](supabase-rules.md)
- [Workflow](workflow.md)

## Product Direction

`tio-world` is a Flutter-first health, fitness, workout, nutrition, progress, wearable, and AI coaching monorepo.

The preferred platform strategy is:

- Flutter for Android phone, iPhone, and Wear OS UI.
- Native Swift + SwiftUI for Apple Watch.
- Shared Dart contracts in `apps/shared` and lightweight design primitives in `apps/core` for Flutter feature packages and Wear OS where practical.
- Backend and AI work behind server-side boundaries.

## Canonical References

Use these documents as the source of truth when available:

- [Root README](../README.md)
- [Contributing Guide](../CONTRIBUTING.md)
- [GitHub Contributing Pointer](../.github/CONTRIBUTING.md)
- [Pull Request Template](../.github/PULL_REQUEST_TEMPLATE.md)
- [Post-Merge Sync Guide](../docs/POST_MERGE_SYNC.md)
- [Push Template](../docs/PUSH_TEMPLATE.md)
- [Onboarding Flow Architecture](../docs/ONBOARDING_ARCHITECTURE.md)
- [Supabase-First Platform Strategy](../docs/SUPABASE_STRATEGY.md)

## Priority Rule

When docs conflict:

1. Runtime source/config wins for actual behavior.
2. Root documentation wins for repository structure and current direction.
3. Platform-local docs win for platform-specific implementation details.
4. This `.ai` directory is only a concise orientation layer.

Do not invent future modules, APIs, schemas, or product behavior without a concrete feature slice or user request.

## Working Memory

Use this small memory layer to resume work safely:

- `CURRENT.md` separates verified runtime facts from documented targets and records the next decision that blocks implementation.
- `DECISIONS.md` records durable product and architecture decisions. Mark a decision superseded instead of silently rewriting history.
- `IMPLEMENTATION_STATUS.md` distinguishes documented, scaffolded, implemented, and validated work.
- `tasks/` contains focused, updateable task briefs. Read the relevant brief before starting a feature and update it only when its status or scope materially changes.
- `archive/` retains completed or superseded task briefs without mixing them into active work.

Keep this directory concise. Do not store secrets, machine-specific paths, chat transcripts, transient terminal output, or unverifiable implementation claims here.
