# GitHub #568 / TNYX-78 — Hosted 68/68 First-Routine actual-write QA readiness

**Status:** Audit complete; source/device QA and product activation NOT authorized as passed.
**Date:** 2026-10-21. **Verified GitHub main:** `8da55bdfe29ed5ec1eee3e5e2f7fed972260b42c`.
**Owner:** Flutter app-shell and Workout capability QA. **Related:** #569/TNYX-81 (Move release remains independently gated).

## Truth and scope

Following owner's hash-verified Windows `supabase db push --linked --skip-vault` with explicit `DEPLOY-BOTH`, independent connected hosted project `oykupyiitspujzpwwvuj` read-only audit confirms **68/68 exact migration versions+names** and no missing/hosted-only entries. The #568 first-Routine RPC is callable by `authenticated` but not `anon`, `service_role`, or `PUBLIC`; #569's two Move RPCs remain EXECUTE-denied. Three live SECDEF function bodies match reviewed migration source after line-ending normalization and enforce trusted `auth.users.is_anonymous IS FALSE`. RLS remains enabled. Supabase Security Advisor's `authenticated_security_definer_function_executable` warning count increased from 9 to 10 as expected for the intentionally exposed #568 owner-scoped API. This is a reviewed risk, **not** a clean scanner.

The existing checked-in Flutter owner/login-cycle adapter at `apps/features/workout/lib/src/data/repositories/supabase_my_program_routine_create_repository.dart` sends one atomic `create_user_workout_routine_in_my_program` RPC with a frozen mutation identity, no automatic retry and UNKNOWN handling. `apps/app/lib/app/routing/shell/shell_route.dart` wires the direct Library Create action through the canonical composer and owner/session/pending-operation checks; a successful save may create a server-owned default Program within the same transaction. **`myProgramRoutineCreateReleaseEnabledProvider=false` in production.** Both Move release and actual client RPC grants stay OFF.

## Verified reusable tests and exact limitations

Existing focused tests should be **reused, not duplicated**:
- `apps/features/workout/test/data/supabase_my_program_routine_create_repository_test.dart`;
- `apps/features/workout/test/presentation/my_program_routine_create_composer_test.dart`;
- `apps/features/workout/test/presentation/routine_pending_my_program_create_gate_test.dart`;
- `apps/features/workout/test/presentation/routine_create_controller_test.dart`;
- `apps/app/test/app/workout_exercises_route_test.dart` already exercises first-Routine release OFF and **test-only** `ProviderScope` overrides for rejected transactions, ACK refresh, lost ACK, and login-cycle revocation.

These tests were **inspected in source**, not rerun by this remote connected session. They use fake/test repositories rather than a physical phone with an Auth test account. Previous green source Flutter CI is not evidence of authenticated hosted actual-write QA.

`.github/workflows/flutter-ci.yml` supplies Melos analysis plus app/workout Flutter tests. Existing `.github/workflows/android-native-ci.yml` builds unsigned debug phone and Wear APKs but does not establish an Android Supabase QA login/build route. `.github/workflows/ios-ui-build.yml` has a `qa_login` configuration for an **unsigned profile** device artifact; a profile build cannot bypass the currently hard-false first-Routine release provider. No distributed/test-device build currently proves direct Library first-Routine Create end-to-end. Do not mistake the `TIO_MOVE_ROUTINE_UI_PREVIEW` debug flag for actual-write ability: it does zero writes.

## Next bounded QA engineering gate (not yet implemented)

1. Run the existing focused Dart/Flutter tests at exact Git commit and record toolchain, command, outcome and any failing tests. Do **not** claim PASS from inspected source alone.
2. Independently review a strictly controlled **test-only** real-write capability that allows signed-in **owner-approved testing accounts** to exercise the approved Library flow on Android and iOS without changing production release defaults. Prefer existing provider overrides and reuse one composer/adapter; do not add a second persistence path, publish a production flag, inject a service-role key, or widen remote grants. A build mode/compile-time flag alone is **not an authorization boundary**: the hosted RPC is already REST-executable by permanent accounts.
3. Securely provision device QA builds without leaking Supabase QA credentials into artifacts. Work through the existing Android/iOS CI ownership and signing/install limitations; do not claim an unsigned IPA is installable on a real iPhone. Any scoped QA-only app behavior that newly exposes an action to testers must have explicit acceptance/review before running actual writes.
4. On dedicated test accounts/devices with approved user write consent, verify empty Library and cancel (zero default), successful single atomic default+Routine+Exercise+Set persistence, default rename then follow-up Create with same stable identity, no duplicate defaults on frozen exact retry/two-device race, owner A/B isolation, stale login-cycle switch, network timeout/UNKNOWN positive readback, offline and app relaunch, and legacy existing Program compatibility. Verify row/state deltas without reading or publishing private tester identifiers. Distinguish server-verified behavior from client UI/physical-device outcomes.
5. Review subsequent actual-write evidence, negative permission probes, Security Advisor differential and a documented permission-only emergency REVOKE procedure. Only then consider separately owner-approved mobile release activation. Keep #569 Move grant, real Undo, AI generation, Program deletion and Workout Start outside this #568 QA slice.

## Exit conditions / stop rules

**Current verdict:** database deployment PASS, app-source QA readiness AUDITED, **real authenticated Android/iOS Create SAVE = NOT TESTED**, production feature release **NO-GO**. No new SQL, hosted writes, user data edits, client flag changes, branch merge, or app distribution in this documentation-only slice. Stop on mismatched Git SHA, non-test account, missing owner/session binding, direct client table-write fallback, unexplained RPC/Advisor permissions, QA credential exposure or ambiguous commit; never retry an UNKNOWN write with a new identity.
