import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_auth/auth.dart' show AuthSessionAuthenticated;
import 'package:tio_feature_home/home.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

import '../../app_mode/app_mode.dart';
import '../../calendar_preferences.dart';
import '../../meal_diary_today_glyph.dart';
import '../../network_providers.dart';
import '../../session/session.dart';

/// Keep the pre-confirmation Routine 3-dot modal bound to its opening owner.
/// The later Delete confirmation has a separate per-attempt guard.
/// This wrapper is app-owned: Workout never imports Auth or Supabase.
Widget _guardRoutineOptionsSheet({
  required Widget content,
  required String? ownerId,
  required String? loginCycleId,
}) => Consumer(
  builder: (sheetContext, sheetRef, _) {
    final boot = sheetRef.watch(appSessionBootstrapControllerProvider).state;
    final authValue = sheetRef.watch(authSessionStateProvider);
    final auth = authValue.isLoading || authValue.hasError
        ? null : authValue.valueOrNull;
    final valid = ownerId != null && loginCycleId != null &&
        boot is AppSessionBootstrapReady && boot.userId == ownerId &&
        auth is AuthSessionAuthenticated &&
        auth.session.userId == ownerId &&
        auth.session.loginCycleId == loginCycleId;
    if (valid) return content;

    // Do not render the former account's name/actions for one more frame.
    // Dismiss exactly this sheet's route, never a newer owner route.
    final route = ModalRoute.of(sheetContext);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!sheetContext.mounted || route == null || !route.isActive) {
        return;
      }
      Navigator.of(sheetContext).removeRoute(route);
    });
    return const SizedBox.shrink();
  },
);
TioShellPlaceholder _page(TioRouteContract route) {
  return TioShellPlaceholder(
      title: route.title, description: route.description);
}

Widget _shellBranchPage(ShellBranchDefinition branch) {
  if (branch.tab == ShellTab.home) {
    return const HomePage();
  }

  if (branch.tab == ShellTab.workout) {
    // Workout consumes the same app-global calendar preference as every other
    // date surface. The feature owns only its selected date and navigation
    // range; no Workout domain truth is fabricated in this shell.
    return Consumer(
      builder: (context, ref, _) => WorkoutHomePage(
        resolvedFirstDayOfWeek: ref.watch(resolvedFirstDayOfWeekProvider),
        onLibraryPressed: () => context.push(AppRoutes.workoutLibrary.path),
      ),
    );
  }

  if (branch.tab == ShellTab.nutrition) {
    // Meal Diary is the first consumer of the app-global week start. It is
    // read here, at composition, so Nutrition never reaches into Settings for
    // it — and watched, so changing the preference relays out the calendar
    // without leaving this screen.
    return Consumer(
      builder: (context, ref, _) => MealDiaryPage(
        resolvedFirstDayOfWeek: ref.watch(resolvedFirstDayOfWeekProvider),
        // Quick Add's Meal type options come from the same repository the
        // Meal Categories screens use, handed down rather than reached for:
        // the feature cannot import this layer.
        mealCategoriesRepository: ref.watch(mealCategoriesRepositoryProvider),
        mealTextParseRepository: ref.watch(mealTextParseRepositoryProvider),
      ),
    );
  }

  return _page(branch.route);
}

/// Full-screen destinations nested under a main tab's route.
///
/// They are shown on the root navigator, above the shell, so they cover its
/// chrome rather than making the shell hide it mid-transition, which would
/// relayout the tab underneath. A direct deep link still lands with the tab
/// root beneath them. Paths are relative to the branch root.
List<RouteBase> _shellBranchChildRoutes(
  ShellBranchDefinition branch,
  GlobalKey<NavigatorState> rootNavigatorKey,
) {
  if (branch.tab != ShellTab.workout) return const [];

  return [
    GoRoute(
      path: _childPath(branch, AppRoutes.workoutLibrary),
      parentNavigatorKey: rootNavigatorKey,
      // Library → Exercises pushes, so back from Exercises returns here.
      builder: (context, state) => Consumer(
        builder: (context, ref, _) {
          final programRepository = ref.watch(programRepositoryProvider);
          final routineRepository = ref.watch(routineRepositoryProvider);
          final compositions = ref.watch(routineCompositionRepositoryProvider);
          final createRepository = ref.watch(routineCreateRepositoryProvider);
          final deleteRepository = ref.watch(routineDeleteRepositoryProvider);
          final deleteFlow = ref.read(routineDeleteFlowProvider);
          // Reuse the feature-owned Move flow and the same existing/New Program
          // adapter instance. The release capability remains OFF until M3D3
          // coordination, hosted RPC/grants and device QA are approved.
          final moveReleaseEnabled = ref.watch(routineMoveReleaseEnabledProvider);
          final movePreviewEnabled =
              ref.watch(routineMoveUiPreviewEnabledProvider);
          final moveActionEnabled = moveReleaseEnabled || movePreviewEnabled;
          final moveRepository = ref.watch(routineMoveRepositoryProvider);
          final createMoveRepository =
              ref.watch(routineCreateMoveRepositoryProvider);
          final moveFlow = ref.read(routineMoveFlowProvider);
          final moveRefresh = ref.read(routineMoveRefreshSignalProvider);
          final catalog = ref.watch(exerciseCatalogRepositoryProvider);
          final userExerciseRepository =
              ref.watch(userExerciseRepositoryProvider);
          /// One session-guarded full Routine editor shared by Detail and the
          /// existing Routine-card options popup. Never use metadata Rename.
          Future<bool> editRoutine(Program program, Routine ownedRoutine) async {
            if (routineRepository == null || compositions == null ||
                userExerciseRepository == null ||
                ownedRoutine.programId != program.id) {
              return false;
            }
            final openingSession =
                ref.read(appSessionBootstrapControllerProvider).state;
            final startingOwner = openingSession is AppSessionBootstrapReady
                ? openingSession.userId : null;
            final openingAuthAsync = ref.read(authSessionStateProvider);
            final openingAuth = openingAuthAsync.isLoading ||
                    openingAuthAsync.hasError
                ? null : openingAuthAsync.valueOrNull;
            final startingAuth = openingAuth is AuthSessionAuthenticated
                ? openingAuth.session.userId : null;
            final startingCycleId = openingAuth is AuthSessionAuthenticated
                ? openingAuth.session.loginCycleId : null;
            final openingProfile = ref.read(profileDataProvider);
            if (startingOwner == null || startingOwner != startingAuth ||
                startingCycleId == null || openingProfile.isLoading ||
                openingProfile.hasError ||
                openingProfile.valueOrNull?.unitPreferences.weightUnit == null) {
              return false;
            }
                              var revoked = false;
                              final confirmed = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => Consumer(
                                    builder: (context, ref, _) {
                                      // Re-evaluate all account capabilities
                                      // in the destination itself, not only
                                      // when the navigation action was tapped.
                                      final session = ref
                                          .watch(
                                            appSessionBootstrapControllerProvider,
                                          )
                                          .state;
                                      final currentOwner =
                                          session is AppSessionBootstrapReady
                                              ? session.userId
                                              : null;
                                      final authAsync =
                                          ref.watch(authSessionStateProvider);
                                      final auth = authAsync.isLoading ||
                                              authAsync.hasError
                                          ? null
                                          : authAsync.valueOrNull;
                                      final currentAuth =
                                          auth is AuthSessionAuthenticated
                                              ? auth.session.userId
                                              : null;
                                      final currentCycleId =
                                          auth is AuthSessionAuthenticated
                                              ? auth.session.loginCycleId
                                              : null;
                                      final authorized =
                                          currentOwner == startingOwner &&
                                          currentAuth == startingOwner &&
                                          currentCycleId == startingCycleId;
                                      // The editor may be covered by a
                                      // picker or Set modal on this Navigator.
                                      // A changed Auth/bootstrap owner must
                                      // dismiss those routes too: disposing
                                      // the underlying keyed editor alone
                                      // does not clear an overlay's private
                                      // Custom Exercise/Set draft.
                                      if (!authorized && !revoked) {
                                        revoked = true;
                                        final editorRoute =
                                            ModalRoute.of(context);
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          if (!context.mounted ||
                                              editorRoute == null ||
                                              !editorRoute.isActive) {
                                            return;
                                          }
                                          final navigator =
                                              Navigator.of(context);
                                          navigator.popUntil(
                                            (route) =>
                                                identical(route, editorRoute),
                                          );
                                          // A pending RPC deliberately
                                          // blocks normal back via PopScope.
                                          // On auth/cycle revocation that
                                          // protection must NOT keep the old
                                          // account's editor mounted. Force
                                          // removal bypasses canPop; the
                                          // disposed controller ignores any
                                          // eventual old-cycle save response.
                                          // Revoked navigation resolves
                                          // with null (never a save success).
                                          navigator.removeRoute(editorRoute);
                                        });
                                      }
                                      final profileAsync =
                                          ref.watch(profileDataProvider);
                                      final unit = authorized &&
                                              !profileAsync.isLoading &&
                                              !profileAsync.hasError
                                          ? profileAsync
                                              .valueOrNull
                                              ?.unitPreferences
                                              .weightUnit
                                          : null;
                                      return EditRoutinePage(
                                        key: ValueKey(
                                          'edit-routine-owner-${currentOwner ?? 'none'}-auth-${currentAuth ?? 'none'}-cycle-${currentCycleId ?? 'none'}',
                                        ),
                                        program: program,
                                        routine: ownedRoutine,
                                        routineRepository: authorized
                                            ? ref.watch(routineRepositoryProvider)
                                            : null,
                                        compositionRepository: authorized
                                            ? ref.watch(
                                                routineCompositionRepositoryProvider,
                                              )
                                            : null,
                                        catalogRepository: ref.watch(
                                          exerciseCatalogRepositoryProvider,
                                        ),
                                        userExerciseRepository: authorized
                                            ? ref.watch(
                                                userExerciseRepositoryProvider,
                                              )
                                            : null,
                                        viewerMediaGender: authorized && unit != null
                                            ? ref.watch(exerciseViewerMediaGenderProvider)
                                            : null,
                                        weightUnit: unit,
                                        // Recheck the live opening login cycle
                                        // synchronously immediately before an
                                        // RPC, not only after the route rebuilds.
                                        canWrite: () {
                                          try {
                                            final liveBoot = ref
                                                .read(
                                                  appSessionBootstrapControllerProvider,
                                                )
                                                .state;
                                            final liveAuthAsync =
                                                ref.read(authSessionStateProvider);
                                            final liveAuth = liveAuthAsync.isLoading ||
                                                    liveAuthAsync.hasError
                                                ? null
                                                : liveAuthAsync.valueOrNull;
                                            return liveBoot is AppSessionBootstrapReady &&
                                                liveBoot.userId == startingOwner &&
                                                liveAuth is AuthSessionAuthenticated &&
                                                liveAuth.session.userId ==
                                                    startingOwner &&
                                                liveAuth.session.loginCycleId ==
                                                    startingCycleId;
                                          } catch (_) {
                                            // A disposed Consumer cannot retain
                                            // a capability for the old session.
                                            return false;
                                          }
                                        },
                                      );
                                    },
                                  ),
                                ),
                              );
            return confirmed ?? false;
          }

          /// One guarded Delete entry shared by expanded Library and Detail.
          /// The feature workflow owns confirmation and outcomes; shell only
          /// supplies a live bootstrap/Auth-cycle capability check.
          Future<bool> deleteRoutine(Program program, Routine routine) async {
            final repository = deleteRepository;
            if (repository == null || routineRepository == null ||
                routine.programId != program.id) {
              return false;
            }
            final openingBoot =
                ref.read(appSessionBootstrapControllerProvider).state;
            final owner = openingBoot is AppSessionBootstrapReady
                ? openingBoot.userId : null;
            final openingValue = ref.read(authSessionStateProvider);
            final openingAuth = openingValue.isLoading || openingValue.hasError
                ? null : openingValue.valueOrNull;
            final cycle = openingAuth is AuthSessionAuthenticated &&
                    openingAuth.session.userId == owner
                ? openingAuth.session.loginCycleId : null;
            if (owner == null || cycle == null) return false;

            bool sameSession() {
              try {
                final boot = ref.read(appSessionBootstrapControllerProvider).state;
                final value = ref.read(authSessionStateProvider);
                final auth = value.isLoading || value.hasError
                    ? null : value.valueOrNull;
                return boot is AppSessionBootstrapReady &&
                    boot.userId == owner &&
                    auth is AuthSessionAuthenticated &&
                    auth.session.userId == owner &&
                    auth.session.loginCycleId == cycle &&
                    ref.read(supabaseClientProvider)?.auth.currentUser?.id == owner;
              } catch (_) {
                return false;
              }
            }
            if (!sameSession()) return false;
            return deleteFlow.run(
              context: context, program: program, routine: routine,
              repository: repository, canWrite: sameSession,
              confirmationGuard: (dialogContext, content) => Consumer(
                builder: (guardContext, guardRef, _) {
                  final currentBoot = guardRef
                      .watch(appSessionBootstrapControllerProvider).state;
                  final currentAuth = guardRef.watch(authSessionStateProvider);
                  final currentState = currentAuth.isLoading || currentAuth.hasError
                      ? null : currentAuth.valueOrNull;
                  final stillOwner = currentBoot is AppSessionBootstrapReady &&
                      currentBoot.userId == owner &&
                      currentState is AuthSessionAuthenticated &&
                      currentState.session.userId == owner &&
                      currentState.session.loginCycleId == cycle &&
                      sameSession();
                  if (!stillOwner) {
                    // Remove the exact stale confirmation route, not an
                    // unrelated/new-owner route, after its private name is
                    // synchronously removed from the rendered widget tree.
                    final staleRoute = ModalRoute.of(guardContext);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!guardContext.mounted || staleRoute == null ||
                          !staleRoute.isActive) {
                        return;
                      }
                      Navigator.of(guardContext).removeRoute(staleRoute);
                    });
                    return const SizedBox.shrink();
                  }
                  return content;
                },
              ),
            );
          }

          /// Prepare the canonical Workout Move flow behind a default-off
          /// app release gate; do not expose a partially working card action.
          /// Both existing Program Move and atomic Create+Move share the
          /// same session-bound adapter, attempt gate and confirmation flow.
          Future<bool> moveRoutine(Program program, Routine routine) async {
            final programs = programRepository;
            final moves = moveRepository;
            final atomicMoves = createMoveRepository;
            if (!moveActionEnabled || programs == null || moves == null ||
                atomicMoves == null || !identical(moves, atomicMoves) ||
                routineRepository == null || routine.programId != program.id) {
              return false;
            }

            final openingBoot =
                ref.read(appSessionBootstrapControllerProvider).state;
            final owner = openingBoot is AppSessionBootstrapReady
                ? openingBoot.userId : null;
            final authValue = ref.read(authSessionStateProvider);
            final auth = authValue.isLoading || authValue.hasError
                ? null : authValue.valueOrNull;
            final cycle = auth is AuthSessionAuthenticated &&
                    auth.session.userId == owner
                ? auth.session.loginCycleId : null;
            if (owner == null || cycle == null || cycle.trim().isEmpty) {
              return false;
            }

            // A previously captured callback may run after logout or
            // same-owner relogin. Never give that old cycle new authority.
            // Post-write read invalidation must use only the authenticated
            // owner/cycle. A newly pending Create or a release-toggle change
            // may revoke NEW writes but cannot undo an already sent RPC.
            bool sameAuthenticatedOwner() {
              try {
                final boot =
                    ref.read(appSessionBootstrapControllerProvider).state;
                final value = ref.read(authSessionStateProvider);
                final live = value.isLoading || value.hasError
                    ? null : value.valueOrNull;
                return boot is AppSessionBootstrapReady &&
                    boot.userId == owner &&
                    live is AuthSessionAuthenticated &&
                    live.session.userId == owner &&
                    live.session.loginCycleId == cycle &&
                    ref.read(supabaseClientProvider)?.auth.currentUser?.id ==
                        owner;
              } catch (_) {
                return false;
              }
            }

            // Actual Move dispatch additionally requires the release/preview
            // gate and no unresolved Create in its source Program.
            bool sameSession() {
              try {
                return sameAuthenticatedOwner() &&
                    (ref.read(routineMoveReleaseEnabledProvider) ||
                        ref.read(routineMoveUiPreviewEnabledProvider)) &&
                    !ref.read(routinePendingCreateGateProvider).hasPending(
                      owner: owner, loginCycle: cycle, programId: program.id,
                    );
              } catch (_) {
                return false;
              }
            }

            if (!sameSession()) return false;
            var atomicCreateWasAttempted = false;
            final needsRefresh = await moveFlow.run(
              context: context,
              sourceProgram: program,
              routine: routine,
              programs: programs,
              repository: moves,
              canWrite: sameSession,
              // Debug-only preview still uses live owner-scoped reads but
              // never reaches either protected write RPC after confirmation.
              previewOnly: movePreviewEnabled,
              createAndMove: ({
                required RoutineMoveTarget target,
                required ProgramId newProgramId,
                required String newProgramName,
                required String mutationId,
              }) {
                // Read the Program collection too even if the atomic RPC's
                // response is UNKNOWN. Never claim the Program was created.
                atomicCreateWasAttempted = true;
                return atomicMoves.createAndMove(
                  target: target,
                  newProgramId: newProgramId,
                  newProgramName: newProgramName,
                  mutationId: mutationId,
                );
              },
              modalGuard: (dialogContext, content) =>
                  _guardRoutineOptionsSheet(
                content: content, ownerId: owner, loginCycleId: cycle,
              ),
            );
            // An attempted write (including UNKNOWN or a late rejection)
            // invalidates live owner-scoped readers. The flow's boolean is
            // NOT a confirmed server mutation. If auth changed after dispatch,
            // the next owner/session must never receive the previous signal.
            if (needsRefresh && sameAuthenticatedOwner()) {
              moveRefresh.request(
                ownerId: owner,
                loginCycleId: cycle,
                programsMayHaveChanged: atomicCreateWasAttempted,
              );
            }
            // Registered Library/Detail listeners now own the refresh.
            // Suppress the calling card's older one-Program duplicate read.
            return false;
          }

          Future<void> openRoutine(Program program, Routine routine) async {
            if (routineRepository == null ||
                compositions == null ||
                routine.programId != program.id) {
              return;
            }
            await Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => Consumer(
                  builder: (context, ref, _) {
                    // The Supabase client instance survives auth transitions.
                    // Key the preview by the canonical session user so a
                    // sign-out/account switch disposes its private read state
                    // immediately, even while catalog resolution is in flight.
                    final session = ref
                        .watch(appSessionBootstrapControllerProvider)
                        .state;
                    final ownerId = session is AppSessionBootstrapReady
                        ? session.userId
                        : null;
                    // Riverpod may retain account A's previous Profile DTO
                    // while reloading account B. Require both session identity
                    // and a completed, error-free Profile reload before using
                    // any account-owned display unit.
                    final authAsync = ref.watch(authSessionStateProvider);
                    final auth = authAsync.isLoading || authAsync.hasError
                        ? null
                        : authAsync.valueOrNull;
                    final authUserId = auth is AuthSessionAuthenticated
                        ? auth.session.userId
                        : null;
                    // Unlike userId, a sign-in cycle changes when the same
                    // account authenticates anew. Never carry previous-cycle
                    // Routine content or edits into the new session.
                    final authCycleId = auth is AuthSessionAuthenticated
                        ? auth.session.loginCycleId
                        : null;
                    final profileAsync = ref.watch(profileDataProvider);
                    final weightUnit = ownerId != null &&
                            authUserId == ownerId &&
                            !profileAsync.isLoading &&
                            !profileAsync.hasError
                        ? profileAsync.valueOrNull?.unitPreferences.weightUnit
                        : null;
                    // A bootstrap user alone is insufficient: Auth must
                    // resolve to the same current user before exposing an
                    // owner-scoped Detail repository or an Edit capability.
                    final verifiedOwner =
                        ownerId != null && ownerId == authUserId;
                    final mayEdit = verifiedOwner &&
                        weightUnit != null &&
                        userExerciseRepository != null;
                    return RoutineDetailPage(
                      key: ValueKey(
                        'routine-detail-owner-${ownerId ?? 'none'}-auth-${authUserId ?? 'none'}-cycle-${authCycleId ?? 'none'}',
                      ),
                      program: program,
                      routine: routine,
                      routineRepository:
                          verifiedOwner ? routineRepository : null,
                      compositionRepository:
                          verifiedOwner ? compositions : null,
                      catalogRepository: catalog,
                      userExerciseRepository:
                          verifiedOwner ? userExerciseRepository : null,
                      viewerMediaGender: verifiedOwner && weightUnit != null
                          ? ref.watch(exerciseViewerMediaGenderProvider)
                          : null,
                      weightUnit: weightUnit,
                      onEditPressed: !mayEdit
                          ? null
                          : (ownedRoutine) async {
                              if (ownedRoutine.id != routine.id ||
                                  ownedRoutine.programId != program.id) {
                                return false;
                              }
                              return editRoutine(program, ownedRoutine);
                            },
                    );
                  },
                ),
              ),
            );
          }

          Future<void> openProgram(Program program,
              {bool launchCreate = false}) async {
            if (routineRepository == null) return;
            // This Program belongs to the session which opened Detail.
            // A mounted Detail must not create under an old Program
            // after an account switch or a new login cycle.
            final openingBoot =
                ref.read(appSessionBootstrapControllerProvider).state;
            final openingOwner = openingBoot is AppSessionBootstrapReady
                ? openingBoot.userId
                : null;
            final openingAuthAsync = ref.read(authSessionStateProvider);
            final openingAuth = openingAuthAsync.isLoading ||
                    openingAuthAsync.hasError
                ? null
                : openingAuthAsync.valueOrNull;
            final openingCycle =
                openingAuth is AuthSessionAuthenticated &&
                        openingAuth.session.userId == openingOwner
                    ? openingAuth.session.loginCycleId
                    : null;
            final pendingGate = ref.read(routinePendingCreateGateProvider);
            if (openingOwner != null && openingCycle != null) {
              pendingGate.bindSession(
                owner: openingOwner, loginCycle: openingCycle);
            }
            bool openingSessionValid() {
              try {
                final boot = ref.read(
                    appSessionBootstrapControllerProvider).state;
                final value = ref.read(authSessionStateProvider);
                final auth = value.isLoading || value.hasError
                    ? null : value.valueOrNull;
                return openingOwner != null && openingCycle != null &&
                    boot is AppSessionBootstrapReady &&
                    boot.userId == openingOwner &&
                    auth is AuthSessionAuthenticated &&
                    auth.session.userId == openingOwner &&
                    auth.session.loginCycleId == openingCycle;
              } catch (_) { return false; }
            }
            // Canonical guarded atomic Create, shared by Program Detail and
            // direct Library Add. No metadata-only or duplicate persistence.
            Future<bool> createRoutine(String suggestedName,
                {bool launchedFromLibrary = false}) async {
              if (createRepository == null ||
                  compositions == null ||
                  userExerciseRepository == null ||
                  !openingSessionValid() ||
                  pendingGate.hasPending(
                    owner: openingOwner!,
                    loginCycle: openingCycle!,
                    programId: program.id,
                  )) {
                return false;
              }
              final boot = ref
                  .read(appSessionBootstrapControllerProvider)
                  .state;
              final initialOwner = boot is AppSessionBootstrapReady
                  ? boot.userId
                  : null;
              final authValue = ref.read(authSessionStateProvider);
              final initialAuth = authValue.isLoading ||
                      authValue.hasError
                  ? null
                  : authValue.valueOrNull;
              final initialAuthOwner =
                  initialAuth is AuthSessionAuthenticated
                      ? initialAuth.session.userId
                      : null;
              final initialCycle =
                  initialAuth is AuthSessionAuthenticated
                      ? initialAuth.session.loginCycleId
                      : null;
              if (initialOwner != openingOwner ||
                  initialAuthOwner != openingOwner ||
                  initialCycle != openingCycle) {
                return false;
              }
              var revoked = false;
              var exitedUnconfirmed = false;
              // Scoped to the opening owner/login cycle.
              // Transient Profile errors must not replace
              // this route's unsaved Create controller.
              WeightUnit? lastVerifiedUnit;
              final confirmed = await Navigator.of(context)
                  .push<bool>(MaterialPageRoute(
                builder: (_) => Consumer(
                  builder: (context, ref, _) {
                    final boot = ref
                        .watch(appSessionBootstrapControllerProvider)
                        .state;
                    final owner = boot is AppSessionBootstrapReady
                        ? boot.userId
                        : null;
                    final authAsync =
                        ref.watch(authSessionStateProvider);
                    final auth = authAsync.isLoading ||
                            authAsync.hasError
                        ? null
                        : authAsync.valueOrNull;
                    final authOwner =
                        auth is AuthSessionAuthenticated
                            ? auth.session.userId
                            : null;
                    final cycle =
                        auth is AuthSessionAuthenticated
                            ? auth.session.loginCycleId
                            : null;
                    final authorized =
                        owner == initialOwner &&
                        authOwner == initialOwner &&
                        cycle == initialCycle;
                    if (!authorized && !revoked) {
                      revoked = true;
                      final privateRoute =
                          ModalRoute.of(context);
                      WidgetsBinding.instance
                          .addPostFrameCallback((_) {
                        if (!context.mounted ||
                            privateRoute == null ||
                            !privateRoute.isActive) {
                          return;
                        }
                        // A picker or Exercise Options
                        // modal is a separate Navigator
                        // route above the Create draft.
                        // Dismiss every private overlay
                        // before removing the revoked
                        // session's underlying route.
                        final navigator = Navigator.of(context);
                        navigator.popUntil((route) =>
                            identical(route, privateRoute));
                        // RemoveRoute bypasses a pending
                        // save's PopScope; revoked content
                        // must not survive the login cycle.
                        navigator.removeRoute(privateRoute);
                      });
                    }
                    final profile =
                        ref.watch(profileDataProvider);
                    final resolvedUnit = authorized &&
                            !profile.isLoading &&
                            !profile.hasError
                        ? profile.valueOrNull
                            ?.unitPreferences.weightUnit
                        : null;
                    if (resolvedUnit != null) {
                      lastVerifiedUnit = resolvedUnit;
                    }
                    final unit = authorized
                        ? lastVerifiedUnit
                        : null;
                    if (!authorized || unit == null) {
                      return const Scaffold(
                        body: Center(
                          child: Text(
                            'Create Routine is unavailable.',
                          ),
                        ),
                      );
                    }
                    return CreateRoutinePage(
                      key: ValueKey(
                        'create-routine-owner-$owner-cycle-$cycle',
                      ),
                      program: program,
                      initialName: suggestedName,
                      returnToLibrary: launchedFromLibrary,
                      createRepository: createRepository,
                      catalogRepository: catalog,
                      userExerciseRepository:
                          userExerciseRepository,
                      routineRepository: routineRepository,
                      compositionRepository: compositions,
                      // An explicitly unconfirmed exit
                      // needs a fresh owner-bound Program
                      // read; it is not an ACK of Create.
                      onUnconfirmedExit: (command) {
                        if (!openingSessionValid()) return;
                        pendingGate.retain(
                          owner: openingOwner,
                          loginCycle: openingCycle,
                          command: command,
                        );
                        exitedUnconfirmed = true;
                      },
                      // Capture immutable identity BEFORE
                      // dispatch, not only on an optional
                      // user-triggered unknown exit. A
                      // revoked route cannot stop an RPC
                      // which is already in-flight.
                      onWriteStarted: (command) {
                        if (!openingSessionValid()) return;
                        pendingGate.retain(
                          owner: openingOwner,
                          loginCycle: openingCycle,
                          command: command,
                        );
                      },
                      onWriteResolved: (command) {
                        if (!openingSessionValid()) return;
                        pendingGate.release(
                          owner: openingOwner,
                          loginCycle: openingCycle,
                          command: command,
                        );
                      },
                      onDefiniteFailure: (command) {
                        // A definite rejected RPC is safe
                        // to forget even if this old route
                        // was removed after reauthentication.
                        // The gate checks SAME owner and
                        // exact command object, not an old
                        // login-cycle write capability.
                        pendingGate.releaseDefiniteForOwner(
                          owner: openingOwner,
                          command: command,
                        );
                      },
                      viewerMediaGender: authorized
                          ? ref.watch(exerciseViewerMediaGenderProvider)
                          : null,
                      weightUnit: unit,
                      canWrite: () {
                        try {
                          final current = ref
                              .read(appSessionBootstrapControllerProvider)
                              .state;
                          final a = ref
                              .read(authSessionStateProvider);
                          final auth = a.isLoading || a.hasError
                              ? null
                              : a.valueOrNull;
                          return current is AppSessionBootstrapReady &&
                              current.userId == initialOwner &&
                              auth is AuthSessionAuthenticated &&
                              auth.session.userId == initialOwner &&
                              auth.session.loginCycleId ==
                                  initialCycle;
                        } catch (_) {
                          return false;
                        }
                      },
                    );
                  },
                ),
              ));
              // The parent refreshes on either a
              // confirmed save or a consciously unconfirmed
              // exit; the latter must not imply success.
              return confirmed == true || exitedUnconfirmed;
            }

            // Library's Add action must not push a visible Program Detail.
            // Reuse the same owner-scoped read/naming and guarded Create
            // callback as the Program Detail app-bar action.
            if (launchCreate) {
              // A delayed owner read may outlive Library navigation.
              // Never push Create over a different current destination.
              final libraryRoute = ModalRoute.of(context);
              if (libraryRoute == null || !libraryRoute.isCurrent) return;
              if (createRepository == null ||
                  compositions == null ||
                  userExerciseRepository == null ||
                  !openingSessionValid() ||
                  pendingGate.hasPending(
                    owner: openingOwner!,
                    loginCycle: openingCycle!,
                    programId: program.id,
                  )) {
                return;
              }
              final routines = ProgramRoutinesController(
                program: program,
                repository: routineRepository,
              );
              try {
                await routines.load();
                if (!context.mounted ||
                    !libraryRoute.isCurrent ||
                    !openingSessionValid() ||
                    routines.state.status != ProgramRoutinesStatus.ready ||
                    pendingGate.hasPending(
                      owner: openingOwner,
                      loginCycle: openingCycle,
                      programId: program.id,
                    )) {
                  return;
                }
                await createRoutine(routines.suggestedName(),
                    launchedFromLibrary: true);
              } finally {
                routines.dispose();
              }
              return;
            }

            // Program Detail may still be navigated read-only;
            // only account-owned Create requires this capability.
            await Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => Consumer(
                  builder: (routeContext, routeRef, _) {
                    // A program route can outlive the session that opened it.
                    // Revoke its loaded owner data and destructive callbacks
                    // on bootstrap or Auth-cycle change, even mid-dialog.
                    final bootState = routeRef
                        .watch(appSessionBootstrapControllerProvider).state;
                    final authAsync = routeRef.watch(authSessionStateProvider);
                    final authState = authAsync.isLoading || authAsync.hasError
                        ? null : authAsync.valueOrNull;
                    final authorized = openingOwner != null &&
                        openingCycle != null &&
                        bootState is AppSessionBootstrapReady &&
                        bootState.userId == openingOwner &&
                        authState is AuthSessionAuthenticated &&
                        authState.session.userId == openingOwner &&
                        authState.session.loginCycleId == openingCycle;
                    // Unauthenticated routes were already permitted to show
                    // read-only public context without offering a write.
                    // If an initially authenticated route is revoked, keep
                    // the page/nav alive but dispose its owner-bound reader.
                    final revoked = openingCycle != null && !authorized;
                    return ProgramDetailPage(
                      key: ValueKey('program-detail-$openingOwner-$openingCycle'),
                      // A mounted old owner route must not retain its
                      // private Program title when its auth cycle is revoked.
                      program: revoked
                          ? Program(id: program.id, name: 'Routines unavailable')
                          : program,
                      routineRepository: revoked ? null : routineRepository,
                      moveRefreshSignal: revoked ? null : moveRefresh,
                      moveRefreshOwnerId: revoked ? null : openingOwner,
                      moveRefreshLoginCycleId: revoked ? null : openingCycle,
                      actionSheetGuard: (sheetContext, sheet) =>
                          _guardRoutineOptionsSheet(
                            content: sheet, ownerId: openingOwner,
                            loginCycleId: openingCycle,
                          ),
                  pendingCreateChanges: pendingGate,
                  onRoutinePressed: revoked || compositions == null
                      ? null
                      : (routine) => openRoutine(program, routine),
                  onEditRoutine: revoked || compositions == null ||
                          userExerciseRepository == null
                      ? null
                      : (routine) => editRoutine(program, routine),
                  onMoveRoutine: !moveActionEnabled || revoked ||
                          moveRepository == null ||
                          createMoveRepository == null ||
                          programRepository == null ||
                          !openingSessionValid()
                      ? null
                      : (routine) => moveRoutine(program, routine),
                  onDeleteRoutine: revoked || deleteRepository == null ||
                          !openingSessionValid()
                      ? null
                      : (routine) => deleteRoutine(program, routine),
                  hasUnconfirmedCreate: () =>
                      !revoked && openingOwner != null && openingCycle != null &&
                      pendingGate.hasPending(
                        owner: openingOwner,
                        loginCycle: openingCycle,
                        programId: program.id,
                      ),
                  onVerifyUnconfirmedCreate: revoked || compositions == null ||
                          openingOwner == null || openingCycle == null
                      ? null
                      : () => pendingGate.verify(
                        owner: openingOwner,
                        loginCycle: openingCycle,
                        programId: program.id,
                        routines: routineRepository,
                        compositions: compositions,
                        canWrite: openingSessionValid,
                      ),
                  // Always supply the Create action to keep
                  // the legacy metadata-only sheet unreachable in
                  // production, including if RPC dependencies fail.
                  onCreateRoutine: createRoutine,
                    );
                  },
                ),
              ),
            );
          }

          final boot = ref.watch(appSessionBootstrapControllerProvider).state;
          final authValue = ref.watch(authSessionStateProvider);
          final auth = authValue.isLoading || authValue.hasError
              ? null
              : authValue.valueOrNull;
          final canCreateForSession = boot is AppSessionBootstrapReady &&
              auth is AuthSessionAuthenticated &&
              auth.session.userId == boot.userId;
          // This is a Provider holding a ChangeNotifier, not a notifier
          // provider. Library explicitly subscribes via ListenableBuilder.
          final pendingCreates = ref.read(routinePendingCreateGateProvider);
          final currentOwner =
              boot is AppSessionBootstrapReady ? boot.userId : null;
          final currentCycle = auth is AuthSessionAuthenticated &&
                  auth.session.userId == currentOwner
              ? auth.session.loginCycleId
              : null;

          return _VerifiedLibraryCreateSession(
            gate: pendingCreates,
            owner: canCreateForSession ? currentOwner : null,
            loginCycle: canCreateForSession ? currentCycle : null,
            builder: (bound) => LibraryPage(
            programRepository: programRepository,
            routineRepository: routineRepository,
            onProgramPressed: routineRepository == null
                ? null
                : (program) => openProgram(program),
            onAddRoutinePressed: !bound ||
                    !canCreateForSession ||
                    routineRepository == null ||
                    createRepository == null ||
                    compositions == null ||
                    userExerciseRepository == null
                ? null
                : (program) => openProgram(program, launchCreate: true),
            pendingCreateChanges: pendingCreates,
            moveRefreshSignal: bound ? moveRefresh : null,
            moveRefreshOwnerId: bound ? currentOwner : null,
            moveRefreshLoginCycleId: bound ? currentCycle : null,
            hasUnconfirmedCreate: (program) =>
                bound && currentOwner != null && currentCycle != null &&
                pendingCreates.hasPending(
                  owner: currentOwner,
                  loginCycle: currentCycle,
                  programId: program.id,
                ),
            onRoutinePressed: compositions == null || routineRepository == null
                ? null
                : openRoutine,
            onEditRoutine: !bound || !canCreateForSession ||
                    routineRepository == null || compositions == null ||
                    userExerciseRepository == null
                ? null
                : editRoutine,
            onMoveRoutine: !moveActionEnabled || !bound ||
                    !canCreateForSession || programRepository == null ||
                    routineRepository == null || moveRepository == null ||
                    createMoveRepository == null
                ? null
                : moveRoutine,
            actionSheetGuard: (sheetContext, sheet) =>
                _guardRoutineOptionsSheet(
                  content: sheet,
                  ownerId: bound ? currentOwner : null,
                  loginCycleId: bound ? currentCycle : null,
                ),
            onDeleteRoutine: !bound || !canCreateForSession ||
                    routineRepository == null || deleteRepository == null
                ? null
                : deleteRoutine,
            onProgramsManagePressed: () =>
                context.push(AppRoutes.workoutPrograms.path),
            onExercisesPressed: () =>
                context.push(AppRoutes.workoutExercises.path),
            onCreateExercisePressed: () {
              final repository = userExerciseRepository;
              if (repository == null) return;
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => CreateExercisePage(
                    repository: repository,
                  ),
                ),
              );
            },
            canCreateExercise: userExerciseRepository != null,
            onSearchPressed: () => context.push(
              Uri(
                path: AppRoutes.workoutExercises.path,
                queryParameters: const {_exercisesSearchParameter: 'true'},
              ).toString(),
            ),
            ),
          );
        },
      ),
    ),
    GoRoute(
      path: _childPath(branch, AppRoutes.workoutPrograms),
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => Consumer(
        builder: (context, ref, _) => ProgramsPage(
          repository: ref.watch(programRepositoryProvider),
        ),
      ),
    ),
    GoRoute(
      path: _childPath(branch, AppRoutes.workoutExercises),
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => Consumer(
        builder: (context, ref, _) => ExercisesPage(
          startSearching:
              state.uri.queryParameters[_exercisesSearchParameter] == 'true',
          userExerciseRepository: ref.watch(userExerciseRepositoryProvider),
        ),
      ),
    ),
  ];
}

/// `/workout/exercises?search=true` opens Exercises with search active.
const _exercisesSearchParameter = 'search';

String _childPath(ShellBranchDefinition branch, TioRouteContract route) {
  final prefix = '${branch.route.path}/';
  assert(route.path.startsWith(prefix), '${route.path} is not under $prefix');
  return route.path.substring(prefix.length);
}

/// Shared calendar-surface centred month label, constrained so it cannot run
/// under the status action cluster.
///
/// `TioShellStatusTopBar` centres this across the whole bar on purpose, so it
/// stays centred on screen no matter how wide the title or actions are. That
/// also means nothing stops a long label from painting beneath the actions:
/// at 320dp with a 1.6x text scale and the Today action showing, the label
/// reached 238.75dp while the Today glyph starts at 212dp. Because the label
/// is centred, the space it can safely occupy is the bar minus twice the
/// cluster's painted width, and it ellipsises rather than overlapping.
///
/// At a normal text scale this changes nothing — the label still renders in
/// full. It only bites at large text scales on a narrow screen, where the
/// alternative is the month painting across the icons.
Widget _calendarVisibleMonthLabel(
  BuildContext context, {
  required DateTime visibleMonth,
  required Key labelKey,
}) {
  // Measured against painted glyphs, not hit boxes. The cluster's touch
  // targets reach 120dp in from the right edge, but its leftmost *painted*
  // pixel — the Today glyph, inset 12dp inside its 48dp button — starts at
  // 108dp. Reserving the hit box instead would shrink the label to an
  // ellipsis at every width, which is a worse outcome than a button whose
  // padding a centred label passes under without touching its icon.
  const paintedClusterWidth = TioSize.dp48 * 2 + TioSize.dp12;
  final available =
      MediaQuery.sizeOf(context).width - paintedClusterWidth * 2;

  return ConstrainedBox(
    constraints: BoxConstraints(maxWidth: available > 0 ? available : 0),
    child: Text(
      tioCompactMonthYearLabel(
        visibleMonth,
        localeName: Localizations.localeOf(context).toString(),
      ),
      key: labelKey,
      style: Theme.of(context).textTheme.titleSmall,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    ),
  );
}

String _calendarTodayTooltip(
  BuildContext context,
  DateTime selectedDate, {
  required bool isOnToday,
}) {
  if (isOnToday) return 'Return calendar to current week';
  final formattedDate =
      MaterialLocalizations.of(context).formatMediumDate(selectedDate);
  return 'Return to Today and current week from $formattedDate';
}

void _handleShellAction(GoRouter router,
    StatefulNavigationShell navigationShell, ShellAction action) {
  if (action is ShellTabSelected) {
    navigationShell.goBranch(action.tab.branchIndex);
    return;
  }

  if (action is ShellProfileClicked) {
    router.push(AppRoutes.profile.path);
    return;
  }
}

StatefulShellRoute buildAppShellRoute({
  required GlobalKey<NavigatorState> rootNavigatorKey,
  required ChromePolicy Function(String location) chromePolicyForPath,
  required bool Function() isOnboardingCompleted,
  required GoRouter Function() router,
}) {
  return StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            final chromePolicy = chromePolicyForPath(state.uri.path);

            return Consumer(
              builder: (context, ref, child) {
                final modeState = ref.watch(appModeControllerProvider);
                final selectedMode = modeState.selectedMode;
                final visibleTabs = selectedMode == null
                    ? (isOnboardingCompleted()
                        ? missingModeCompatibilityShellTabs
                        : const [ShellTab.home])
                    : shellTabsForDestinations(
                        modeState.activeDestinations ??
                            selectedMode.guidedDestinations,
                      );

                final profileAsync = ref.watch(profileDataProvider);
                final profileData = profileAsync.valueOrNull;

                final planTier = switch (profileData?.plan.toLowerCase()) {
                  'plus' => ShellPlanTier.plus,
                  'pro' || 'premium' => ShellPlanTier.premium,
                  _ => ShellPlanTier.free,
                };
                final selectedTab =
                    ShellTab.fromBranchIndex(navigationShell.currentIndex);
                final workoutDates = selectedTab == ShellTab.workout
                    ? ref.watch(workoutDateControllerProvider)
                    : null;
                final mealDiaryDates = selectedTab == ShellTab.nutrition
                    ? ref.watch(mealDiaryDateControllerProvider)
                    : null;

                return TioShell(
                  key: ValueKey(
                      'shell-${profileData?.avatarUrl}-${profileData?.plan}'),
                  state: ShellUiState(
                    selectedTab: selectedTab,
                    visibleTabs: visibleTabs,
                    isBottomNavVisible: chromePolicy.showsBottomNav,
                    isRootTopBarVisible: chromePolicy.showsRootTopBar,
                    userName: profileData?.name ?? profileData?.username,
                    avatarUrl: profileData?.avatarUrl,
                    planTier: planTier,
                  ),
                  onAction: (action) =>
                      _handleShellAction(router(), navigationShell, action),
                  // The tab is Nutrition; the screen inside it is the Meal
                  // Diary, and its own compact name is what the top bar shows.
                  statusTopBarTitle:
                      selectedTab == ShellTab.nutrition ? 'Diary' : null,
                  // Where the reader currently is in the calendar, which is not
                  // the same question as what they have selected.
                  statusTopBarCenter: workoutDates != null
                      ? _calendarVisibleMonthLabel(
                          context,
                          visibleMonth: workoutDates.visibleMonth,
                          labelKey: const ValueKey('workout-visible-month'),
                        )
                      : mealDiaryDates != null
                          ? _calendarVisibleMonthLabel(
                              context,
                              visibleMonth: mealDiaryDates.visibleMonth,
                              labelKey:
                                  const ValueKey('meal-diary-visible-month'),
                            )
                          : null,
                  // Calendar surfaces share the same return-to-Today affordance.
                  // Workout currently has [Today?] [streak]; Meal Diary keeps
                  // its owner-locked [Today?] [streak] [More] order.
                  statusTopBarLeadingAction: workoutDates != null &&
                          workoutDates.shouldShowTodayAction
                      ? IconButton(
                          key: const ValueKey('workout-today-action'),
                          tooltip: _calendarTodayTooltip(
                            context,
                            workoutDates.selectedDate,
                            isOnToday: workoutDates.isOnToday,
                          ),
                          onPressed: workoutDates.selectToday,
                          icon: MealDiaryTodayGlyph(
                            localToday: workoutDates.localToday,
                          ),
                        )
                      : mealDiaryDates != null &&
                              mealDiaryDates.shouldShowTodayAction
                          ? IconButton(
                              key: const ValueKey('meal-diary-today-action'),
                              tooltip: _calendarTodayTooltip(
                                context,
                                mealDiaryDates.selectedDate,
                                isOnToday: mealDiaryDates.isOnToday,
                              ),
                              onPressed: mealDiaryDates.selectToday,
                              icon: MealDiaryTodayGlyph(
                                localToday: mealDiaryDates.localToday,
                              ),
                            )
                          : null,
                  statusTopBarTrailingAction: mealDiaryDates == null
                      ? null
                      : MealDiaryMoreMenu(
                          onMealDiarySettingsPressed: () => context.push(
                            AppRoutes.mealDiarySettings.path,
                          ),
                        ),
                  child: child!,
                );
              },
              child: navigationShell,
            );
          },
          branches: shellBranchRegistry.map((branch) {
            return StatefulShellBranch(
              routes: [
                GoRoute(
                  path: branch.route.path,
                  builder: (context, state) => _shellBranchPage(branch),
                  routes: _shellBranchChildRoutes(branch, rootNavigatorKey),
                ),
              ],
            );
          }).toList(growable: false),
        );
}

/// App-only gate: reconcile the verified Library owner/login-cycle *before*
/// enabling either Add Routine entry point. Binding notifies listeners, so do
/// it after the current frame rather than mutating a ChangeNotifier in build.
/// The first frame of a new identity fails closed until the gate is bound.
class _VerifiedLibraryCreateSession extends StatefulWidget {
  const _VerifiedLibraryCreateSession({
    required this.gate,
    required this.owner,
    required this.loginCycle,
    required this.builder,
  });

  final RoutinePendingCreateGate gate;
  final String? owner;
  final String? loginCycle;
  final Widget Function(bool bound) builder;

  @override
  State<_VerifiedLibraryCreateSession> createState() =>
      _VerifiedLibraryCreateSessionState();
}

class _VerifiedLibraryCreateSessionState
    extends State<_VerifiedLibraryCreateSession> {
  bool _bound = false;

  @override
  void initState() {
    super.initState();
    _scheduleBinding();
  }

  @override
  void didUpdateWidget(covariant _VerifiedLibraryCreateSession oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gate != oldWidget.gate ||
        widget.owner != oldWidget.owner ||
        widget.loginCycle != oldWidget.loginCycle) {
      _bound = false;
      _scheduleBinding();
    }
  }

  void _scheduleBinding() {
    final gate = widget.gate;
    final owner = widget.owner;
    final cycle = widget.loginCycle;
    if (owner == null || cycle == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          widget.gate != gate ||
          widget.owner != owner ||
          widget.loginCycle != cycle) {
        return;
      }
      gate.bindSession(owner: owner, loginCycle: cycle);
      if (mounted) setState(() => _bound = true);
    });
  }

  @override
  Widget build(BuildContext context) => widget.builder(_bound);
}

