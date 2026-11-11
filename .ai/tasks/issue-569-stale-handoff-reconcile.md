# #569 — Stale handoff reconcile (docs only)

**Status:** Docs-only release-readiness recheck [PR #641](https://github.com/im-tnyx/tio-world/pull/641), 2026-10-21. Owner (Santosh) approved earlier Option C scope; previous 2026-10-20 reconciliation is historical. Owner-local diff receipt and independent review now supplied; docs-only handoff correction/new-HEAD re-review and owner-controlled merge pending. No source, migration, grant, flag, hosted deploy, or Undo change.

## PR #626 approval

Owner (Santosh) approved [PR #626](https://github.com/im-tnyx/tio-world/pull/626)’s test-only scope on 2026-10-20. That approval is chat-only. It is recorded in the #626 brief and is not recorded on GitHub #569. Chat-only bot audit verdicts from Security #05, Engineering Auditor #01, and QA #04 APPROVE at `6e1d6f7ab45b8e5328132e1fe50185252fe2c94b` and at `56029459dfafe3038a0a7441a179a9415986a811`. Those verdicts are not GitHub reviews. GitHub shows 0 formal reviews. At write time, proof was the latest #626 head and this docs branch did not edit that PR. [PR #626](https://github.com/im-tnyx/tio-world/pull/626) later **MERGED** as squash `main@fbf132841597bae8ff41aac3e2d8d1b922b49d35`. Do not open a new product slice without explicit owner approval.

The #626 brief and README row historically said not to bulk-rewrite older #569 rows. That instruction applied to the #626 test slice. Option C, approved separately, is the archive recorded below. The pre-merge #626 README row was copied byte-identical so either PR could merge first without a README conflict; post-merge status for #626 is reconciled in a later docs-only follow-up.

**Primary owner:** Documentation handoff for GitHub #569.
**Affected platforms:** `.ai/tasks` and `.ai/archive` only.

## 2026-10-21 remote-only release-readiness recheck (current checkpoint)

**Scope/ownership:** Documentation and gate-evidence continuation of approved GitHub #569 Move Routine, not a new Move/Undo product implementation. GitHub #569 / Linear TNYX-81 own planning. This GitHub-connected session owns only this handoff and its task-index row. No ownership transfer of Flutter source, database migrations, or the owner's Windows checkout is claimed. `im-tio` independent review has occurred, most recently [review `5594915887`](https://github.com/im-tnyx/tio-world/pull/641#pullrequestreview-5594915887); disposition CHANGES_REQUESTED for stale validation handoff/CI applicability, not a product-code finding.

**Verified GitHub/Linear:** Protected `main@da3a94ce9bde2c2e6fdf3ef367a3aad55a28ee79` contains merged [PR #640](https://github.com/im-tnyx/tio-world/pull/640). [#569](https://github.com/im-tnyx/tio-world/issues/569) and [#568](https://github.com/im-tnyx/tio-world/issues/568) remain open; [TNYX-81](https://linear.app/tnyx/issue/TNYX-81) is Backlog and blocked by TNYX-78/TNYX-80. Move's UNKNOWN feedback regression [#616](https://github.com/im-tnyx/tio-world/pull/616) and default identity SQL regression [#626](https://github.com/im-tnyx/tio-world/pull/626) merged. Upstream #568 adapter [#637](https://github.com/im-tnyx/tio-world/pull/637), default Program identity [#638](https://github.com/im-tnyx/tio-world/pull/638), positive read-back predicate [#639](https://github.com/im-tnyx/tio-world/pull/639), and 66/66 inventory [#640](https://github.com/im-tnyx/tio-world/pull/640) merged. Older In Review rows in task briefs are historical checkpoints, not current PR state. No open Move-specific PR was found.

**Verified hosted read-only:** Connected Tio-world Supabase project `oykupyiitspujzpwwvuj` reports **66 applied migrations**, including `20261017100000` Move, `20261017154241` Rename cutoff, `20261018100000` atomic Create+Move, and `20261019162535` W1 default Program. Program and Routine tables both have RLS enabled; direct authenticated Routine `UPDATE(program_id)` remains denied in the prior privilege audit. All three `public` RPCs (`move_user_workout_routine`, `create_user_workout_program_and_move_routine`, `create_user_workout_routine_in_my_program`) report `EXECUTE=false` for `anon`, `authenticated`, and `service_role`. This **supersedes the historical 65/66 / absent-default-marker state in older 2026-10-20 sections below**. Do not reapply the already deployed W1 migration.

**Verified app hold:** `apps/app/lib/app/composition/workout_providers.dart` defines `routineMoveReleaseEnabledProvider = Provider<bool>((ref) => false)`. `TIO_MOVE_ROUTINE_UI_PREVIEW` is a debug-only zero-write capability. Dormant RPC deployment and merged implementation do not constitute production Move release.

### Remaining gates before any real Move release

1. **Security and owner approval:** independently review a separately scoped exact `GRANT EXECUTE` migration, server-side ownership/CAS/idempotency, legacy-client compatibility, security findings, and a rollback plan. Do not grant permissions under this docs-only task.
2. **Implementation / QA:** reconcile W1/W3 dependencies and the pending #568 first-Routine client/UNKNOWN path; validate the actual activation build with current-head CI, independent review, server/Flutter race cases, and Android/iOS physical-device real-write QA. The dormant test matrix does **not** establish successful real hosted moves.
3. **Product decision:** five-second real post-commit `Undo` is requested but remains unimplemented; preview Undo only dismisses a no-write pill. The owner must explicitly decide whether an independently approved real Move release can precede Undo. This audit does not approve Undo implementation.

**Validation / CI applicability (2026-10-21):** The GitHub connector itself did not run Windows git or Flutter. The owner ran a guarded read-only Windows PowerShell check from `G:\projects\Tio-World`, pinned `main@da3a94ce9bde2c2e6fdf3ef367a3aad55a28ee79` and original PR source HEAD `afd1caf42e995473a6b1359a749298466975b623`: `git diff --check` **PASS / exit 0**, exact two expected Markdown paths (`.ai/tasks/README.md`, `.ai/tasks/issue-569-stale-handoff-reconcile.md`), branch and porcelain working tree unchanged. This is **owner-provided local evidence**, not a command executed by this connector or reviewer. GitHub [attribution guard run `39486096237`](https://github.com/im-tnyx/tio-world/actions/runs/39486096237) succeeded on that original PR HEAD. The checked-in `.github/workflows/flutter-ci.yml` triggers `pull_request` only for changes to `apps/**`, key workspace manifests, `scripts/ci/flutter-test-shards.sh` and the Flutter workflow itself; this two-file `.ai/tasks/**` docs-only change does **not** match its path filter. Flutter CI is therefore **not an applicable PR-triggered check** for this docs-only slice, and the absence of a Flutter run is **not** a Flutter CI PASS. Neither release-activation CI nor device QA is implied. After the docs correction, inspect new HEAD attribution, diff/merge-base and independent reviewer disposition; do not reuse the old local exact-HEAD receipt as proof for newly changed docs. No hosted writes, grants, migrations, flags, user data, Workout source, UI, or Undo were changed.

**Next exact action:** Recheck corrected documentation PR's new HEAD, attribution guard and independent `im-tio` review; close P2 only on reviewer verification, then owner-authorized normal merge. A subsequent #568 implementation, #569 activation, or Undo slice needs its own explicit ownership and release gate; this documentation merge must never enable Move.


### PR #641 independent review status (2026-10-21)

`im-tio` re-reviewed the original docs-only HEAD `afd1caf42e995473a6b1359a749298466975b623` after the owner-local diff-check receipt. The reviewer accepted the owner-provided exact-base/head diff-check evidence; the remaining **P2** concerns a stale handoff/PR description and explicit applicability of exact-head Flutter CI to a docs-only PR. Those factual gaps are addressed in this document and PR description; the current updated HEAD is **not yet independently APPROVED**. The original source HEAD remains distinct from this later docs-only correction. Hosted activation security/physical QA/rollback/real Undo decision remain OPEN.

## Evidence used

- Base `main` at reconcile start: `59155cc7db7e29eab7d601e8a22e6d337fdd824a`.
- GitHub #569 remains **OPEN**. Linear TNYX-81 remains **Backlog** (updated 2026-10-20), blocked by TNYX-78 and TNYX-80. This slice does not close either tracker.
- Merged PR SHAs below come from `gh pr list --state merged` on 2026-10-20.
- Hosted project `oykupyiitspujzpwwvuj` read-only SQL on 2026-10-20: 65 applied versions, latest `20261018100000`. Repository has 66 SQL migrations. `20261019162535` (#568, [PR #620](https://github.com/im-tnyx/tio-world/pull/620) `main@4d7e7986fb93b0aae14c38f2b9c236585eac61bf`) is not hosted. Hosted `user_workout_programs.is_default` is false/absent.
- `routineMoveReleaseEnabledProvider` in `apps/app/lib/app/composition/workout_providers.dart` returns `false`.

## What changed

Validated child briefs whose headers still said In progress, In review, or unmerged were marked **Validated / archived 2026-10-20** and moved to `.ai/archive/`. Each file's status banner cites its PR and full merge SHA. M1 and M3B2 stay active because they are the living release-dependency record, not a finished product slice.

Archived, with merge SHA:

| Brief | PR | `main` SHA |
|---|---|---|
| M2 rename compatibility | [#591](https://github.com/im-tnyx/tio-world/pull/591) | `c12ea127e4cc74ebdde08b559bef04216b9b9f6b` |
| M2C preflight | [#593](https://github.com/im-tnyx/tio-world/pull/593) | `1188346d90fd8e1a15b77d00eae48d369bd4d817` |
| M2C cutoff | [#594](https://github.com/im-tnyx/tio-world/pull/594) | `20c1d21efe1760109b28daffa8990a9e77b4aca0` |
| M3A adapter | [#595](https://github.com/im-tnyx/tio-world/pull/595) | `59a21ba305b3265aa8d903dc3f46ee397b39219f` |
| M3B1 controller | [#597](https://github.com/im-tnyx/tio-world/pull/597) | `f58fbc34e28110ef8bddfbce14756430b19ada4e` |
| M3B1 selector | [#598](https://github.com/im-tnyx/tio-world/pull/598) | `0898fadf7d5e7bac5ed84c8b3f0dfd4000108fcf` |
| M3B2B1 selector | [#600](https://github.com/im-tnyx/tio-world/pull/600) | `55ef926e9ed1be1300061f065b8f3458019410d7` |
| M3C adapter | [#601](https://github.com/im-tnyx/tio-world/pull/601) | `b53c330303503a91b7b6131999095a21f63ebb8e` |
| M3D1 providers | [#602](https://github.com/im-tnyx/tio-world/pull/602) | `bbe255c071e064b1aab6d68e836397b0becc4352` |
| M3D2A callbacks | [#603](https://github.com/im-tnyx/tio-world/pull/603) | `11d5324fd44ff1c690417bfacf3005b02a865032` |
| M3D2B1 shell | [#604](https://github.com/im-tnyx/tio-world/pull/604) | `d3753bcda7cc0dae6a61d0c3914d78e6500fc3ea` |
| M3D3A release-off tests | [#605](https://github.com/im-tnyx/tio-world/pull/605) | `bd55f80eb0171590544205fc41a36451ab550a65` |
| M3D3B1 auth revocation | [#606](https://github.com/im-tnyx/tio-world/pull/606) | `e08d547b6cfe3c99096029f2df9c5196b6aad006` |
| M3D3C debug preview | [#607](https://github.com/im-tnyx/tio-world/pull/607) | `a69bc82443201c66c8d34e3c346db362cc2e450d` |
| M3D3B2a Move/Delete | [#609](https://github.com/im-tnyx/tio-world/pull/609) | `7801502a1d85670bc17b22d8a07a5aebd6f6b339` |
| M3D3B2b1 Edit arbitration | [#610](https://github.com/im-tnyx/tio-world/pull/610) | `d758f6652d23aa82c7542b75d940e4ce32e44e68` |
| M3D3B2b2 pending Create | [#611](https://github.com/im-tnyx/tio-world/pull/611) | `948ad092562eab45590eac42411a61d93c28a52a` |
| M3D3B3a refresh fan-out | [#612](https://github.com/im-tnyx/tio-world/pull/612) | `4b9404f4e6a93239f8ddab597eb6b55efdb7c1b0` |
| M3D3B3b UNKNOWN readback | [#613](https://github.com/im-tnyx/tio-world/pull/613) | `a892e2dbabf19d771234f3e1d8f94d8f2c58a544` |
| M3D3B3c UNKNOWN feedback | [#614](https://github.com/im-tnyx/tio-world/pull/614) | `428e2c6506533b2b4aecf0ae7f3b94835171f438` |
| M3D3B3d cross-path receipt | [#615](https://github.com/im-tnyx/tio-world/pull/615) | `173b5d979c5952d1a492c7c050ddcf6b4001920a` |

Already archived before this slice: B3e [#616](https://github.com/im-tnyx/tio-world/pull/616) `main@8d25bde88f3de0d8b896b4a30d3312b1e92f7ee0`. Docs follow-up [#617](https://github.com/im-tnyx/tio-world/pull/617) `main@8295659a5b976cd4bbb50d5a8ca244c2c186f8de`.

Updated in place, not archived:

- [M1](issue-569-routine-move-existing-program-db.md) — [#588](https://github.com/im-tnyx/tio-world/pull/588) `main@5a9e9f46d2d114ff6eefac7aeb9b5341f24e6a65`.
- [M3B2](issue-569-m3b2-atomic-create-program-and-move-db.md) — [#599](https://github.com/im-tnyx/tio-world/pull/599) `main@2c5a2638fdb3eba7daef27a91eb09415fda9543b`. The brief's “PR #618 unmerged” sentence was false: [#618](https://github.com/im-tnyx/tio-world/pull/618) merged `main@3d75d1b1224519d8a2a49c6528b1b4641fe5ebf0`.

Archive is permitted because each child slice outcome is merged and the durable release hold (flag false, EXECUTE revoked, debug preview zero-write) is already in [DEVELOPMENT_SETUP.md](../../docs/development/DEVELOPMENT_SETUP.md). This slice does not edit `docs/data/SUPABASE_STRATEGY.md` or `docs/screens/routine-library.md`; GitHub #250 owns that cleanup.

## Stale RPC comment

The comment on `public.move_user_workout_routine` in `supabase/migrations/20261017100000_move_user_workout_routine_between_owned_programs.sql` says EXECUTE is withheld until legacy Rename compatibility is retired. Hosted `obj_description` matches that sentence, and version `20261017100000` is already applied. The migration file was not edited. The correction is recorded in the M1 brief: M2C [#594](https://github.com/im-tnyx/tio-world/pull/594) retired direct authenticated routine `UPDATE(name)`. The live hold is the Flutter activation gate and a future reviewed EXECUTE grant.

## Production Move activation gates

Read-only on 2026-10-20. Nothing here grants, deploys, or flips the flag.

### Security

| Gate | Verified state | Evidence | Approval needed |
|---|---|---|---|
| EXECUTE grant migration review | Not started. Both Move functions exist and are dormant. | Hosted SQL: `move_user_workout_routine` and `create_user_workout_program_and_move_routine` are `SECURITY DEFINER`, `search_path=''`, EXECUTE false for public/anon/authenticated/service_role. | Owner plus Security & Data Integrity before any `GRANT EXECUTE` migration. |
| RLS / owner checks | RLS enabled. Authenticated routine UPDATE columns empty. Program `name` UPDATE remains. `program_id` is not an authenticated UPDATE column. | Hosted `pg_class.relrowsecurity` true for `user_workout_programs` and `user_workout_routines`. Column privileges query returned only `user_workout_programs.name`. | Security review of any future grant against owner, revision CAS, and idempotency already in the functions. |
| SECURITY DEFINER audit | Functions are definer-owned with empty `search_path`. No new audit sign-off for activation. | Same hosted catalog read. Atomic comment already names the Flutter activation gate. M1 comment is stale and left in applied history. | Independent security review of the exact grant migration, not a comment-only edit. |
| Hosted migration ledger, including #568 drift | Repo 66 / hosted 65. Latest hosted `20261018100000`. `20261019162535` is on `main` and not applied. Hosted `is_default` absent. | `supabase_migrations.schema_migrations` plus `information_schema.columns`. [PR #620](https://github.com/im-tnyx/tio-world/pull/620). | Separate owner authorization before any hosted apply of #568. Do not deploy it to make Move executable. |

### QA

| Gate | Verified state | Evidence | Approval needed |
|---|---|---|---|
| Automated tests | Merged disposable SQL and Flutter matrices cover dormant Move, CAS, auth revocation, arbitration, and UNKNOWN paths. They do not prove a live permissioned write. | Merged PRs #588–#616 listed above. [PR #626](https://github.com/im-tnyx/tio-world/pull/626) disposable default-identity regression later merged as squash `main@fbf132841597bae8ff41aac3e2d8d1b922b49d35`; it was outside this docs slice at write time. Production Move remains OFF. | QA accepts the exact activation build's CI, including any new grant migration tests. |
| Physical-device QA, Android and iOS | Debug preview only. Owner phone UI PASS for #607 was zero-write. No physical-device pass of a real Move write. | [PR #607](https://github.com/im-tnyx/tio-world/pull/607) `main@a69bc82443201c66c8d34e3c346db362cc2e450d`. [DEVELOPMENT_SETUP.md](../../docs/development/DEVELOPMENT_SETUP.md) debug define `TIO_MOVE_ROUTINE_UI_PREVIEW`. | Owner device QA on Android and iOS after a reviewed activation build. |
| Concurrency / UNKNOWN | Covered in CI for dormant code: revision conflict, one-use gate, UNKNOWN readback, cross-path receipt. Not exercised as live hosted writes. | PRs #609–#616. | QA sign-off on those scenarios against the activated grant, including two-device conflict. |

### Release

| Gate | Verified state | Evidence | Approval needed |
|---|---|---|---|
| `routineMoveReleaseEnabledProvider` | Hard `false`. | `apps/app/lib/app/composition/workout_providers.dart`. | Explicit owner approval to change the provider. A flag flip is product-visible. |
| Rollout / rollback plan | Not approved. Prior dormant slices say disable Move before any legacy Rename restoration. Direct routine Rename is already cut off on hosted. | [PR #594](https://github.com/im-tnyx/tio-world/pull/594). Flag source above. | Release owner writes the rollout and the rollback (flag back to false, and revoke EXECUTE if a grant shipped). |
| Hosted deploy authorization | M1 `20261017100000`, M2C cutoff, and atomic `20261018100000` are already applied dormant. #568 is not. No new Move deploy is authorized. | Hosted ledger read 2026-10-20. | Owner authorization for any further hosted migration. |

### Product / UX

| Gate | Verified state | Evidence | Approval needed |
|---|---|---|---|
| Visible Move UI | Hidden while the release provider is false. Debug preview is opt-in and zero-write. | Provider source and DEVELOPMENT_SETUP.md. | Owner approval before exposing production Move. |
| Five-second real Undo | Planning acceptance only. Not implemented. Debug Undo only dismisses a zero-write pill. Create & Move Undo must not delete the new Program (#567). | GitHub #569 body, 2026-10-19: “Obtain exact bounded-slice owner approval before implementing.” | Undo is **not** recorded as a prerequisite that blocks a separately approved activation. It is also **not** approved to build. Product owner must say whether activation may ship without real Undo. |
| My Program identity | Source merged in #620. Not hosted. Flutter program reads do not depend on `is_default` for this docs finding. | PR #620; hosted column absent. | #568 owner if activation must depend on default-program identity. |

## Non-goals

No EXECUTE grant, no flag change, no hosted Supabase write, no new migration, no Undo implementation, no canonical `docs/` rewrite, no unrelated task edits.
