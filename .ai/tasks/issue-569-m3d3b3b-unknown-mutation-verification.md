# GitHub #569 — M3D3B3b UNKNOWN Move mutation readback

**Status:** In progress; implementation / CI / review pending
**Implementation owner:** Workout domain/data repository
**Related:** GitHub #569, merged PR #612, Linear TNYX-81 / TNYX-267
**Base:** protected main@4b9404f4e6a93239f8ddab597eb6b55efdb7c1b0
**Branch:** `tnyx/issue-569-m3d3b3b-unknown-mutation-verification`
**Owner approval:** normal correctness subtask within owner-approved #569 Move Routine. User 2026-10-19: "Next work start kare ... Next work go with audit Follow agent.md". No new product-visible interaction or DB shape.

## Discovery and runtime evidence
- Root and apps/features AGENTS, canonical docs, ADR/UI acceptance via #569, workflow, PR/push template, previous B3a task and actual data/flow sources read.
- PR #612 merged, protected main@4b9404f4e6a93239f8ddab597eb6b55efdb7c1b0; main post-merge Flutter CI successful; no other open PR when branch created.
- Move data adapter has _unknown owner-scoped header read and owner+Routine CAS UNKNOWN gate; existing B3a invalidates Program lists but expressly cannot identify which RPC committed.
- Both Move SQL variants write `last_composition_mutation_id` and increment `composition_revision` atomically with Program reparent. Live Tio Supabase authenticated SELECT privilege exists on mutation/revision/Program columns, but Move EXECUTE remains false and atomic Create+Move RPC is absent.
- Documentation drift: .ai/tasks/README.md still describes B3a as in progress; live PR #612 is merged.

## Chosen bounded behavior
- Freeze original Move attempt (owner, login cycle, Routine, source, target, expected revision and generated mutation UUID) only when RPC outcome becomes UNKNOWN. Never expose Create draft, authentication credentials or cross-owner records.
- Offer an optional read-only repository capability for manually invoked owner/session-bound verification: exact latest server mutation token + destination + expected revision+1 means **that request is observed committed**. Missing, unchanged, different token, later revision, read failure and auth-cycle rotation cannot be reported as confirmed.
- Do not retry the RPC, invent Program or Routine data, or turn generic list refresh into a transaction receipt. Do not clear CAS UNKNOWN merely on an early negative read. The existing later-revision CAS supersession may retire the process-local hold after verified owner read.
- Prefer the existing Workout repository and process-local gate over a new global registry/server endpoint. Read-only API only; no visible UI changes in B3b.

## Scope and non-goals
- **In:** Workout domain/data verification contract, repository readback, focused fake gateway/owner/cycle/CAS tests and docs handoff.
- **Out:** production Move enablement, SQL migrations/grants/deployment, direct UPDATE, auth/security weakening, retry/autoplay, real 5s Undo, new UI/pill, persistent recovery across app restart, cross-device mutation feed.
- Existing Python/Windows local checkout, Flutter CLI and physical device are not accessible through GitHub connector; never claim them tested.

## Quality gates
- [ ] Exact-head hosted Flutter analyzer/app-workout/core-wear/nutrition/aggregate CI
- [ ] Attribution guard
- [ ] Codex/manual security review and disposition
- [ ] Separate user Go merge, **not requested**
