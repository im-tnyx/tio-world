# W4 Routine Flutter PR consolidation / integration gate

**Status:** In progress / integration review.

## 2026-10-15 post-review 2 P2 auth/profile gate

Fresh Codex automated review of **exact `f2abb3fe125bc46516ec59f85e1857c71603b4cb`** arrived after [Flutter CI #38695799579 SUCCESS](https://github.com/im-tnyx/tio-world/actions/runs/38695799579) and all three prior P2 source fixes. It added two P2s: `PRRT_kwDOTOXwB86sqRsx` (pending Create reservation stranded if a revoked old-cycle RPC later returns **definite rejection**) and `PRRT_kwDOTOXwB86sqRs5` (null Custom profile hides historical saved metric targets and current null compatibility wildcard permits unsafe Update). 24 total / 18 unresolved threads. Owner Routine UI accepted; no new screen, schema/SQL, token, migration or cross-module infrastructure.

**Approved correction of original W4 review behavior:**
1. A definite rejected atomic Create must release the **identical** reserved Routine+mutation command even after its page/controller has been disposed by auth cycle revocation, but only while the current pending gate belongs to the SAME owner. Never release uncertain/timeout writes; never open old-session private UI, never mutate another owner's pending gate, and never free a newer command. Keep app restart limitation explicit. Add real held-RPC same-owner cycle widget integration and controller tests, plus normal/unknown/different-owner negative controls.
2. `routineEntryMeasurementProfile(null, persisted Sets)` derives a **presentation-only** distance/duration profile from actual persisted metric fields when Custom metadata lost its Exercise Type, not a newly persisted source of truth. `RoutineCompositionLimits.targetsMatchExerciseType(null, ...)` must fail closed for existing metric targets during Update, providing actionable remediation. Preserve all original UUIDs/targets and never pretend KM/TIME is KG/REPS. Test read-only Detail/Edit rendering, rejected Edit with zero writes, and legacy nullable untyped Reps/Load stays supported.

**Validation:** CI on new exact head and second Codex re-review; 3 earlier P2 review threads have evidence replies but remain unresolved. #534 server archived Custom race, #559 nullable-Reps old installed client compatibility, hosted #536/#540 migration release sequencing, device QA and final owner merge gates remain blocked. No production deployment or cleanup.

---


## 2026-10-15 Codex exact-head 3 P2 review follow-up

**Reconciled source:** Latest Codex reviewed `cf4e5b3ff1614b33006581600ea2ec891a2a435c` with Flutter CI #38692605004 + attribution guards PASS, and reported three **new** P2 threads `PRRT_kwDOTOXwB86sp4uS` (historical 9+ Set Update), `PRRT_kwDOTOXwB86sp4uX` (pre-execution `PGRST203` Create rejection), `PRRT_kwDOTOXwB86sp4ua` (stale Custom Exercise type/Set-target compatibility on Create AND Edit). 22 threads total, 16 unresolved. Owner accepted Routine UI; this is the already-approved bounded PR #551 code review gate, not a new screen/visual/DB task. Existing branch remains only implementation owner; preserve UI and database compatibility.

**Implementation sequence, one slice at a time:**
1. Enforce `RoutineCompositionLimits.maxSetsPerExercise=8` on **controller Update** and show actionable message while preserving read/edit/removal of legacy 9+ Set rows. Zero RPC for over-cap drafts, tests including first invalid then corrected retry; don't hide or delete historical rows automatically.
2. Treat PostgREST `PGRST203` overload-resolution (HTTP 300, pre-RPC) as a definite `invalidRequest` rejection, not unknown, with real SDK MockClient test, preserve 5xx/transport uncertainty and JWT mapping.
3. Before Create/Update RPC, validate current active Custom Exercise measurement type against the draft's selected/expected profile and stored prescription fields. No stale KG/REPS↔KM/TIME writes, no imaginary conversions, zero RPC and editable guidance, preserve historical referenced Exercise IDs. Unit and async owner-change tests; check supported types via existing enum/taxonomy, no model/schema change.

**Gates:** Only exact-head CI and independent Codex reviewer disposition may close review findings; preserve #534 server-side Custom archive race, #559 older-client null-Reps rollout, 55-migration hosted ledger (new migrations #536/#540 merged source but not deployed), no device QA claim, no merge/deploy/ancestors cleanup. Check repo-side file Sha/head before each remote write; the GitHub connector does not expose local git worktree status.

---


## 2026-10-15 Codex latest-head two P1 review fixes (active)

**Owner instruction and boundaries:** Owner accepted current Routine UI and explicitly said `Go` to advance gate. The follow-on `@codex review` on #551 head `c13bc1a4206532cd89a49bd65d6bca5a2d3a1d8c` returned TWO NEW P1 threads (19 total, 13 unresolved). Normal bounded review remediation on the same exclusive implementation branch. No redesign, new UI, new screens, services, Supabase columns/migrations, merge or deployment.

1. `PRRT_kwDOTOXwB86soz-m` app shell `shell_route.dart:481`: auth/login-cycle revocation while `RoutineCreateController` RPC is `saving` forcibly disposes draft before pending mutation is transferred to `RoutinePendingCreateGate`. In-process same-owner reauth can create a second Routine while first RPC commits. Design must preserve opaque immutable attempt only for same owner, never expose old-session UI, verify under NEW owner-authenticated capability, never authorize write from revoked route, and retain fail-closed unknown status. Different owner must clear the pending identity. Existing in-memory guard does NOT solve process restarts.
2. `PRRT_kwDOTOXwB86soz-t` `EditRoutinePage._setEditor` ignores `_blankSetIds` for a valid `Rest & set details` replacement. Definite RPC rejection unmounts/remounts list and displays blank inline Reps despite saved draft value; accepted sheet change should remove stale blank marker before controller save. Preserve untouched genuinely blank/null Reps.

**Validation:** add unit/widget tests for in-flight Save revocation, same-owner next-cycle gate survival and eventual positive verification, different-owner discard, no second Create writes, continued overlay revocation; advanced-sheet Reps persisted visibly after definite rejected Update with same Set ID. CI rerun on exact new head and request review on the two new P1 threads. Existing CI #38684571808 SUCCESS only at *old head*, so it is not evidence for new commits. Independent review and hosted DB/client compatibility #559, Custom/Edit race #534, physical QA and owner release authorization remain open.

---


## 2026-10-15 approved #556 Custom media-slot selection alignment slice (active; validation pending)

**Approval and ownership:** Owner explicitly said `Go` to existing PR #551 merge-gate plan; immediate first task is their reported Custom Exercise thumbnail/icon and selection badge bug tracked by [#556](https://github.com/im-tnyx/tio-world/issues/556). Existing #551 branch `tnyx/routine-set-boxed-fields-compact-add-set` remains the single implementation owner for this W4 selection presentation regression. No branch takeover, extra PR, unrelated new Custom editor or Exercise Detail changes. This remote connector does not expose the owner's local worktree; do not claim local `git status`, Flutter runtime or physical device QA.

**Verified pre-change:** PR #551 open main-based head `477c6cfde92e9877ccd840e69f6cf123176588a9`, main `6a76011f10be1828b1dc661b2293de6ae41e775b`. `ExercisesPage` renders canonical Custom and Catalog sections in one page and supplies `thumbnailUrl:null` for user-created rows. `ExerciseListRow` currently paints thumbnail only if URL nonnull, leaving Custom rows text-shifted and putting the 18dp selected check at row trailing edge in multi-select. Selected catalog thumbnails have a 56dp+12dp footprint with an upper-right 18dp badge. Existing focused tests in `routine_exercise_picker_test.dart` cover Catalog badges, but not Custom badge placement. Core theme README and feature AGENTS read; no Core contract change requested.

**Bounded change:** In existing `ExerciseListRow` only, render an exercise-relevant `Custom` fallback icon in the same Core-governed 56dp/12dp media footprint as Catalog thumbnails, including normal browse. In selection mode selected Custom shows the existing badge overlay on the fallback icon slot's upper-right rim rather than trailing. Keep Catalog image network failure contract, text-only no-thumbnail Catalog behavior, existing `Custom` badge, List/Search, Create and Edit navigation, haptics, semantics and no writes before Save unchanged. Add focused widget coverage for unselected/selected, alignment and light/dark/320dp. Reuse `TioSize`/`TioSpacing`/`TioRadius`, no new token or data model. Do not touch W3D required-field #558 or detail #557.

**Validation/review gate:** Push source+test to #551, verify exact new head, CI, thread state and independently review the diff. Mark review pending until verified; inherited #544/#546 and the 11 currently unresolved #551 threads need independent disposition. Supabase #536/#540 source is merged but production migration ledger ends at 55/`20261010061809`, so app release/merge remains gated on secure migration/old-client compatibility, #534 race, independent security review, real device QA and owner authorization. No merge, ancestor closing or migration/deployment in this slice.


**Approval evidence:** On 2026-10-14 the owner requested a reduction from many Routine feature PRs, then explicitly said "Go" after the plan to consolidate seven stacked Flutter PRs into one without inventing new PRs. This is **not** approval to merge, deploy, expand the feature, change database schema, or rewrite history.

**Implementation/coordination owner:** current connected GitHub session on existing branch `tnyx/routine-set-boxed-fields-compact-add-set`. Ownership transition: existing W4B1/Create/Set/visual branch implementations are frozen for further edits; this consolidated integration branch owns all fixes to that combined Flutter implementation until handoff. **Independent review owner:** not yet assigned. **Planning:** Linear [TNYX-81](https://linear.app/tnyx/issue/TNYX-81/w4-programs-and-routines-canonical-content-composition-and-builders) remains Backlog, blocked by TNYX-78 and TNYX-80.

## Active bounded P2 remediation — unknown Create exit (2026-10-14, pending validation)

**Approval and scope:** Owner said “Go” to the next #551 integration P2 fix, following independent source review [#551 discussion r4269785813](https://github.com/im-tnyx/tio-world/pull/551#discussion_r4269785813). Implementation owner remains the consolidated #551 branch; old stacked Flutter PRs stay frozen. This normal review-finding remediation covers Create's uncertain-outcome exit/back behavior, truthful parent Program refresh, and focused route/widget tests; no schema, Supabase deploy, shared contract change, Core design change, rollout decision, or separate PR.

**Source/runtime finding:** `RoutineCreateController._attempt` freezes Routine+mutation IDs on an ambiguous response, but `CreateRoutinePage.PopScope` only blocks while saving and Cancel directly pops. `ProgramDetailPage._openCreate` refreshed only after `true`, so an already-committed unknown Create could stay unseen. Re-entering generates different IDs, outside atomic Create's same-UUID idempotency.

**Decision:** Preserve normal Cancel and Back when safe. On `outcomeUnknown` intercept both and use a one-off explicit warning/action policy: stay and retry read-only Verify, or consciously exit to check Program. The app shell tells Program Detail to re-read its owner-scoped list upon that explicitly unconfirmed exit without claiming the write was acknowledged. Never auto-retry a write or invent a stable-idempotency guarantee after a route/process restart. Test: committed RPC + lost response → Cancel/Back warning; no accidental second write; explicit exit refreshes Program list. If read remains unavailable, this is still a user-informed risk requiring old/new-client staging/review acceptance, not a provably cross-session no-duplicate solution.

**Validation before edits:** exact remote PR #551 head `16bd4e3d9ad7166ab97bb68acf96f7fe5e32710c` Draft/main; one new P2 inline thread; GitHub CI #38531453666 passes on **old** head and is not evidence for remediation. GitHub API work surface has no local checked-out worktree or Flutter SDK; inspect remote API file blobs/parent SHA and require new exact-head CI after push. TNYX-81 Backlog blocked by TNYX-78/80; DB #536/#540 separately Draft/undeployed. Current P2 task status **In progress**, independent review owner still unassigned.

**Implementation checkpoint:** Added reusable Core `showTioConfirmationBottomSheet` on unknown Cancel/Back, explicit exit callback to app composition, and Program re-read when outcome is uncertain; regression tests cover warning, zero automatic retry, and committed response-loss refresh. Code head `7c88562805b981ad51afb6ae0812d094cd206064` is pushed to Draft #551; **exact-head Flutter CI pending**. Before merge, review whether a durable attempt policy is required for cold-restart/network-delay cases; no claim of cross-session idempotency. No merge or ancestor closure is authorized.

## Current verified integration checkpoint — 2026-10-14 (supersedes older status text below)

This paragraph and the checklist below report **current verified state**. Subsequent dated "Owner correction" sections preserve the decisions and implementation gaps **as observed at that earlier checkpoint**; their historical "not implemented", "CI pending" and proposed-shape statements must **not** be interpreted as current branch truth.

- **Flutter**: single integrated [Draft #551](https://github.com/im-tnyx/tio-world/pull/551) now targets `main`; code HEAD `00d6120301773be55b9c7375dc20b23105b01f4d` has [Flutter CI #38527996681](https://github.com/im-tnyx/tio-world/actions/runs/38527996681) **SUCCESS** (Flutter/Dart Analyze and full package tests). Verified runner tests include 44dp Set badge/boxed number/supporting Add Set in 320dp light/OLED, Exercise type-specific KG/REPS vs KM/TIME vs TIME, retryable definite Create vs uncertain transport, auth/login-cycle route revocation, nullable Rest, Rep Range draft selection, and sheet/inline Set synchronization. Six Codex review threads on #551 are **replied/resolved with exact-head test evidence**; resolution is **not** final independent latest-head approval.
- **Database**: [Draft #536](https://github.com/im-tnyx/tio-world/pull/536) HEAD `015a2ec1c277fc5f82dda8a54d727d67a3187177` has individual database CI PASS and 3/3 prior Codex threads already resolved. Its atomic Create enforces an Exercise and nonempty Set array per Exercise before metadata insert, owner/account lock order, and Unicode nonblank Routine names. [Draft #540](https://github.com/im-tnyx/tio-world/pull/540) HEAD `0aae3df17d9f04332054c2eb0256fe96ab5efbe2` has [combined disposable DB CI #38526157520](https://github.com/im-tnyx/tio-world/actions/runs/38526157520) **SUCCESS**, including pinned #536 migration and all SQL/two-session races. Its 1/1 Codex workflow-guard thread is replied/resolved on static evidence plus PR-event CI; `workflow_dispatch` **has not been manually executed**.
- **Approved nullable targets now exist in Draft source, not hosted Supabase**: `SetPrescription.reps` nullable, null KG, typed distance in meters and duration in seconds, type-specific UI and protected RPC schema in separate branches. Hosted DB has **not been deployed**. The `main` client still requires strictly positive non-null `SetPrescription.reps` and rejects null from hosted rows. A new blank-target writer can therefore introduce **old-client read failures** after deployment; old-client full-snapshot writes may also require incompatibility rejection. Do not claim mobile release or a safe deployment order without explicit old/new-client rollout gates. An all-blank Rep Range selection remains **transient UI-only** because `reps_max=NULL` does not persist a Range-mode bit; no extra column is approved.
- **Still BLOCKED**: latest-head independent security/Flutter/DB review (Codex review quota blocked new requests), real manual dispatch validation if required, old-client compatibility and staged DB/app rollout plan, physical Android/iOS 320dp/light/OLED/large-font/screen-reader QA, GitHub #534 Custom archive-vs-Edit RPC race, and Linear TNYX-81 (Backlog; blocked by TNYX-78/TNYX-80). Do not merge, deploy, mark Ready, close superseded ancestor PRs, rewrite branches or report shipment from these green CIs.

## Source and branch baseline
- Root `AGENTS.md`, `apps/features/AGENTS.md`, canonical `docs/screens/routine-library.md`, `docs/architecture/MODULE_OWNERSHIP.md`, `.ai/FEATURE_DEVELOPMENT.md`, `.github/PUSH_TEMPLATE.md`, and existing implementation briefs examined. GitHub PR metadata/inline Codex threads, Linear TNYX-81 and actual combined remote diff reconciled.
- **Seven stacked Flutter Drafts:** #533 (W4B1 editor, main) → #537 (Create, #533) → #541 (Set Type/Rep Range, #537) → #544 (Create interaction and blank Reps, #541) → #546 (Detail/Edit grids, #544) → #549 (numeric limits, #546) → **#551** (owner-approved Core `TioButton.supporting` / `TioInput.boxedNumber` and Set visual, #549). Each parent is currently the preceding head; #551 already contains the accumulated Flutter source.
- **Exact remote baseline prior to integration:** `main@ee5ed4cc67bfb6c8d3eb867129578201b60703bc`; child #551 `fea690a8bd19b682ea0dee7076b750c5e6f96f61`; GitHub compare: **ahead 189 / behind 0 / merge-base=main, 55 changed files**. GitHub APIs confirm ancestry and changed-file list; local worktree, `git diff --check`, tests and Flutter SDK are not available here.
- **Do not mix Supabase migrations into Flutter PR:** #536 atomic Create RPC and #540 Set metadata/Range DB changes are independently owned main-based Drafts. Supabase live runtime is not automatically updated by this client branch. No migration is in the observed 55-file Flutter delta. DB roll-out and client compatibility gates remain separate.

## Integration-only scope and decisions
1. Retarget the **existing #551** (not a new PR) from `tnyx/routine-set-input-typing-limits` to `main` **while keeping Draft**. Update PR body/title to reflect *all* Flutter changes, upstream review finding links, broad security/DB gates, and accurate validation. This will make main-targeted Flutter CI eligible to run on the **real** integrated feature head, instead of creating synthetic temporary CI PRs.
2. **Do not close, force-push, merge or delete** #533/#537/#541/#544/#546/#549 solely to lower counts. Their code/review history stays accessible. After integration source is independently validated, original threads' findings are explicitly handled, and user reviews the handoff, mark them superseded and close unmerged one by one.
3. Fix only confirmed integration defects within existing approved scope, with focused tests. Preserve Core component ownership and no separate Workout-specific button/input helpers or feature token bags. No UI redesign beyond existing approval; no new database table/column/RPC.
4. All fixes on #551 branch are integration-owned; do not edit parent/source branches. Changes to authentication route cleanup require specific revocation and capability tests and security review. Do not suppress/skip existing full-suite CI checks.

## Existing release/review blockers
- **P1 data integrity** (inherited [#546](https://github.com/im-tnyx/tio-world/pull/546)): Advanced Set details changes to Reps/Weight leave existing inline controllers stale; later inline editing can silently overwrite saved draft values. Add widget regression for sheet → inline → Update preserving independent fields, including conversion.
- **P2 auth privacy** (#546): Create Exercise Options overlay may survive auth cycle revocation.
- **P2 explicit Rep Range Max** (#544): fixed Reps → Range must leave *new* Max blank and Save disabled until typed, not synthesize `8–8`.
- **P2 reorder accessibility** (#544): add keyboard/screen-reader custom move actions to Create Exercises without restoring visual arrows.
- **CI**: ancestor #537 stale `apps/app/test/app/workout_exercises_route_test.dart` integration test and previous synthetic-only analyzer fixture issues; Flutter Analyze/Tests must run at actual integration head.
- **Security/deploy**: owner-scoped repositories, auth/login-cycle revocation, Supabase #536/#540 protected RPC/columns not deployed, older client compatibility, independent review, device QA, and TNYX-81 dependencies.
- Codex usage limits or exhausted CI are not review approvals. A PR showing `mergeable:true` does not satisfy these gates.

## Checkpoints and exit criteria
- [x] Fresh GH/Linear/source/AGENTS audit (2026-10-14).
- [x] Verify seven Flutter branches all stack and #551 HEAD is ahead of main with no divergence; 55 changed files, no `supabase/` files.
- [x] Retarget #551 to main as Draft; validate source and full Flutter CI at exact code HEAD (see current checkpoint).
- [x] Repair known #551 P1/P2 blockers with focused tests and review source; all 6 PR #551 Codex threads are evidence-reconciled and resolved.
- [x] Flutter/Dart Analyze and full tests pass on exact #551 code HEAD; focused 320dp light/OLED widget tests pass.
- [ ] Independent latest-head review, large-text/screen-reader and physical-device QA remain outstanding.
- [ ] Dependency/security/DB deployment readiness and explicit merge decision. No automatic merge.
- [ ] When reconciled, safely close redundant superseded PRs without deleting branches and reflect final status in Linear.

**Validation recorded so far:** actual remote source/diff, six review threads resolved with evidence, full latest-code Flutter CI #38527996681 PASS, combined disposable DB CI #38526157520 PASS. These are runner validations; **no physical device run, manual dispatch, hosted DB deployment or independent latest-head approval** is claimed.


## Owner correction checkpoint — 2026-10-14 (single existing PR)

**Approval (historical checkpoint):** The owner requires shorter boxed fields, Reps/Rep Range Min/Max **at most three digits (0–999 typed; positive if persisted)**, one canonical Exercises screen in both browse/selection, and Exercise artwork in Routine screens. The owner separately requires an Exercise AND Set with **optional unfilled Reps/KG** at Create Save. This was not implemented at the time of the checkpoint; it is now implemented in Draft Flutter #551 and DB #536/#540 code/tests **but not deployed**. No invented `SetPrescription(reps:1)` may be persisted.

**Implemented on #551, no new PR:**
- Core `TioInput.boxedNumber` now has denser variant-only styling (44dp minimum InputDecoration constraints, smaller governed vertical padding); Core test reflects the approved geometry. Legacy Core inputs remain unchanged.
- Workout Reps/Range Min/Max input formatter rejects more than **3 whole digits**, including paste, without truncation; the Rest field retains its separate int32 cap and Weight retains 6+3 format. Unit/precision and schema int32 guard are not replaced.
- Deleted duplicate `RoutineExercisePickerPage` and removed its public export; Create/Edit route the **existing** `ExercisesPage` with a scoped selection callback and title `Add Exercise`. Normal browsing retains `Exercises` title, filters, search and Custom edit action. Selection reuses `ExercisesController`, the same list row/thumbnail, owner-scoped Custom source and fail-closed readiness; non-pointer browse does not accidentally select.
- Root navigation and widget tests now expect `ExercisesPage`, not the deleted picker. The existing `RoutineExercisePickerController` is **not** a UI screen; retained for canonical Exercise lookup and owner-verified Edit/Detail source resolution. No extra catalog or data storage.
- Create, Edit and Detail resolve artwork from canonical `Exercise.media` with `ExercisesController.thumbnailUrlFor` and reuse `ExerciseThumbnail` (existing text-only fallback). Nullable viewer media gender is supplied by app composition only when the session/profile is verified. No hard-coded image URL or independent network widget.

**Validation truth / known regressions:** Initial CI #38509724461 failed because a nested Riverpod catalog source override violated scope dependencies. Corrected by binding the existing `ExercisesController` to an explicit catalog source within `ExercisesPage` selection context instead of overriding a nested provider. Follow-up CI #38510341736 caught a nullable local controller expression, fixed. CI #38510586889 passed app route and Workout tests but failed a pre-refinement Core boxedNumber padding assertion, corrected in `apps/core/test/ui/components/tio_input_test.dart`. **A new exact-head run is needed before declaring these changes validated.** Never claim pass based on earlier #551 heads.

**Historical backend blocker (resolved in separate Draft source; rollout remains blocked):** For a genuinely blank Reps Set to save, shared `SetPrescription`, Create/Edit adapters, `reps NOT NULL`, existing Save RPC and atomic Create RPC (plus old-client compatibility) must all be coordinated. Also, #536 currently allows zero-Set Exercises whereas owner now requires at least one Set. GitHub #536 / #540 have read-only handoff comments; no SQL was edited/deployed. Current `repsMax != null` marks Range mode: when both Min/Max are blank, the schema cannot preserve Range selection without an explicit persisted mode. Decide/approve that representation before touching DB; do not silently degrade range to fixed or store invented 1/0 reps. Combined replay, RLS, idempotency, concurrency and old-client rollout gates remain mandatory.

**Disposition (updated):** Keep #551 and #536/#540 Draft; exact-code Flutter CI and combined DB replay now pass, but do not merge/production-deploy/close ancestors until independent latest-head review, old-client rollout compatibility, phone QA, Linear dependency reconciliation and explicit owner merge/deploy approval. 


## Owner-approved Cardio/Treadmill measurement-profile correction (2026-10-14)

Reference images supplied in the current project conversation explicitly approve **Treadmill: SET / KM / TIME**, with compact Core-owned outlined numeric boxes containing dash placeholders, versus **Bench Press: SET / KG / REPS**. Both images include the existing Add Set affordance; incidental notes/Rest Timer artwork in the reference does NOT authorize introducing unplanned notes/rest features. Exercise must have >=1 Set but numeric targets (KM, TIME, KG, REPS) may remain unspecified on a reusable Routine template. Reps typing cap remains 3 digits. **No invented zero/one values.**

Verified implementation gap: bundled `ex_walking_on_treadmill` is `category: cardio` and `equipment.primary: treadmill`, but bundled catalog parsing never populates canonical optional `Exercise.exerciseType`. Custom Exercise already supports `ExerciseType.distanceDuration` and the editor offers KM/TIME hint, but W1A3 `SetPrescription` and live SQL only model required Reps / optional KG / Rest. ADR-0011 explicitly defers distance/duration storage, and current DB Drafts #536/#540 do not add it. Therefore **do not** cosmetically relabel KG/REPS as KM/TIME or silently store/reveal a fake Reps=1. Do not categorize all cardio types as equivalent.

**Current narrowly owned metadata slice on #551:** extend optional `exerciseType` parsing in the existing catalog DTO (strict known canonical storage tokens, reject malformed values), annotate the actual treadmill catalog row as `distance_duration`, and prove existing weight/reps catalog data remains unchanged by tests. No new screen/widget/repository or schema. This mapping does not itself enable KM/TIME inputs or true optional Save; those require a separately reviewed compatible end-to-end model/RPC/SQL change.

**Proposed persistence decision to verify under the exact database-shape approval gate**: two nullable columns on `public.user_workout_routine_sets`, `distance_meters` (bounded nonnegative finite numeric) and `duration_seconds` (bounded nonnegative integer), plus nullable `reps` with positive-if-present CHECK and exact existing owner RLS/privileged RPC boundaries. No new table or external API. Existing clients that only understand Reps/KG must NOT silently overwrite non-Reps Sets on full-composition Save; migration and client capabilities must explicitly guard compatibility. Combined #536 then #540 replay, old-client read/write, owner-scoped RPC, and exact Flutter CI are required. No DB migration, merge or deploy in this metadata slice.

**Owner visual reference accepted:** both screenshots (Treadmill KM/TIME and Bench Press KG/REPS) from user message. This handoff deliberately does not claim full UI/DB completion. Implementation owner remains #551 session; all other parent Flutter branches frozen. Independently reviewed implementation and physical device validation still missing.

## Time-only reference correction (2026-10-14)

Owner supplied a second reference image and clarified that some Exercises require **only `SET | TIME`** with the same small governed boxed input and a dash for blank targets. The explicitly approved Routine template measurement layout matrix is now:
- **Weight/Reps** (`ExerciseType.weightReps` or appropriate weight-based variants): `SET | KG (or LB) | REPS`.
- **Distance/Duration** (`ExerciseType.distanceDuration`): `SET | KM | TIME`. Existing bundled `ex_walking_on_treadmill` explicitly opted in; do NOT infer from `category:cardio`.
- **Duration-only** (`ExerciseType.duration`): `SET | TIME` without hidden KG/REPS/KM controls. Existing bundled `ex_front_plank` opted in by explicit canonical profile; do NOT infer from `category:strength` or `equipment:bodyweight`.

This is the approved visual contract, **NOT** permission to fake persistence. Neither duration nor distance currently exists in `SetPrescription`, atomic RPCs, or hosted set table. No runtime `TIME` field is to be displayed without an actual readable/writable nullable `duration_seconds` contract: unfinished implementation must remain Draft. Duration should have an explicit unit-format and input policy (recommend minutes:seconds display with canonical integer seconds) validated before saving; unset values stay null. `distance_meters` is a proposed nullable canonical distance column for KM display; SQL column shape approval/combined #536/#540 replay, old-client non-erasure safeguards, and all cross-surface Create/Edit/Detail tests are still required.

Only catalog type metadata and its strict parser/tests were changed in the current bounded implementation; no new UI/field source, new PR, migration or deployment has been introduced. Do not label the UI screenshot as implemented.

## Owner correction — visible Set-number boxes (2026-10-14)

Approved two reference screenshots show **each Set badge number (1, 2, ...)** centered inside a small, visibly filled rounded-square surface. Existing shared `RoutineSetInputRow` already wraps the Set Type number in a 44dp `InkWell` / `Container` with medium radius, but uses `colors.surface`. In OLED dark `surface` = `#050505` against pure-black `background`, so the current Set badge's box is effectively invisible despite existing widget chrome. Core's owned **`surfaceVariant`** is `#1F1F1F` in OLED, matching the visible reference treatment; light/dark/tioDark use their own corresponding semantic color. Bounded fix: change only that shared Workout Set-number `Container` to `colors.surfaceVariant`; retain 44dp width/min height, medium radius, the existing type selector `InkWell`, W/F/D semantic foreground colors, stable keys, swipes, and a11y tap target. Do **not** add a new Core token, component, or duplicate widget. Validate both Set 1 and Set 2 background/size and OLED/light variants with focused widget assertions and exact-head CI. The change applies to existing Create/Edit shared row only; read-only Detail uses a different rendering and is out of this badge slice. This explicit visual adjustment is approved by the owner, not permission for another design change.

## Owner follow-up — Set badges and Add Set OLED visibility (2026-10-14)

The owner explicitly reported that **the existing supporting Add Set button has the same invisible-on-black issue as the Set number boxes**. Both are fixed on this existing #551 integration branch without creating a separate widget or PR:
- Shared Workout `RoutineSetInputRow` number/Set Type box keeps its existing 44dp size, `TioRadius.md`, select/tap behavior and W/F/D colored labels, but changes fill from near-black `colors.surface` to Core semantic `colors.surfaceVariant`.
- Core-owned reusable `TioButton.supporting` changes only its filled neutral background from `colors.surface` to `colors.surfaceVariant`, including appropriate disabled-opacity and loading states. OLED `surfaceVariant` is already the governed gray `#1F1F1F`; no local Add Set button styling or new Core token. Existing Create/Edit callers inherit the correction.
- Added Core widget assertions for light/OLED background, minimum height, icon, disabled/loading treatment and shared Routine Set widget assertions for visible filled badges on 320dp light/OLED showing both 1 and 2. Core theme README updated to reflect this public variant contract.
- Pending **new exact-head Flutter CI/test validation and independent code review**. Prior green CI predates this commit and cannot validate it. No merge, schema change or production deploy.

This visible-background change is the only new UI appearance amendment; Treadmill KM/TIME and Front Plank TIME, plus truly nullable Set targets, remain **not implemented** pending verified model/RPC/DB compatibility. Do not conflate visual evidence with persistence readiness.

## Owner approval: nullable Routine metrics (2026-10-14)

The owner replied **Go** directly to the exact proposed database shape: `reps integer NULL` (positive if provided), `load_kg` existing nullable, `distance_meters double precision NULL` (finite >=0), `duration_seconds integer NULL` (>=0). It authorizes coordinated changes only on existing DB #536/#540 and Flutter #551, not extra columns, PRs, release or deployment. #536 must reject zero-Set Create before metadata insert; #540 then alters schema and the owner-scoped composition Save RPC, extending deterministic mutation replay and legacy overwrite protection to Reps null and KM/TIME. #551 Shared `SetPrescription`, RPC adapter and existing Core-owned boxedNumber inputs must truthfully serialize/render/read blank targets. Treadmill explicit ExerciseType.distanceDuration -> SET/KM/TIME; Front Plank explicit duration -> SET/TIME; other existing weightReps -> SET/KG/REPS. Default at least one Set per Exercise; Save may proceed with numeric targets unset. The reference pictures' incidental Notes / Rest Timer remain out of scope. The existing Reps cap stays 3 digits.

**Known shape limit:** `reps_max=NULL` cannot independently encode an all-blank Rep Range mode without a newly approved mode indicator; do not add an unapproved third DB column or claim cross-session preservation of blank range selection. Existing positive range when filled continues. Enforce partially filled range invalid and preserve stable UUIDs and previous kg rounding. TIME representation needs a bounded human-readable minutes:seconds parser stored as canonical seconds; cap at supported int32; no speculative performed-set history.

**Implementation ownership:** this connected session owns the current Flutter integration branch #551 only for this approved slice, coordinating separately reviewed DB #536/#540. No other Flutter parent branches mutate. Verify hosted/live DB remains unchanged, exact-head CI, dedicated new vs old client security guards, 320dp/large text/OLED and light, and old-client graceful failure on richer Sets; merge and deployment still require separate approval.

## Owner correction: matched compact Set/input/Add Set heights (2026-10-14)

The owner explicitly reports that SET number box, boxed numeric input and supporting Add Set **do not share the same compact visible height**. Fresh source at `#551@8bf1358` confirms: the shared Set badge is **44dp**, Core `TioInput.boxedNumber` is **min 44dp** but not constrained to a fixed rendered height, while Core `TioButton.supporting` still inherits the global **46dp** FilledButton minimum. Prior color/compact adjustments do not fulfill equal visual heights. Approved bounded fix: keep shared Set badge at 44dp and Core boxedNumber's compact min 44dp; override **only** the reusable Core `TioButton.supporting` minimum visual height to the pre-existing Core `TioSize.dp44` primitive. Do not change the 46dp global primary/secondary/destructive button contract, replace `TioInput`/`TioButton`, or introduce a Workout-specific wrapper. Preserve Material's padded >=48dp interactive target where supported (visual surface may be 44dp), and allow text-scale-driven growth rather than clipping content. Validate equal **rendered filled surface** heights (not merely tokens) in a 320dp widget test for Create/Edit-style combined Set/input/Add Set, with light/OLED states and baseline visual geometry. No independent review or physical-device screenshot is claimed by CI alone. This is a layout-only refinement; database migration review and optional-target contract remain separate gates.


## Owner screenshot Treadmill KG regression: bundled data audit (2026-10-14)

Owner supplied screenshots reiterating Treadmill must show `SET | KM | TIME`, NOT `SET | KG | REPS`; earlier implementation only annotated `ex_walking_on_treadmill` and missed other bundled treadmill choices. Current verified asset `apps/features/workout/assets/exercises/exercise_catalog.json` (version 2, 101 exercises): `ex_walking_on_treadmill` is `distance_duration`; `ex_run_on_treadmill` and `ex_walking_on_incline_treadmill` both omit `exerciseType`. DTO intentionally leaves legacy null unchanged; Create and Edit therefore correctly fall back to KG/REPS for these two malformed-as-to-purpose catalog entries. **Fix the two explicit built-in treadmill rows in the canonical catalog** with `distance_duration`; do not infer an Exercise Type from names, category or equipment globally and do not mutate Custom Exercises. Bump catalog content version, not schema version, and amend production-asset tests to prove all three treadmill rows opt in while other legacy rows retain their exact prior null policy. The edit resolved-catalog and picker paths already consume this canonical Exercise Type; do not introduce UI-specific hardcoded names.

Set-limit request from same owner is a **new separately scoped policy** with no approved number. Current Create and Edit controllers have unbounded `addSet`; DB only enforces payload size (256 KiB) and valid nonempty per-exercise Set arrays. Need owner-approved **maximum Sets per Exercise** value and effective scope before altering client, RPC and legacy data; do not invent a limit or apply a UI-only cap. Unresolved 42dp visual-height request is separate and should not be silently attached to a catalog-data correction. All PR merge/release gates remain pending.


## Owner-approved maximum 8 Sets per Exercise (2026-10-14)

Owner requested 6–8 as a practical maximum; the implementation takes the upper bound **8 Sets for each identified Routine Exercise entry**. Both Create and Edit must disable Add Set at 8, and both controllers must fail closed before generating another Set ID. A second copy of an Exercise starts its own counter. Saving and loading existing records must not drop excess historical Sets. PostgreSQL guards the same upper limit for old, new, or privileged clients using the existing per-exercise unique position and a bounded-position CHECK constraint applied NOT VALID to avoid destructive rewrites of historical over-limit rows. Any existing >8 Sets must remain readable and removable; future full-snapshot saves must reduce to <=8 rather than silently truncate. No table/column ownership or app schema shape changes; only the approved Set cardinality policy. No hosted DB deployment, merge or old-client rollout has occurred. Flutter #551 and database #540 need separate exact-head validation/security review.

The previously approved 42dp SET/input/Supporting button values are present on #551 at time of this handoff; ensure core README agrees with actual 42dp implementation. No physical screenshot validation claimed.

## Owner sizing update 2026-10-14: 40dp replaces 42dp

Owner explicitly requested the Routine SET visual badge, boxed numeric input outline and neutral Add Set filled surface be 40dp (previous 42dp remains historical only). Flutter PR #551 updated existing Core boxedNumber/supporting contracts and Create/Edit Set alignment, with min rather than fixed heights and unchanged 46dp primary button contract. Latest-head Flutter CI and real installed-build visual comparison are required before merge. The separately approved **8 Sets per Exercise** cap remains unchanged (Flutter #551, PostgreSQL #540). No DB deployment or merge is authorized by this sizing update.

## Owner-approved Replace Exercise from ⋮ (2026-10-14, validation pending)

Owner requested `Replace Exercise` alongside the existing `Remove Exercise`
option for Routine Exercise cards. Single bounded owner/surface: consolidated
Draft PR #551. Reuse the feature-owned options sheet, canonical catalog/Custom
Exercise picker and existing Create/Edit authorization. No new PR, Core
component, database shape, service, deployment or UI geometry change.

After a real selection, replace only the chosen Exercise in its ordered slot
with a fresh entry UUID and fresh **blank Set 1**. Retire old Set UUIDs,
typed target validity, Rep Range draft mode and type; never transfer old KG/REPS
into a KM/TIME Exercise. Cancel/Back or same-Exercise selection makes no edit.
Edit persists only on explicit Update, with existing owner Custom preflight.
Focused controller and page regressions cover cancellation, type-specific
fields, no premature writes, fresh identity and null targets.

Validation: source/tests staged for one atomic commit on existing #551 branch.
No local Flutter SDK/worktree in this connected session. Exact-head Flutter CI,
independent review and manual device visual/accessibility checks remain
required. Previous W4 DB/old-client compatibility gates remain unchanged.

## Owner approval: one screen, not two UI implementations (2026-10-14)

User requested that Create/Edit Routine use one screen; the title changes
to `Edit Routine` in edit mode. Owner explicitly rejected two duplicated
screen implementations. This is an approved presentation-consolidation
slice in existing #551, not a new PR or data-model change.

Source finding: before consolidation Create and Edit each had independent
`Scaffold` headers, `CustomScrollView`/reorder lists and ~150-line
Exercise/Set card compositions with diverging layout. Reuse the
`RoutineComposerScreen` (single Scaffold/chassis), `RoutineComposerContent`
(single ordered list), `RoutineComposerExerciseCard` (one Set header and
Add Set layout) and existing shared `RoutineSetInputRow`. Preserve existing
route keys and test selectors for compatibility. Create/Edit page classes
remain state/persistence adapters only; they do **not** maintain a second
Exercise card, reorder list, Scaffold or Set table. Create retains
atomic-create idempotency/unknown-outcome Back blocking; Edit retains
owner-scope reads, revision/mutation/Custom preflight and Update-only writes.
Edit alone shows the truthful PREVIOUS dash (not fake performed history).
Keep approved 40dp and eight-Set policy, user-owned Exercise picker and
Replace/Remove actions. No schema migration or runtime deployment.

Validation: source and focused page assertions written; remote staging is
not Flutter execution. Exact-head Flutter Analyze/full tests, independent
review, accessibility/320dp light/OLED visual comparison and old-client DB
rollout checks are pending. Do not claim merge-ready or deployed.

## Exact-head analyzer correction after main reconciliation (2026-10-14)

Merge reconciliation commit `c8a2c971` now contains merged #533 and #536
in the Git ancestry without history rewriting. Exact-head Flutter CI
#38579061711 actually ran and **FAILED** in Workout analyzer before tests:
the newly shared composer lacked the Workout feature-owned
`RoutineCompositionEntry`/`RoutineCompositionSet` import; the Exercise
options sheet was missing a closing brace; and six explicit flow guards
triggered mandatory `curly_braces_in_flow_control_structures` lint. Fix
only these precise source errors. **CI failure is not a pass**; rerun
exact-head Flutter analyze and full tests before a review/merge decision.
Database PR #540 owns SQL/schema compatibility and its independent CI.

## Shared reorder-list Key correction (2026-10-14; exact-head CI pending)

Exact-head Flutter CI #38579814984 passed the analyzer after prior
syntax/import fixes, but **FAILED** the Flutter app tests (402 passed,
9 failed). All nine were rooted in the shared `SliverReorderableList`
assertion `All list items must have a key`: the itemBuilder now
returned an unkeyed `RoutineComposerExerciseCard`, whose *inner*
Padding carried the entry key. Move each prior stable entry ValueKey
to the top-level card widget returned by the itemBuilder, remove the
duplicate child key, and preserve all existing test selectors.
This is one shared-component defect, not nine unrelated route defects.
Require fresh exact-head Flutter Analyze and full tests; no merge or
release claim until verified.

## Consolidated PR after #540 code merge (2026-10-14)

Database PR #540 was **squash-merged into repository main** at
`6a76011f10be1828b1dc661b2293de6ae41e775b` after exact-head
Supabase Database CI #38581426089 SUCCESS and Commit attribution guard.
This was a Git merge only: the hosted Supabase project still ends at
`20261010061809`, so the #536 atomic Create and #540 nullable targets
migrations are **not deployed**. Old-client compatibility/staged DB
deployment and device QA remain separate release gates.

Flutter CI #38580502750 (before merging new main) passed Flutter/Dart
analysis and app tests, then failed 7 Workout tests: 2 under tall viewport
SET badge expanding to 712 instead of 40dp, and 5 swipe/Delete interactions
whose horizontal recognizer can lose to inline numeric-field selection.
Scoped correction uses vertically-unconstrained painted SET content, and
raw-pointer horizontal intent tracking so child text-selection recognizers
cannot swallow the parent Set swipe. The existing drag/reveal/full-delete
threshold and vertical scroll gesture behavior must pass existing tests.
This source was not locally Flutter-tested; exact-head Flutter CI and
independent review remain mandatory. Reconcile all current #551 changes
with #540's merged main without overwriting its migrations or DB CI/tests.

## P1 same-owner Profile refresh Create preservation (2026-10-14)

Newest #551 P1 review found that a transient `profileDataProvider`
loading/error replaced the still-authorized Create widget with a
Scaffold, disposing the draft/frozen atomic mutation identity.
Fix: keep the last verified weight unit scoped **only to this opening
owner/login-cycle Create route**, and reuse it through transient Profile
loading/error. A subsequent verified unit replaces the display unit
without remounting Create; loss/change of Auth identity still removes
the private route. Added app route test for error then recovery while
preserving typed draft name and Create widget. Source/test ready for
exact-head Flutter CI; no claim physical QA or release safety yet.

## Review P2: persisted Rep Range plus blank Set (2026-10-14)

An existing ranged Routine Exercise loaded into Edit may receive a new
nullable Set with neither Reps field provided. The stored range remains
intact, but the new empty Set is temporarily not encodable as a range,
and the SQL full-snapshot write rejects mixed repetition modes.
The scoped fix records this entry's range draft marker when Add Set
succeeds on a persisted ranged Exercise, displays both Min/Max controls
on its new Set, and blocks Update while a persisted ranged entry contains
a fixed/blank Set. Positive completion after explicit Min+Max permits
one Update without modifying original Set IDs/ranges. No DB migration,
Set-limit, unit, or UI geometry change. Added a focused widget regression;
exact-head Flutter CI and reviewer disposition pending.

## Review P2: catalog measurement-profile upgrade / historic targets

Newer catalog types (Treadmill distance+duration, Front Plank duration)
must not suppress persisted Reps/Load created before the catalog
annotations. Add a single Workout presentation policy resolver consumed
by Detail and Edit: when a newly typed Exercise entry contains legacy
Reps/Load but **no** saved Distance/Duration anywhere in that entry,
render/edit the actual KG/REPS columns instead of empty new-type fields.
No synthetic conversion, mutation, schema migration or catalog-type
rollback. Fresh typed records retain KM/TIME or TIME. Added widget
regressions for legacy Treadmill/Plank Detail and legacy Treadmill Edit,
including preservation of numeric targets on Update. Exact-head Flutter
CI and independent reviewer disposition remain required.

## Codex follow-up P2: advanced sheet clears a persisted Rep Range (2026-10-14)

Codex latest-head review at `75bfdb6e` identified that `_setEditor`
directly invoked `editor.editSet`, bypassing the inline Set row's
transient Rep Range preservation. Clearing both bounds in `Rest & set
details` therefore silently switched a persisted ranged Exercise to
fixed Reps. Fix within existing #551: centralize this transient-mode
preservation in one `_editSetPreservingRange` action called by both
inline row edits and details-sheet saves. Pass the same transient
`showRangeDraft` to `RoutineSetEditorSheet` so reopening details also
retains Maximum Reps when the persisted bounds are blank. A focused
widget regression covers details open -> clear both -> Save Set ->
still two inline Range fields -> details reopen still Maximum Reps ->
explicit Routine Update preserves empty nullable target and Rest.
No DB/schema change, redesign, or extra PR. New exact-head CI and
independent review required before merge.

## Owner-reported numeric focus dismissal (2026-10-14; CI/device QA pending)

Create/Edit Routine KG/REPS inputs remained focused after dismissing the
phone keyboard or touching the screen outside the input. Root cause:
Flutter's implicit `TextField.onTapOutside` does not unfocus for mobile
touches; Flutter can hide the IME on system Back without changing Focus.
Bounded fix in existing #551: add an explicit `onTapOutside` unfocus
**only** for Core `TioInput.boxedNumber`, and listen for the real
keyboard `viewInsets.bottom > 0 -> 0` transition **once** in the shared
feature-owned `RoutineComposerScreen`, only when its route is current.
This covers Create and Edit, KG/REPS, Min/Max, KM/TIME, without changing
global standard/compact input behavior. Switching KG -> REPS retains
correct next focus; focus dismissal must preserve typed targets.
Dedicated Core outside-touch/sibling-input tests and shared composer
Create/Edit keyboard-metrics tests added. No geometry, 40dp, eight-Set
policy, model, persistence, migration or new PR change. Physical Android
system Back/keyboard hide and iOS keyboard dismissal QA still required.

## Owner-approved 38dp Set/Input/Add Set adjustment (2026-10-14; validation pending)

The owner explicitly reduced the previously accepted compact 40dp Routine
Set badge, boxed numeric input and neutral Add Set visual minimum to
**38dp**, preserving the single shared Create/Edit screen. Existing
`TioSize.dp38` supplies the governed primitive. The SET header and
badge widths are 38dp; Create filled and Edit unboxed SET number, all
KG/LB/REPS/Range/KM/TIME numeric fields, and Add Set painted minimum
heights become 38dp together. Accessibility text may still grow;
Material button touch-target policy and Core primary/secondary/destructive
46dp minimums are unchanged. Preserve typed Set targets, dismissal
behavior, swipe/delete interaction, 8-Set cap, and existing validation.
Core, 320dp Create/Edit light/OLED and row geometry tests now assert
38dp. No token, database migration, new PR or unrelated UI redesign.
Exact-head CI and physical compact/light/OLED/large-text QA remain
required before merge.

## Owner-approved SET/Input corner radius match (2026-10-14; CI pending)

After the 38dp geometry change, owner observed a mismatch between the
SET-number box and boxed numeric input corners. Source audit proved the
feature-local badge used `TioRadius.md` = 12dp for both decoration and
InkWell, while Core `TioInput.boxedNumber` has a governed
`TioInputTokens.radius` = 14dp. Align the badge decoration and InkWell
to the existing Core 14dp input radius (do **not** restyle Core/global
inputs). Add a light/OLED widget assertion checking painted SET, focused
and unfocused KG/REPS border radii and InkWell share that value.
Keep Edit's unboxed blue number; preserve 38dp heights and widths,
accessible growth, press behavior and all model/DB rules. No new token,
schema migration or PR. Exact-head Flutter CI and physical screenshot
verification required.

## Owner-reported Set swipe Delete shape + tactile action (2026-10-14)

Two supplied OLED screenshots show the current broken reveal rendering
a broad red stripe/oversized Delete surface, while the intended
reference presents a small rounded Delete action at the right of the
swiped Set row. Runtime root cause is the feature `RoutineSetInputRow`
`Positioned.fill` background `ColoredBox(colors.danger)`, which paints
every pixel exposed by a full/long swipe and is not a shaped button.
Keep the existing page-controlled single-open swipe row, stable Set UUID,
row number, Edit PREVIOUS data boundary, and two intentional deletion
paths: partial swipe -> tap Delete; deliberate full-length left swipe ->
delete on pointer release (not simply a velocity flick). Replace only the
background with a right-aligned compact `TextButton`: danger fill only
inside the button, 38dp visual minimum, governed 14dp boxed-field radius,
and the existing 96dp reveal width. Preserve accessible button tap
semantics and Set deletion callbacks; do not auto-save compositions.
Keep `HapticFeedback.selectionClick` at reveal crossing and add its
missing fast-flick reveal cue; `mediumImpact` remains on explicit
Delete/full-swipe deletion. Add 320dp light/OLED reveal/shape and tap
haptic regressions alongside existing full-swipe and no-accidental-delete
tests. No new Core component/token, DB/schema, feature surface or PR.
Exact-head Flutter CI and real device screenshots/tactile QA pending.

## Owner correction: Delete capsule expands with swipe, fixed 38dp height (2026-10-14)

The earlier compact fixed-96dp Delete button was **not** the owner's
intended swipe interaction. The owner's screenshot shows a clipped or
disconnected rounded action during the drag. Approved behavior: the red
Delete capsule grows in **width** in lock-step with the distance the
foreground Set row moves to the left, with both rounded ends fully visible
and painted minimum height **38dp** throughout (growing vertically only
for accessibility content). The previous 96dp is solely the settled
partial-swipe reveal width; it is NOT a fixed visible button width
throughout dragging. Use one `TweenAnimationBuilder<double>` animation
value for both capsule width and foreground translation, so neither
their boundaries nor their animation frames can diverge. At rest hide
the Delete button entirely. As drag advances, paint only the red capsule
on transparent background; short swipes release to a 96dp exposed
button, while deliberate full swipes still delete on release. Preserve
existing selection/deletion haptics, no-delete-on-fast-short-flick policy,
Set UUID/callbacks and screen state. Light/OLED 320dp tests now verify
two progressive reveal widths, unclipped alignment, 38dp height,
settled width and Delete haptics. No tokens, database writes or new PR.
Flutter CI and real-device swipe/keyboard QA are still required.

## Owner swipe refinement: 8dp field/Delete gap, visible white label (2026-10-14)

After the dynamic-width capsule fix, the owner observed Delete still
touched the REPS text field and the label appeared missing. Confirmed
the feature row gave Delete the *entire* revealed width and gated its
label on reveal width while disabled during drag. The approved, narrow
fix is to use the existing `TioSpacing.sm` = 8dp between the moving
numeric field edge and the red capsule; animate capsule width as
`max(0, revealed - 8dp)` using the existing shared Tween value.
Display the `Delete` label explicitly in white, including the
drag-disabled state, as soon as the available action width reaches
the existing reveal threshold. Preserve the 38dp painted minimum
height/field top-bottom alignment, 14dp corner radius, 96dp *total*
settled reveal (88dp red + 8dp blank), accessible touch/semantics,
and all haptic and swipe-delete policies. Light/OLED 320dp regression
asserts gap at 55/125/96dp reveals, the white label, and 38dp vertical
alignment. Exact-head Flutter CI #38609550012 failed two historical
Create page tests that still assumed an always-mounted disabled
Delete widget at rest. This is no longer the approved behavior; update
only those test expectations to `findsNothing` while keeping their
post-reveal actionable/delete/no-write assertions. No new PR,
migration, layout redesign or change to Set fields/persistence.
Required fresh exact-head full CI, independent review and installed
device/keyboard/screenshot QA before merge.

## Owner follow-up: Delete visually too tall (2026-10-14; CI pending)

Owner reported Delete still looked taller than the 38dp numeric field.
The preceding feature implementation specified only
`TextButton.styleFrom(minimumSize: Size(0,38))`, which does not guarantee
38dp *painted* height under all inherited Material button constraints.
Apply an explicit 38dp visual `fixedSize` at normal text scale, with
`MaterialTapTargetSize.padded`; allow large accessibility font scaling
to fall back to natural min-height growth. Keep the 8dp revealed
field/Delete gap, white label, swipe-progressive width, 14dp radius,
Set UUID/actions and haptics. Add style/painted Material size assertions.
Separately, exact-head Flutter CI #38611299945 found a Core visual
ownership guard failure from the previous `Colors.white` constants
(349 Core tests passed, 1 failed). Replace those three direct framework
colors with exported Core `TioPalette.white`; do not change visible
RGB. Latest-head full Flutter CI and real-device screenshot/touch QA
are required before declaring PASS or merging.

## Owner-approved Add Exercises multi-select (2026-10-14; CI pending)

Scope: existing PR #551, approved by owner screenshots and review
#5522069160 plus revised GitHub comments #6174527380/#6174620850.
Existing canonical `ExercisesPage` now has a distinct Add-only batch
contract. Select/deselect is transient, insertion-ordered by canonical
`ExerciseRef`, with a selected thumbnail-overlay checkmark or text-only
fallback. The footer is absent at selection count zero, and updates to
`Add 1 exercise` / `Add N exercises` on selection. Confirm appends
fresh Exercise/blank Set 1 entries in memory to Create/Edit; ordinary
browse, search/filter, and single-select Replace remain intact. No
new screen/PR/schema/RPC/watch work or data write before Save/Update.

Implementation source commit `2024568530bddc07d9263676baa94eb961d4762d`
introduced the source behavior on the existing consolidated branch.
This test/documentation follow-up updates former single-tap widget/route
fixtures and adds multi-Add Create/Edit/picker checks. Exact-head Flutter
CI and independent review **are required**; no installed-device or
screen-reader QA has run in this session. Existing ownership and DB/
release/merge gates remain unchanged.

## Owner adjustment: smaller selected Exercise badge (2026-10-14)

Reduce only the Add-mode selected-thumbnail and text-only fallback
checkmark circle from 24dp to governed 20dp, and its icon from 16dp to
14dp. Keep the surrounding row tap target/semantics, thumbnail size,
selected-state colors, browse/Replace modes and Add footer unchanged.
Add focused widget geometry assertions. Exact-head Flutter CI and physical
visual/accessibility QA remain required; no merge authorization.

## Owner refinement: selected Exercise marker hugs thumbnail rim (2026-10-14)

Follow-up to the approved Add-mode thumbnail-overlay checkmark. At the
observed #551 HEAD `a643360b2aa6a1b5d5e3614eb843d18a16cd43a5`
the marker was already reduced from 24dp to 20dp. Owner requested
another slight size reduction and placement closer to the image border.
Reduce only the governed marker circle to **18dp** and icon to **12dp**.
Move the image-overlay `Positioned` marker from `top: 0`,
`right: TioSpacing.md` to `top: -TioSpacing.xs`,
`right: TioSpacing.xs` relative to the existing thumbnail + padding
stack. The check now straddles the upper-right image rim while the
thumbnail size/row geometry remain unchanged. Apply the smaller marker
to the text-only fallback too; retain accessible row semantics and
tap size. No new token, UI fork, database work, PR, merge or rollout.
Focused UI geometry assertions added; exact-head Flutter CI and
physical visual/accessibility QA still required.


## Exact-head Flutter CI #38616706794 remediation (2026-10-15; pending new CI)

At PR #551 SHA `01834457c070051df05961f369dc36a5d4d6564b`,
GitHub Flutter CI #38616706794 failed in the Workout package:
**523 passed, 7 failed**. Flutter/Dart analyze passed; Dart package
tests were skipped following the Flutter failure. From job
`116033733560` logs, six failures were stale widget test flow
assumptions following the approved batch picker (five Edit Custom
preflight scenarios plus one Detail -> Edit scenario): those tests
tapped a row and expected the picker to auto-close. They now assert
the count-one action exists, tap `exercises-add-selected`, then
continue their existing Custom-owner/RPC/cancel/refresh protections.
The remaining new batch Create test supplied only four UUID fixtures
for two Exercise+Set pairs, but `RoutineCreateController.save` also
allocates Routine and mutation UUIDs. It now supplies six IDs,
without changing source identity behavior. No production code or
persistence contract changed in this remediation. New exact-head
Flutter CI, independent review and physical accessibility/visual QA
are required; prior 523/7 is not a pass.

## Codex exact-head review remediations (2026-10-15; CI pending)

Latest Codex review on #551 head `5b50f0a77ba1bfa642ddea2df871b28ecbc83ede` added three P2 threads:
late-running Create RPC commit after parent Program refresh, definite HTTP
4xx incorrectly treated as unknown, and disappearing Add-mode selected
badge on broken network thumbnail. These are real review findings; 7 total
#551 threads remain unreviewed/resolution pending.

This **bounded first fix** keeps the Create adapter's existing explicit
SQL/Auth cases, adds definite handling for unclassified numeric HTTP
400–499 errors (matching the Edit adapter's ambiguity criteria), and
adds a real-SDK MockClient test for 400/404/409/422/429 with one request.
The selected-only ExerciseThumbnail now retains its original 56dp media
footprint when network imagery fails so the 18dp overlay remains visible.
Browse/single-select thumbnail failure still collapses as before and
no new media loader/selection state is introduced. Widget regression
asserts a failed network thumbnail retains badge, size and legible name.
No schema, new page, change to Routine identities, or hosted deployment.

The **late-commit P2 is NOT fixed** by this slice: one initial refresh
cannot prove absence after a timed-out RPC. Needs an explicit protected
same-session pending-attempt/settlement gate or a thoroughly reviewed
server-backed reconciliation design plus tests before resolution. No
unapproved arbitrary polling window or false no-duplicate promise.
Exact-head Flutter CI, independent Code review, DB old-client staging,
and manual device QA remain required before merge.

## Same-session late-commit Create gate (2026-10-15; CI pending)

Codex P2: the client's 15s timeout does not cancel the original atomic RPC.
An immediate owner-scoped Program read may miss a late commit. Preserve the
same RoutineCreateCommand in a volatile app Provider keyed by verified owner,
login cycle and Program when the user explicitly exits an unknown Create.
Block further Program Add actions until an explicit positive matching read
confirms metadata and composition revision 1 / mutation UUID / exact content.
Negative, stale owner, partial and failed reads never unlock. Program route
re-entry in the same session retains the gate. This is intentionally NOT
durable process-restart recovery; its residual risk requires review.
No schema, backend service or unsafe time-based unlock; exact-head CI and
independent review plus device QA are still pending.

## Follow-up CI and late-commit integration (2026-10-15)

First in-session gate commit `cf553a367244b25ae3aaba86caf4a727403ea9d1`
failed exact-head Flutter CI #38677295359 on five analyzer warnings for
redundant null checks/assertions in the app shell; no tests ran.
Remove those redundancies without changing actual session authorization.
Strengthen app integration fixtures: simulate an ACK lost **after** commit
and a second case where the RPC times out while uncommitted, the Program
reads empty, verification reads empty, the user returns to Library and
reopens Program Detail, then the original RPC commits. The original
Create must have only one request; only positive full-content verification
may unlock fresh Create. Await runner CI and independent review.

## Workout analyzer follow-up (2026-10-15; CI pending)

Commit `ba47e9785d688013070ee6a0f5740dc47643659e` Flutter CI
#38677601745 failed after Flutter/Dart app analysis passed: Workout
package emitted only three `curly_braces_in_flow_control_structures`
info-level diagnostics treated as CI failures. Wrap those three
multi-line if statements with braces without changing control flow.
No other production changes; next runner must verify tests.

## Latest CI fixture correction (2026-10-15; exact-head validation pending)

At `3689e9d60d96b18c9983f4374116a1c91e2dca38`, CI #38677830512
passed Flutter/Dart analysis, and 412 tio_app tests passed with one newly
introduced late-Create test failure. Its assertion incorrectly claimed the
Program had no Routines at all; the canonical route fixture already seeds
`Synthetic Route Routine`. Update the assertion to require the existing list
and existing Routine, but **absence of the uncommitted new `Routine 1`**.
Guard/production code unchanged. New CI required.

## Codex second latest-head findings, scoped correction (2026-10-15)

Latest reviewed head `4531c4160b2abeef2df860b282b015dd01de4805`
has Flutter CI #38678197154 SUCCESS, and Codex identified two new P2s.
First, `RoutinePendingCreateGate.verify` must not compare the mutable Routine
name: a rename does not invalidate immutable Routine UUID, Program FK,
revision-1 last mutation UUID and identical Exercise/Set composition.
Retain all existing immutable identity, content, owner and login-cycle
checks; add remote rename positive and wrong mutation negative tests.
Second, `ExerciseType.stepsDuration` has approved catalog label STEPS/TIME
but **no canonical Steps SetPrescription or SQL field**. A false KG/REPS
mapping would be data corruption; no schema/repurposed field is approved.
Fail closed in Create/Edit/Add/Replace Routine selectors and their draft
controllers, preserve normal Exercise Library browse/Custom editing, and
show a specific selection-context message. Add picker and controller tests.
Do not implement Steps storage, backend schema or core redesign here.
This is source remediation pending exact-head CI and independent thread
re-review; 9 unresolved threads as of audit, without reviewer approvals.

## Save-time verification hardening (2026-10-15; CI pending)

Besides picker and controller Add/Replace guards for STEPS/TIME, verify the
current authenticated Custom Exercise type again immediately before Create
or Edit RPC. Another device may change the active Custom definition after the
picker returns; a still-active ref is not sufficient to authorize treating
STEPS as REPS. Retain fail-closed no-write behavior with a precise message.
Test both Create and Edit stale-definition preflights with zero writes.
Likewise the Create editor's in-place unknown ACK reconciliation uses stable
Routine ID, owner Program, mutation ID and composition equality rather than
requiring the initial mutable display name; regression for rename. No schema.

## Latest Codex P1/P2 remediations — newer revision confirmation + Edit blank marker (2026-10-15; CI pending)

Codex on #551 head `a659455316a9dd3b0b3a0470a3f2137c2ea2b598` reported:
- P1 new/Replace Edit Set typed Reps can disappear after an Update reject/rebuild because the blank marker remains when validity stays true→true. Fix on successful inline onChanged before editor publishes/rebuilds; regression checks typed Reps remain visible and in unchanged draft after definite RPC failure.
- P2 Create RPC may commit and later Edit advances the same persisted Routine to revision > 1, replacing lastMutationId and content. Strict revision-1 confirmation would strand a same-session Program Add lock. Centralize read-only confirmation in RoutineCreateCommand: require owner-verified Routine ID/Program listing, snapshot's Routine ID, and at revision 1 exact original mutation/content; for revision > 1 require a committed mutation marker. Later revision proves this stable Routine exists, NOT that the original payload is unchanged. Both pending Program gate and in-place Create editor use this contract; add positive later-edit and negative no-provenance regressions. This is not a new DB column or permission to trust unscoped source data.
Original process-death recovery, old client compatibility, #534, device QA and independent review remain merge/release gates.
