# W4 Routine Flutter PR consolidation / integration gate

**Status:** In progress / integration review.

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
