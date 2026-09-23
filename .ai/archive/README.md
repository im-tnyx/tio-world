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
