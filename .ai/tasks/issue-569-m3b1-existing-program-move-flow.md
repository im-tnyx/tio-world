# #569 M3B1 — Feature-owned Move selector and confirmation

**Status:** Active Draft PR [#598](https://github.com/im-tnyx/tio-world/pull/598), safely reconciled with protected `main@f58fbc34` after squash-merged controller #597. Reconciled source/test HEAD `6391776670e68f5bf539944d1754b8d5a6a554ac` verified by [Flutter CI #39062399593](https://github.com/im-tnyx/tio-world/actions/runs/39062399593) **7/7 PASS**; any later docs-only HEAD requires its own checks. No owner merge gate completed. Not app-wired, not shipped.
**Implementation owner:** Workout feature presentation UI/confirmation branch `tnyx/issue-569-m3b1-existing-program-move-flow`. Owner of validation/dispatch: merged `RoutineMoveDestinationController`; no competing Move authority.
**Planning:** GitHub #569 owner-approved Move lifecycle; Linear TNYX-81 remains broad Backlog and TNYX-267 tracks W6B; dependency status unchanged.
**Affected scope:** Workout Flutter feature UI/test, public feature export and this active task/index. No app shell, Wear OS, watchOS, backend, SQL, RLS, deployment or visible runtime activation.

## Product agreement and precise slice

- Owner-approved existing-Program path: Routine three-dot Move → owner Program selector → confirmation naming Routine and target Program → ONE owner-scoped protected Move RPC. The persisted Routine, Exercise and Set identities remain unchanged.
- Reuse existing `ProgramRepository.list()`, M3A `RoutineMoveRepository.inspect/move`, merged controller and Core `showTioEditorSheet`, `TioCard` and `TioButton` without an unrelated visual redesign. Do not identify default My Program by mutable name.
- Dormant slice only: no app-level `onMove` provider/callback, cross-operation Create/Edit/Delete mutex, source/destination refresh wiring, `+ New Program`/atomic Create & Move, #568 canonical My Program identity or production grant. **Keep Move unavailable to real users until those separately gated requirements are implemented.** When no eligible destination exists, current dormant flow still shows an informational message rather than the final owner-approved `+ New Program` first-row UX; do not claim acceptance is complete.
- Explicit close/cancel performs zero write; owner/login-cycle checks happen after awaits; denied/revision-conflict/unknown results must never fabricate confirmed Move or unsafe retry. A returned `true` requests a future owner-list refresh; it is not an ACK of committed persistence.

## Verified repository and review checkpoints

- Protected `main@f58fbc34e28110ef8bddfbce14756430b19ada4e` contains **squash-merged PR #597**; [post-merge Flutter CI #39060837742](https://github.com/im-tnyx/tio-world/actions/runs/39060837742) **SUCCESS**, 5/5 jobs. Parent controller itself passed pre-merge 7/7 checks and both P2 comments are resolved.
- Historical source baseline: #598 isolated `62900703` passed Flutter CI #39057336768 (5 Flutter jobs, 2 attribution); combined child before parent squash `2667ea26` passed Flutter CI #39059602212 (7/7, Workout 737 PASS and 10/10 Move widget cases).
- **Post-squash reconciled code+test HEAD `6391776670e68f5bf539944d1754b8d5a6a554ac`**: [Flutter CI #39062399593](https://github.com/im-tnyx/tio-world/actions/runs/39062399593) **COMPLETED SUCCESS, 7/7 exact-head checks** (5 Flutter jobs and both attribution checks). Workout shard **737 tests passed**, including **10/10 focused Move UI widgets** with deleted-destination zero-RPC regression. This is the current source validation checkpoint; a docs-only follow-up commit must be separately checked.
- Root `AGENTS.md`, `apps/features/AGENTS.md`, `.github/PUSH_TEMPLATE.md`, ADR-0015, canonical Routine Library contract and source reviewed. No physical device or user-data Move RPC exercised.
- Supabase hosted read-only: 64 migrations applied, `authenticated` and `anon` cannot EXECUTE `move_user_workout_routine`; authenticated direct UPDATE of Routine `program_id` denied. No GRANT or schema modification permitted in this UI slice.
- #598 previous P2 stale destination/duplicated dispatch resolved using the merged controller. The P3 outdated handoff finding was corrected and review thread resolved. Remaining **open** P3 is the owner-approved `+ New Program` first-row / atomic Create & Move *activation* gate; the live Move callback stays disabled until fulfilled.

## Post-squash branch reconciliation and quality gate

- Original stacked parent `tnyx/issue-569-m3b-existing-program-move-flow@741bd429` was squash-merged as `main@f58fbc34`. GitHub confirmed the previous child-to-main comparison was **diverged** (20 ahead / 1 behind), even though old parent-to-child delta was exactly five owned UI/test/task paths.
- Reconciliation now completed through an explicit **non-force two-parent merge commit** `73459be4c9038c69bcd108edd6ed18c511c14733`, with the five child-owned file blobs applied to the exact squash-merged `main` tree. Child PR #598 was retargeted to protected `main`. GitHub verifies **main is an ancestor** (0 behind) and the compared diff is **exactly five intended UI/test/handoff files**. Historical stacked commits remain in the DAG (23 ahead), but no duplicate parent controller source delta exists versus `main`; do not claim this is a history rewrite or clean linear ancestry. Fresh exact-head CI is still required.
- Recheck exact final HEAD Flutter tests/analysis and attribution, inspect review threads and repeat owner merge gate independently. No independent GitHub APPROVED reviewer is claimed; earlier COMMENTED reviews are source audits only.
- Repository accessed through remote GitHub integration. The owner's Windows checkout, `git status`, local Flutter execution, `git pull --ff-only`, branch pruning and local device checks were not run or assumed.

## Handoff

**Current next task:** validate this docs-only handoff update's exact head, review the five-file PR against protected main, prepare Ready-for-Review and separate owner-directed `Go merge` gate. No production Move, client grant, device QA or PR merge authorized by this brief. Future #569 M3B2 and #568/atomic Create & Move require separate execution and release gates.
