from __future__ import annotations

import base64
import json
import os
import stat
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from mobile_qa_runtime_config import (  # noqa: E402
    ConfigurationError,
    resolve_runtime_config,
    write_runtime_config,
)


class RuntimeConfigTests(unittest.TestCase):
    @staticmethod
    def _workspace_temp_directory() -> tempfile.TemporaryDirectory[str]:
        repo_root = Path(__file__).resolve().parents[2]
        return tempfile.TemporaryDirectory(dir=repo_root)

    def test_qa_login_accepts_https_supabase_project_and_publishable_key(self) -> None:
        self.assertEqual(
            resolve_runtime_config(
                "https://tio-qa-123.supabase.co",
                "sb_publishable_exampleKey_123",
            ),
            {
                "SUPABASE_URL": "https://tio-qa-123.supabase.co",
                "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_exampleKey_123",
            },
        )

    def test_qa_login_rejects_missing_and_partial_configuration(self) -> None:
        for url, key in (
            ("", ""),
            ("https://tio-qa.supabase.co", ""),
            ("", "sb_publishable_exampleKey"),
        ):
            with self.subTest(url=bool(url), key=bool(key)):
                with self.assertRaises(ConfigurationError):
                    resolve_runtime_config(url, key)

    def test_qa_login_rejects_non_https_or_non_supabase_endpoints(self) -> None:
        for url in (
            "http://tio-qa.supabase.co",
            "https://tio-qa.supabase.co.attacker.example",
            "https://user@tio-qa.supabase.co",
            "https://tio-qa.supabase.co/path",
            "https://tio-qa.supabase.co?query=1",
            "https://tio-qa.supabase.co#fragment",
            "https://tio-qa.supabase.co:444",
        ):
            with self.subTest(url=url):
                with self.assertRaises(ConfigurationError):
                    resolve_runtime_config(url, "sb_publishable_exampleKey")

    def test_qa_login_rejects_invalid_and_privileged_keys(self) -> None:
        service_role_payload = base64.urlsafe_b64encode(
            json.dumps({"role": "service_role"}).encode("utf-8")
        ).decode("ascii").rstrip("=")
        keys = (
            "sb_publishable_",
            "sb_publishable_has spaces",
            "sb_secret_not-a-client-key",
            "sb_service_role_not-a-client-key",
            f"eyJhbGciOiJub25lIn0.{service_role_payload}.signature",
        )
        for key in keys:
            with self.subTest(key_prefix=key[:18]):
                with self.assertRaises(ConfigurationError):
                    resolve_runtime_config("https://tio-qa.supabase.co", key)

    def test_valid_qa_config_is_written_without_extra_fields(self) -> None:
        with self._workspace_temp_directory() as temp_dir:
            output = Path(temp_dir) / "runtime.json"
            write_runtime_config(
                output,
                "https://tio-qa.supabase.co",
                "sb_publishable_exampleKey_123",
            )
            self.assertEqual(
                json.loads(output.read_text(encoding="utf-8")),
                {
                    "SUPABASE_URL": "https://tio-qa.supabase.co",
                    "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_exampleKey_123",
                },
            )
            if os.name == "posix":
                self.assertEqual(stat.S_IMODE(output.stat().st_mode), 0o600)

    def test_invalid_config_does_not_create_or_overwrite_runtime_file(self) -> None:
        with self._workspace_temp_directory() as temp_dir:
            output = Path(temp_dir) / "runtime.json"
            with self.assertRaises(ConfigurationError):
                write_runtime_config(output, "https://tio-qa.supabase.co", "sb_secret_bad")
            self.assertFalse(output.exists())

            output.write_text("existing", encoding="utf-8")
            with self.assertRaises(FileExistsError):
                write_runtime_config(
                    output,
                    "https://tio-qa.supabase.co",
                    "sb_publishable_exampleKey",
                )
            self.assertEqual(output.read_text(encoding="utf-8"), "existing")

    def test_cli_fails_closed_when_qa_secrets_are_missing(self) -> None:
        with self._workspace_temp_directory() as temp_dir:
            output = Path(temp_dir) / "runtime.json"
            env = dict(os.environ)
            env.pop("TIO_QA_SUPABASE_URL", None)
            env.pop("TIO_QA_SUPABASE_PUBLISHABLE_KEY", None)
            result = subprocess.run(
                [sys.executable, str(Path(__file__).with_name("mobile_qa_runtime_config.py")),
                 "--output", str(output)],
                capture_output=True,
                text=True,
                env=env,
                check=False,
            )
            self.assertEqual(result.returncode, 2)
            self.assertFalse(output.exists())
            self.assertEqual(result.stdout, "")
            self.assertIn("missing", result.stderr)


class WorkflowContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        root = Path(__file__).resolve().parents[2]
        cls.workflow = (root / ".github/workflows/mobile-qa-build.yml").read_text(
            encoding="utf-8"
        ).replace("\r\n", "\n")
        cls.old_workflow = root / ".github/workflows/ios-ui-build.yml"
        cls.android = cls.workflow.split("\n  android:\n", 1)[1].split(
            "\n  ios:\n", 1
        )[0]
        cls.ios = cls.workflow.split("\n  ios:\n", 1)[1]

    def test_manual_platform_choice_and_selected_job_only(self) -> None:
        trigger_block = self.workflow.split("on:\n", 1)[1].split(
            "\npermissions:", 1
        )[0]
        self.assertIn("workflow_dispatch:", trigger_block)
        self.assertIn("type: choice", trigger_block)
        self.assertIn("- android\n          - ios", trigger_block)
        self.assertNotIn("build_mode:", trigger_block)
        for trigger in (
            "push:", "pull_request:", "pull_request_target:", "schedule:",
            "repository_dispatch:", "workflow_run:",
        ):
            self.assertNotIn(trigger, trigger_block)
        self.assertIn("if: inputs.platform == 'android'", self.android)
        self.assertIn("if: inputs.platform == 'ios'", self.ios)
        self.assertIn("runs-on: ubuntu-latest", self.android)
        self.assertIn("runs-on: macos-15", self.ios)
        self.assertNotIn("ui_only", self.workflow)
        self.assertFalse(self.old_workflow.exists())

    def test_both_jobs_require_client_safe_qa_config_and_cleanup(self) -> None:
        self.assertIn("permissions:\n  contents: read", self.workflow)
        for job in (self.android, self.ios):
            self.assertIn("persist-credentials: false", job)
            self.assertIn("secrets.TIO_IOS_QA_SUPABASE_URL", job)
            self.assertIn("secrets.TIO_IOS_QA_SUPABASE_PUBLISHABLE_KEY", job)
            self.assertIn(".github/scripts/mobile_qa_runtime_config.py", job)
            self.assertIn("$RUNNER_TEMP/tio-mobile-qa-runtime.json", job)
            self.assertIn("--dart-define-from-file=", job)
            self.assertIn("trap 'rm -f", job)
            self.assertIn("if: always()\n        shell: bash\n        run: rm -f", job)
            self.assertIn("qa_mode=qa_login", job)
            self.assertNotIn("vars.TIO_", job)

    def test_artifacts_are_verified_and_exclude_runtime_config(self) -> None:
        self.assertIn("flutter build apk --debug --no-pub", self.android)
        self.assertNotIn("apps/wear", self.android)
        self.assertIn("sha256sum -c Tio-qa-debug.apk.sha256", self.android)
        self.assertIn("signing=ephemeral_android_debug", self.android)
        self.assertIn("flutter build ios --profile --no-codesign", self.ios)
        self.assertIn("lipo -archs", self.ios)
        self.assertIn("test ! -e \"$app_path/embedded.mobileprovision\"", self.ios)
        self.assertIn("shasum -a 256 -c Tio-unsigned-profile.ipa.sha256", self.ios)
        self.assertIn("test -s ios/Podfile.lock", self.ios)
        self.assertIn("signing=none", self.ios)
        for job in (self.android, self.ios):
            self.assertIn("test \"$source_sha\" = \"$build_sha\"", job)
            self.assertIn("workflow_run_number=$GITHUB_RUN_NUMBER", job)
            self.assertIn("retention-days: 7", job)
            for field in (
                "platform=", "qa_mode=qa_login", "source_sha=", "build_sha=",
                "flutter=", "artifact_type=", "signing=",
            ):
                self.assertIn(field, job)
            upload = job.split("uses: actions/upload-artifact@v4", 1)[1]
            self.assertIn("${{ github.run_number }}-${{ github.run_attempt }}", upload)
            self.assertIn("if-no-files-found: error", upload)
            self.assertNotIn("runtime.json", upload)
            self.assertNotIn(".json", upload)
            self.assertNotIn("keystore", upload)


if __name__ == "__main__":
    unittest.main()
