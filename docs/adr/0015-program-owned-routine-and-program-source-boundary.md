# ADR-0015: Program-owned Routine and Program source boundary

Document Status: Architecture Decision Record
Last Verified: 2026-09-28
Owner: Workout domain architecture (`apps/features/workout` + `apps/shared`)
Truth Boundary: Authoritative for Program/Routine ownership, creation-source editing boundaries, and Program versus TrainingPlan ownership; not evidence runtime implementation is complete.

- **Status:** Accepted
- **Date:** 2026-09-28
- **Supersedes:** [ADR-0011](0011-workout-canonical-identities-and-exercise-catalog.md) for the Routine/Program ownership semantics that ADR-0011 originally deferred. ADR-0011 remains the historical identity/catalog record.

## Context

ADR-0011 intentionally deferred Routine/Program ownership and revision/fork semantics. Product direction now requires one durable ownership model before Program/Routine domain, persistence, Library W6B, AI, Coach or curated-content work can proceed.

The user-created flow must stay minimal, while Tio-curated, coach-created and accepted AI-generated Programs may carry richer source metadata. Personal scheduling/following state must not be confused with reusable Program truth.

## Decision

- A user-owned Program is the reusable container for user-owned Routines.
- A saved user-owned Routine keeps stable `RoutineId` and composition but belongs to exactly one user-owned Program. It is not an orphan top-level Library object.
- A Program may contain **zero or more** Routines. Zero is valid for a newly created draft/empty Program immediately after confirmation; executable/followable flows may impose stronger readiness requirements later.
- Library exposes Programs, Plans/Training Plans and Exercises as capabilities become ready. Routine create/edit/manage is entered from the owning Program; there is no standalone user Routines collection or top-level Create Routine action.
- Initial user-created Program creation presents a generated non-blank name such as `Program 1` before confirmation. The user may rename it before OK. The user-created Program editing surface initially exposes only name and optional image; richer metadata is not required from the user.
- Routine creation inside a Program follows the same minimal direction: generated non-blank name, with optional image as later approved media capability. Exact Routine composition fields remain owned by their bounded domain slice.
- Program remains one canonical domain capability, but persistence separates user-owned Program truth from Tio-owned source/catalog Program truth. User-owned Programs use a dedicated user-owned Program table/source; Tio-curated source Programs must not be mixed into that user-owned table.
- `user_created`, adopted Tio content, accepted AI-generated content, and eligible coach-derived content become user-owned Program records only at the explicit create/adopt/accept boundary. Their provenance/lineage remains explicit.
- Tio/Coach/AI source/catalog persistence may use source-specific protected tables/services when those slices are approved; this ADR does not pre-authorize their physical schema.
- Tio/Coach/AI Programs may carry richer source metadata such as description, goal, level, type and recommended duration when their concrete source slice defines it. The user must not receive unrestricted mutation of source-owned metadata merely because the Program is visible in their Library.
- User-adjustable schedule, start/end or follow-duration/till-date state belongs to TrainingPlan/following truth, even when edited from a Program-context UI. It is not silently written back into reusable Program source metadata.
- Curated/coach/AI adoption, copy-on-adopt, lineage and exact field-level edit permissions remain gated by their concrete slices. This ADR fixes the ownership boundary, not a speculative persistence schema.
- Optional Program/Routine images are future private Workout media. This decision does not authorize a Storage bucket, database column or upload implementation.
- Program identity/minimal ownership must be established before the saved Routine contract that requires an owning Program.

## Alternatives

- **Standalone user Routines in Library:** rejected because it permits orphan Routine ownership and creates two competing organization surfaces.
- **Require a Routine before Program confirmation:** rejected because the approved one-click Program flow creates the container first and lets the user add Routines afterward.
- **Require all Program metadata from users:** rejected because user-created Programs need only lightweight organization; richer metadata is source-specific or later editing concern.
- **Store personal schedule directly on Program:** rejected because reusable Program structure and user-specific following state have different lifecycles.
- **One physical Program table for both user-owned and authoritative source content:** rejected because ownership, write authority, RLS, lifecycle and source publication semantics differ.
- **Single physical Program table for both user-owned and Tio source/catalog rows:** rejected because ownership, mutation authority, RLS and source lifecycle differ; canonical domain capability does not require one physical table.

## Consequences

- Empty newly created Programs are representable, but cannot be treated as executable merely because they exist.
- Routine persistence must enforce Program ownership without collapsing Routine identity into anonymous nested data.
- Source/provenance and edit authority must be explicit before curated, coach or AI Program persistence is implemented.
- User-owned Program rows and authoritative Tio/Coach source Program rows must not share one physical table; adoption crosses an explicit copy/lineage boundary.
- UI may present TrainingPlan controls in Program context while domain ownership remains TrainingPlan.
- The user-owned/source Program table separation is locked, but exact table names, columns, foreign keys, Routine table shape, indexes, grants and RLS policies remain a separate approved persistence slice.
- Program/Routine persistence implementation, RLS and Storage remain separate approved slices.

## Links

- [ADR-0011](0011-workout-canonical-identities-and-exercise-catalog.md) — superseded for previously deferred Routine/Program ownership semantics
- [Module Ownership](../architecture/MODULE_OWNERSHIP.md)
- [Library](../screens/library.md)
- [Programs](../screens/programs.md)
- [Program-owned Routines](../screens/routine-library.md)
- Linear: TNYX-78, TNYX-81, TNYX-83, TNYX-267
- GitHub: PR #459
