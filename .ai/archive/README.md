# Archive

This folder keeps concise records of completed or superseded AI task briefs. It preserves decision context without letting old work appear active.

## What Belongs Here

- A task brief whose outcome is validated.
- A task brief superseded by a newer approved direction.
- A short retrospective only when it contains a durable lesson that cannot live in canonical documentation.

## What Does Not Belong Here

- Active work, open questions, or an unvalidated implementation.
- Full chat transcripts, terminal output, logs, generated artifacts, or temporary plans.
- Secrets, personal data, credentials, machine-specific paths, or copies of source code.

## Archive Procedure

1. Update the task status to `Validated` or `Superseded` and add the completion date.
2. Ensure durable product, architecture, or ownership decisions are recorded in canonical docs and, where useful, [DECISIONS.md](../DECISIONS.md).
3. Move the task brief here with a stable name: `YYYY-MM-topic.md`.
4. Add one row below with the archive date, outcome, and canonical reference.

## Archived Tasks

| Archived | Task | Outcome | Canonical reference |
|---|---|---|---|
| 2026-09-24 | [TNYX-78 W1A0 — Workout canonical identities and terminology](2026-09-tnyx-78-w1a0-workout-canonical-identities.md) | Validated; merged via PR #324 (`45c194e0`) | [ADR-0011](../../docs/adr/0011-workout-canonical-identities-and-exercise-catalog.md), D-019 in [DECISIONS.md](../DECISIONS.md) |
| 2026-09-24 | [TNYX-258 W1A7 — Stale shared Workout scaffold cleanup](2026-09-tnyx-258-w1a7-stale-workout-scaffold-cleanup.md) | Validated; merged via PR #327 (`ec1f94c9`) | [ADR-0011](../../docs/adr/0011-workout-canonical-identities-and-exercise-catalog.md), D-019 in [DECISIONS.md](../DECISIONS.md), [MODULE_OWNERSHIP.md](../../docs/MODULE_OWNERSHIP.md) |
| 2026-09-24 | [TNYX-259 W1A1 — Canonical Workout identity value objects](2026-09-tnyx-259-w1a1-workout-identity-value-objects.md) | Validated; merged via PR #329 (`17de0500`) | D-019 in [DECISIONS.md](../DECISIONS.md), [ADR-0011](../../docs/adr/0011-workout-canonical-identities-and-exercise-catalog.md) |
| 2026-09-24 | [Workout Library / Exercises / Explore IA reconciliation](2026-09-workout-library-exercises-ia-reconciliation.md) | Validated; merged via PR #331 (`65353fec`) | D-020 in [DECISIONS.md](../DECISIONS.md), [Library](../../docs/screens/library.md) |
