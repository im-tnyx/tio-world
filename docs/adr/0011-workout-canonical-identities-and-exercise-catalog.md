# ADR-0011 — Workout canonical identities and bundled Exercise catalog

- **Status:** Accepted
- **Date:** 2026-09-23

## Context

TNYX-78 must establish one Workout identity model before Exercise Library, Programs/Routines, Training Plans, Active Workout, and history are implemented. The repository has legacy unused Workout scaffolds under `apps/shared`, while older planning text placed future capability folders under `apps/features/workout`.

The built-in Exercise catalog is being authored as versioned JSON and will continue to grow. Its completeness must not block domain work, and duplicating built-in catalog content into Supabase would create competing truth. Existing source/legacy numeric IDs are not stable enough to become Tio identity.

Repository ownership rules and the validated Nutrition precedent place durable pure-Dart entities/value objects in `apps/shared` while feature behavior and data-source composition stay in the owning feature package.

## Decision

1. **Canonical Workout domain placement**
   - `apps/shared` owns durable pure-Dart Workout IDs, value objects, canonical entities, and historical snapshot contracts.
   - `apps/features/workout` owns Workout-specific repository interfaces, catalog/user data sources, controllers, presentation, and feature composition.
   - Existing Workout Profile/Targets files are not moved by this ADR; migration requires a separately justified slice.

2. **Built-in Exercise catalog identity**
   - The built-in Exercise catalog remains versioned bundled application content.
   - A stable `ex_*` value is the canonical identity for a built-in Exercise.
   - Identity is not re-derived from mutable title or slug values.
   - Legacy/numeric/source IDs remain lookup/integration metadata only.
   - New well-formed `ex_*` IDs may be added as the catalog grows without changing domain architecture.
   - Once an `ex_*` ID ships, rename/reuse/removal requires an explicit migration.

3. **Persistence boundary**
   - Built-in catalog rows are not mirrored into Supabase.
   - User-created Exercises and user relationships are separate user-owned dynamic data for later approved persistence slices.
   - Routine/Program/PlannedWorkout/WorkoutSession/Favorite/Folder contracts reference canonical Exercise identity rather than cloning built-in catalog truth.
   - Completed WorkoutSession design must snapshot the performed data needed to keep history stable if catalog/template content later changes.

4. **Set terminology**
   - Template/prescription sets are `SetPrescription`.
   - Actual performed historical sets are `PerformedSet`.
   - `WorkoutSet` is not part of the new canonical model.

5. **Legacy shared scaffolds**
   - Existing unused `apps/shared/lib/src/workout/**` scaffolds are non-canonical.
   - They are removed in an isolated W1A7 cleanup before new W1A1 canonical identities are introduced.

6. **Explicit deferrals**
   - Curated Routine/Program namespace and revision/fork semantics are deferred to W1A3/W1A4.
   - Set measurement kinds and `SetPrescription` fields are deferred to W1A3; this ADR does not choose any measurement.
   - Saved/Following/Owned semantics are deferred to W1A4.
   - TrainingPlan/PlannedWorkout provenance and planless scheduling are deferred to W1A5.
   - Quick Start/ad-hoc session, PlannedWorkout→WorkoutSession cardinality, and session local-date/timezone semantics are deferred to W1A6a.
   - Persistence encoding/table/repository shapes are deferred to W1B0.
   - Compatibility when an older or offline phone/watch client receives a Routine/Program/PlannedWorkout/WorkoutSession reference to a built-in `ex_*` ID that is absent from its bundled catalog is deferred to W1B0/W3. That later work must choose and validate an approved contract (for example minimum catalog/version compatibility, graceful unknown-ID fallback, or a sufficient reference snapshot). This ADR does not select a mechanism, does not add schema fields, and does not change the rule that built-in catalog rows are not mirrored into Supabase.
   - Physical Exercise asset path, JSON loader/schema validation, standards evaluation logic, and licensing/attribution gate are deferred to W3.

## Alternatives

### Put all Workout domain entities under `apps/features/workout`

Rejected for new durable identities because it conflicts with the repository's shared pure-Dart domain boundary and the established Nutrition precedent. Feature-specific behavior remains in the feature package.

### Mirror built-in Exercises into Supabase

Rejected because it creates duplicate canonical truth and unnecessary synchronization/versioning work for content that can ship with the app.

### Use slug or legacy numeric IDs as Exercise identity

Rejected because slugs/titles are mutable and legacy IDs may be multiple/source-specific. They remain metadata.

### Keep `WorkoutSet` as the shared set name

Rejected because it does not distinguish prescribed template state from performed historical state.

## Consequences

- W1A1 can define `ExerciseRef` and approved root IDs without waiting for the Exercise catalog to be complete.
- W1A7 must run before W1A1 so stale competing shared types cannot be reused accidentally.
- Adding exercises or changing non-identity catalog metadata does not require a domain redesign.
- Built-in Exercise content stays offline-capable and does not depend on Supabase availability.
- Supabase persistence design remains intentionally deferred until real user-owned data shapes are approved.
- Cross-platform consumers can share stable pure-Dart Workout entities without importing Flutter feature presentation/data-source code.
- Existing Profile/Targets models remain in their current feature location until a separate migration is justified.
- This ADR does not resolve the Quick Start/ad-hoc session conflict.

## Links

- Linear: TNYX-78 — W1 Workout domain identities, IA, persistence & folder ownership
- [Active decisions](../../.ai/DECISIONS.md)
- [Module ownership](../MODULE_OWNERSHIP.md)
- [Exercise Search](../screens/exercise-search.md)
- [W1A0 task brief](../../.ai/tasks/tnyx-78-w1a0-workout-canonical-identities.md)
