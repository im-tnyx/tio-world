import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_home/home.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_feature_workout/workout.dart';

import '../../app_mode/app_mode.dart';
import '../../calendar_preferences.dart';
import '../../meal_diary_today_glyph.dart';
import '../../network_providers.dart';

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
      builder: (context, state) => LibraryPage(
        onExercisesPressed: () =>
            context.push(AppRoutes.workoutExercises.path),
        onSearchPressed: () => context.push(
          Uri(
            path: AppRoutes.workoutExercises.path,
            queryParameters: const {_exercisesSearchParameter: 'true'},
          ).toString(),
        ),
      ),
    ),
    GoRoute(
      path: _childPath(branch, AppRoutes.workoutExercises),
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => ExercisesPage(
        startSearching:
            state.uri.queryParameters[_exercisesSearchParameter] == 'true',
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
