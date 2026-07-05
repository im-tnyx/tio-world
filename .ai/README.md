# AI Context

This directory gives AI assistants and contributors a concise orientation to **TNYX / tio-world**.

It is intentionally short. It is not a replacement for canonical repository documentation.

## Start Here

Read these files before making architecture, module, data, or workflow decisions:

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

- Flutter for Android phone and iPhone mobile UI.
- Native Kotlin + Compose for Wear OS.
- Native Swift + SwiftUI for Apple Watch.
- Shared Dart packages for mobile app logic where practical.
- Backend and AI work behind server-side boundaries.

## Canonical References

Use these documents as the source of truth when available:

- [Root README](../README.md)
- [Contributing Guide](../CONTRIBUTING.md)
- [GitHub Contributing Pointer](../.github/CONTRIBUTING.md)
- [Pull Request Template](../.github/PULL_REQUEST_TEMPLATE.md)
- [Post-Merge Sync Guide](../docs/POST_MERGE_SYNC.md)
- [Push Template](../docs/PUSH_TEMPLATE.md)

## Priority Rule

When docs conflict:

1. Runtime source/config wins for actual behavior.
2. Root documentation wins for repository structure and current direction.
3. Platform-local docs win for platform-specific implementation details.
4. This `.ai` directory is only a concise orientation layer.

Do not invent future modules, APIs, schemas, or product behavior without a concrete feature slice or user request.
