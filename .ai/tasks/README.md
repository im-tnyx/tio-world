# Task Files

Task files are compact, durable briefs for work that is active, blocked on one decision, or ready to hand off. They are not a backlog dump or a replacement for GitHub Issues when external tracking is needed.

## Current Tasks

| Task | Status | Primary owner | Read before |
|---|---|---|---|
| [App Mode foundation](app-mode-foundation.md) | In progress | `apps/shared`, onboarding, Settings, `apps/app`, `apps/core` | Changing phone navigation, onboarding, or Settings |
| [Adaptive navigation and action entry](adaptive-navigation-and-actions.md) | Ready | `apps/shared`, `apps/core`, `apps/app`, Settings, affected features | Designing custom tabs, Home composition, or feature action placement |
| [Material 3 Expressive foundation](material-3-expressive.md) | In progress | `apps/core`, `apps/app` | Changing shared theme, navigation, buttons, motion, or accessibility behavior |
| [Screen catalog and module plan](screen-catalog-and-module-plan.md) | Ready | `apps/app`, `apps/core`, `apps/shared`, affected features | Starting a screen or module vertical slice |
| [Supabase foundation](supabase-foundation.md) | Needs decision | future `supabase/`, `apps/shared`, affected feature | Starting Auth, data, RLS, Storage, or protected AI work |

## File Contract

Each task file should contain:

1. The seven Feature Development phases: discovery, exploration, clarification, design, implementation, review, and handoff.
2. A clear outcome, current status, verified evidence, and success criteria.
3. In-scope and out-of-scope boundaries plus ownership and dependency notes.
4. Any decision that must be confirmed before source changes begin.
5. A short implementation checklist, validation evidence, and exit criteria.

Start new feature work from [TEMPLATE.md](TEMPLATE.md). Existing task briefs may be migrated when they next become active; do not rewrite historical task state just to match the template.

Use status values `Ready`, `In progress`, `Needs decision`, `Blocked`, `Validated`, or `Superseded`. Move a task to [the archive](../archive/README.md) only after its outcome is validated or superseded and its durable decision/status has been moved to the relevant canonical doc.

Never put secrets, personal data, unverified completion claims, machine-specific paths, or full conversation transcripts in these files.
