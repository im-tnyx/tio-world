"""Guard the fail-closed Android build selection contract."""

import unittest
from pathlib import Path

from android_native_change_scope import select_targets


class AndroidNativeChangeScopeTest(unittest.TestCase):
    def test_wear_only_skips_phone(self) -> None:
        self.assertEqual(select_targets([b"apps/wear/lib/home.dart"]), (False, True))

    def test_phone_only_skips_wear(self) -> None:
        self.assertEqual(select_targets([b"apps/app/android/settings.gradle"]), (True, False))
        self.assertEqual(select_targets([b"apps/features/workout/lib/workout.dart"]), (True, False))

    def test_wear_has_no_phone_feature_dependency(self) -> None:
        wear_pubspec = Path(__file__).resolve().parents[2] / "apps/wear/pubspec.yaml"
        self.assertNotIn("../features", wear_pubspec.read_text(encoding="utf-8"))

    def test_both_apps_build_both(self) -> None:
        self.assertEqual(
            select_targets([b"apps/app/pubspec.lock", b"apps/wear/pubspec.lock"]),
            (True, True),
        )

    def test_shared_or_unknown_changes_build_both(self) -> None:
        for path in (
            b"apps/shared/lib/workout.dart",
            b"apps/core/lib/core.dart",
            b"pubspec.yaml",
            b"melos.yaml",
            b".github/workflows/android-native-ci.yml",
        ):
            with self.subTest(path=path):
                self.assertEqual(select_targets([b"apps/wear/lib/home.dart", path]), (True, True))

    def test_empty_diff_builds_both(self) -> None:
        self.assertEqual(select_targets([]), (True, True))

    def test_rename_across_apps_builds_both_when_git_reports_both_paths(self) -> None:
        self.assertEqual(
            select_targets([b"apps/app/lib/old.dart", b"apps/wear/lib/new.dart"]),
            (True, True),
        )


if __name__ == "__main__":
    unittest.main()
