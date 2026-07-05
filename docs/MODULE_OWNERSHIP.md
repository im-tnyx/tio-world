# Module Ownership

This document defines where code should live in `tio-world`.

## Top-Level Ownership

| Path | Owner / Responsibility |
| :--- | :--- |
| `apps/mobile` | Flutter Android and iOS phone app. |
| `apps/wear` | Native Wear OS companion app. |
| `apps/design` | Design references, exported assets, and product visuals. |
| `packages/core_models` | Shared Dart models used across multiple features or packages. |
| `packages/api_client` | Typed API client and DTO mapping when introduced. |
| `packages/workout_engine` | Reusable workout calculations and rules. |
| `packages/nutrition_engine` | Reusable nutrition calculations and rules. |
| `packages/design_system` | Shared Flutter design tokens and reusable components. |
| `packages/sync_core` | Shared sync queue and sync policy when introduced. |
| `backend/api` | Public API surface and server-side route handlers. |
| `backend/ai-coach` | Coaching runtime and AI orchestration. |
| `backend/jobs` | Scheduled and background jobs. |
| `backend/db` | Database schema, migrations, seed data, and policies. |
| `docs` | Canonical architecture and process docs. |
| `.github` | GitHub templates, CODEOWNERS, PR, push, and issue workflow. |
| `.ai` | Short AI orientation files. |

Create missing paths only when a real implementation slice needs them.

## Product Feature Ownership

| Feature | Primary owner |
| :--- | :--- |
| Auth | `apps/mobile/lib/features/auth` |
| Onboarding | `apps/mobile/lib/features/onboarding` |
| Dashboard | `apps/mobile/lib/features/dashboard` |
| Workout | `apps/mobile/lib/features/workout` and reusable logic in `packages/workout_engine` when needed |
| Nutrition | `apps/mobile/lib/features/nutrition` and reusable logic in `packages/nutrition_engine` when needed |
| Coaching | `apps/mobile/lib/features/coaching` and server runtime in `backend/ai-coach` when needed |
| Progress | `apps/mobile/lib/features/progress` |
| Profile | `apps/mobile/lib/features/profile` |
| Settings | `apps/mobile/lib/features/settings` |
| Wear workout flows | `apps/wear` |
| Apple Watch flows | future `apps/watchos` if/when introduced |

## Ownership Rules

- Profile is an account and fitness hub, not the owner of workout, nutrition, coaching, or progress logic.
- Workout owns workout plans, exercises, sets, reps, rest timers, history, and workout settings.
- Nutrition owns meals, foods, calories, macros, water, targets, and nutrition settings.
- Progress owns weight, measurements, progress photos, streaks, trends, and analytics.
- Coaching may read workout, nutrition, progress, and recovery data through clear contracts.
- Watch apps own their own UI and platform integrations.
- Backend owns server-side orchestration and protected operations.

## Cross-Feature Rules

When one feature needs another feature's data:

1. Define a stable domain contract.
2. Use repository/use case boundaries.
3. Avoid importing another feature's presentation layer.
4. Avoid direct database or API shape leaking into UI.
5. Document the ownership decision if it changes architecture.

## Anti-Patterns

Avoid:

- putting feature business logic in global app shell
- sharing code too early before reuse exists
- creating empty packages for future ideas
- letting screens call APIs directly
- putting watch-specific UI into phone app widgets
- putting phone dashboard UI into watch apps
