"""Contract checks for the runner, independent of Godot and player data."""
import os
from pathlib import Path
import sys
import tempfile
import unittest

from run_tests import execute, is_success


class RunnerTests(unittest.TestCase):
    def test_explicit_success(self):
        self.assertTrue(is_success("farm_cycle", 0, "TEST_OK farm_cycle\n"))

    def test_zero_exit_does_not_hide_assertion(self):
        self.assertFalse(is_success("x", 0, "SCRIPT ERROR: Assertion failed\nTEST_OK x\n"))

    def test_missing_wrong_and_skipped_markers(self):
        for output in ("", "TEST_OK xy\n", "TEST_SKIP x\n"):
            self.assertFalse(is_success("x", 0, output))

    def test_nonzero_exit(self):
        self.assertFalse(is_success("x", 1, "TEST_OK x\n"))

    def test_engine_and_legacy_save_errors(self):
        for error in ("ERROR: Cannot load resource", "SAVE FAIL roundtrip"):
            self.assertFalse(is_success("x", 0, error + "\nTEST_OK x\n"))

    def test_known_shutdown_leaks_are_warnings(self):
        self.assertTrue(is_success("x", 0, "TEST_OK x\n"
            "ERROR: 1 resources still in use at exit (run with --verbose for details).\n"
            "ERROR: 2 RID allocations of type 'RendererSceneCull' were leaked at exit.\n"))

    def test_timeout_kills_child(self):
        with tempfile.TemporaryDirectory() as folder:
            result = execute([sys.executable, "-c", "import time; time.sleep(30)"],
                             Path(folder) / "log", 0.1, os.environ.copy())
            self.assertEqual(result, "timeout")

    def test_script_failure_stops_without_waiting_for_timeout(self):
        with tempfile.TemporaryDirectory() as folder:
            result = execute([sys.executable, "-u", "-c",
                              "import time; print('SCRIPT ERROR: injected'); time.sleep(30)"],
                             Path(folder) / "log", 5, os.environ.copy(), fail_fast=True)
            self.assertEqual(result, "error")


if __name__ == "__main__":
    unittest.main()
