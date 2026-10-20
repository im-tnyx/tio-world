# GitHub #569 — M3D3B3b UNKNOWN Move mutation readback

**Status:** **Validated / archived 2026-10-20.** [PR #613](https://github.com/im-tnyx/tio-world/pull/613) squash-merged as `main@a892e2dbabf19d771234f3e1d8f94d8f2c58a544` (verified `gh pr list --state merged` on 2026-10-20). Parent [GitHub #569](https://github.com/im-tnyx/tio-world/issues/569) stays OPEN. Production Move stays OFF. The historical status line is not the current handoff.
**Historical status:** **Status:** Ready for Review / merge-gate verification; reviewer P3 governance corrections applied. Actual merge is separately owner-gated.
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
- [x] Flutter CI [#39225108841](https://github.com/im-tnyx/tio-world/actions/runs/39225108841) **5/5 SUCCESS** on code+initial handoff HEAD `903040f803698cc6db4c2d3d58278d4df2517061` (app-workout, analyzer/Dart, core-wear, nutrition, aggregate).
- [x] Attribution [#39225105724](https://github.com/im-tnyx/tio-world/actions/runs/39225105724) **SUCCESS** on the same prior exact HEAD.
- [x] Author-side architecture/security [manual review #5569106776](https://github.com/im-tnyx/tio-world/pull/613#pullrequestreview-5569106776) COMMENTED (not independent APPROVED); two follow-up P3 governance findings identified at prior HEAD: [#4312018758](https://github.com/im-tnyx/tio-world/pull/613#discussion_r4312018758) and [#4312018764](https://github.com/im-tnyx/tio-world/pull/613#discussion_r4312018764).
- [ ] Recheck **new documentation-correction HEAD** CI + attribution; do not reuse prior exact-HEAD result as the new HEAD's validation.
- [ ] Codex review/inline thread disposition and latest-head scope audit. Zero earlier Codex reviews is not an independent approval.
- [ ] Separate owner `Go merge`; **not requested**.

## Merge-gate handoff — 2026-10-19
- User instructed `Merge gate tak jana hoga go`: review and validation through the merge gate, **not an unconditional merge or production enablement**.
- New correction scope limited to `.ai/tasks/README.md` P3 stale status and this handoff P3 stale CI checklist; no Workout runtime, SQL, Auth/session or UI edits.
- Previous PR source/test HEAD `903040f8` passed hosted CI 5/5 and attribution. Manual follow-up review raised two P3 governance items; document status needs to reflect completed checks without falsely claiming new commit has passed.
- Live GitHub status, PR body checkpoint and latest exact-HEAD checks govern if this documentation snapshot becomes historical. PR stays Ready for Review / unmerged until latest checks and all review findings are dispositioned.
- Supabase authenticated Move EXECUTE stays revoked, atomic Create+Move function not hosted and production Move release flag OFF; no device QA asserted.

