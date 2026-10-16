# #564 — Flutter Edit Routine Name + atomic Update

**Status:** In progress; pre-implementation exploration completed; no code/CI/device QA yet.
**Owner-approved goal:** Existing Create and Edit reuse the one `RoutineComposerScreen` and **same `TioInput` geometry**. Edit preloads persisted Name into its top field and performs one server-side atomic `Update` for Name-only, Sets-only or combined changes. Keep existing 3-dot **options container**; change Rename option into Edit Routine only with direct full-editor navigation. Delete #526 remains separately gated; do not offer an inert or unsafe Delete.

## Owner approval, scope, state
- 2026-10-16 user `Go next` after merging/deploying [PR #576](https://github.com/im-tnyx/tio-world/pull/576) for the exact Flutter saved-Name edit behavior confirmed earlier.
- `main@f721c247687b1a83d9bd557efa3b9a75449b6ede`, owner Windows synced `main` clean in earlier output; cannot read current Windows worktree from GitHub session.
- One implementation owner: this GitHub-connected session on branch `tnyx/issue-564-edit-routine-name-atomic-flutter`; no other open implementation PR in this scope. Historical design Draft PR #575 open; do not merge or modify it.
- Tracked in GitHub #564 and Linear TNYX-81 (parent Backlog/blocked TNYX-78 and TNYX-80; do not mark broad W4 completed). Database migration `20261016120000` merged and independently hosted-read-verified after user deployed it. No new SQL/DDL in this slice.
- No UI redesign, no second editor, no watch/app-service, no auth bypass, no Delete persistence, no fabricated performed history or Note/Rest.
- **Found source/tracker contradiction:** #564 calls 3-dot 'Bottom Sheet', but `RoutineMetadataCard` really uses Core `TioAnchoredPopup`; selecting its 'Edit' opens the **separate** `_RoutineNameSheet` from `ProgramDetailPage`. Preserve existing 3-dot container/geometry while retiring only the Rename sheet after full editor integration; don't silently convert it to a new primitive. Clarification accepted in owner conversation: keep 3-dot options surface with Edit Routine; Delete only after #526 lifecycle is real.

## Architecture/behavior baseline
- `RoutineEditorController` tracks only composition state; draft name missing; `update()` short-circuits when Sets unchanged; uncertainty only checks composition, so do NOT call separate old `RoutineRepository.rename()` plus composition save.
- Existing `RoutineCompositionGateway` uses parent owner/revision/token and bracketed child reads, signed-out/auth-change fail closed. Extend bracket with persisted Name, keep old RPC and old test mocks compatible.
- New SQL RPC `update_user_workout_routine_with_composition(p_routine_id uuid,p_program_id uuid,p_expected_revision bigint,p_expected_name text,p_client_mutation_id uuid,p_name text,p_exercises jsonb)` supports Name-only (NULL Exercises), composition-only (NULL Name), combined, and strict same-token full-request SHA256. Must send **one** RPC invocation for a logical atomic Update. In the app preserve frozen identity, baseline name/revision and mutation UUID. Do not silently retry a timed-out request as a new UUID.
- Existing Create `TioInput(hint: 'Routine name', textCapitalization: words)` top of composer; reuse exactly in Edit with persisted name. `RoutineComposerScreen` already has the same top-right Save/Update slot from PR #570.
- Runtime has a distinct owner-scoped direct Rename Data API used by legacy action. Do NOT invoke it from new Edit path. Old client API remains supported.
- Controller Custom Exercise revalidation is needed only when composition is being mutated; Name-only must not send/rewrite unchanged archived Custom/legacy rich Sets, nor fail unnecessarily on existing over-cap historical Set content.
- Async owner/login-cycle switch must revoke capability, discard old drafts, no wrong-account RPC or disclosure. App shell provides a live `canWrite` session gate and keyed editor, currently only from Routine Detail.

## Implementation/QA slices (review gates)
1. [ ] Owner-scoped, versioned Flutter RPC repository + gateway with typed frozen Name/Set request and *read-only* post-unknown reconciliation of authoritative Name/Set/revision/token. No broad interface break or extra privileged write path.
2. [ ] Controller name baseline/draft, name-only bypass composition preflight, combined Update and unknown-response cases; live auth guards, explicit conflict reload, no duplicate save. Tests with verified owner, name/sets changes, archived Custom, exact token and account-switch.
3. [ ] Existing Edit UI uses identical Create TioInput in same position, programmatically prefilled on load, no false submit if blank, no extra screen or button.
4. [ ] Existing Routine 3-dot options surface preserved and its Edit item opens the same full editor via guarded app shell. Do not display enabled Delete until #526 implements owner-confirmed deletion.
5. [ ] GitHub exact-head Flutter CI, focused test/analyze, Codex code review, fixes and independent owner phone QA before merge. No local Flutter SDK available inside this GitHub-connected session; GitHub CI is validation source. PR stays Draft/unmerged until separate owner `Go merge`.
6. [ ] Repo + Linear handoff truth, no claim app store release or real device QA.

**Known limitation:** Existing 3-dot popup is anchored, not a sheet; owner specifically instructed to keep container, not redesign it. If a truly bottom-anchored sheet is later required, that is a separate visual decision.
