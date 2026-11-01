"""Run Godot scenes in a disposable project copy, with logs and explicit results."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import time


VISUAL = set("animal_motion farm_visual hoe_motion hoe_closeups work_closeups "
             "qa_late river_quest rock_closeup screenshots shots3d skin_anim skin_compare perf".split())
ROOT = Path(__file__).resolve().parents[1]
SHUTDOWN_LEAK = re.compile(
    r"^ERROR: (?:\d+ resources still in use at exit|\d+ RID allocations of type .* were leaked at exit\.)")


def execute(command, log, timeout, env, fail_fast=False):
    with log.open("w", encoding="utf-8") as output:
        process = subprocess.Popen(command, stdout=output, stderr=subprocess.STDOUT,
                                   env=env, creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
        deadline = time.monotonic() + timeout
        while True:
            try:
                code = process.wait(timeout=min(0.25, max(0.001, deadline - time.monotonic())))
                break
            except subprocess.TimeoutExpired:
                failed = fail_fast and errors(log.read_text(encoding="utf-8", errors="replace"))
                if failed or time.monotonic() >= deadline:
                    process.kill()
                    process.wait()
                    return "error" if failed else "timeout"
    return code


def errors(text):
    # Existing Godot shutdown resource-leak diagnostics are reported as warnings.
    # All other engine errors, script errors and legacy SAVE FAIL checks fail the run.
    return [line for line in text.splitlines()
            if re.search(r"SCRIPT ERROR:|^ERROR:|SAVE FAIL", line)
            and not SHUTDOWN_LEAK.match(line)]


def is_success(name, code, output):
    return code == 0 and f"TEST_OK {name}" in output.splitlines() and not errors(output)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("tests", nargs="*", help="Scene names; default: all scenes")
    parser.add_argument("--godot", default=os.environ.get("GODOT", "godot"))
    parser.add_argument("--visual", action="store_true", help="Run render tests in a window")
    parser.add_argument("--timeout", type=float, default=240, help="Wall seconds per scene")
    parser.add_argument("--seed", type=int, default=3, help="Farm-cycle regression seed")
    args = parser.parse_args()
    names = args.tests or sorted(p.stem for p in (ROOT / "tests").glob("*.tscn"))
    unknown = [n for n in names if n not in {p.stem for p in (ROOT / "tests").glob("*.tscn")}]
    if unknown:
        parser.error("Unknown scenes: " + ", ".join(unknown))
    executable = shutil.which(args.godot)
    if not executable:
        parser.error("Godot not found; provide --godot PATH or GODOT")
    workspace = Path(tempfile.mkdtemp(prefix="mk_tests_"))
    project = workspace / "project"
    print(f"Logs and isolated project: {workspace}", flush=True)
    shutil.copytree(ROOT, project, ignore=shutil.ignore_patterns(
        ".git", ".godot", "_downloads", "_templates", "build", "dev_gallery",
        "MUHTAR KURAK YAZ", ".claude", "_out", "shots", "__pycache__"))
    # Reuse imported assets, but never copy player saves/settings into the test project.
    imported = ROOT / ".godot" / "imported"
    if imported.exists():
        shutil.copytree(imported, project / ".godot" / "imported")
    (project / "tests" / "shots").mkdir(parents=True, exist_ok=True)
    # Also isolate user:// outputs (screenshots, logs) from the player's profile.
    config = project / "project.godot"
    config.write_text(config.read_text(encoding="utf-8").replace(
        "[application]", '[application]\nconfig/use_custom_user_dir=true\n'
        f'config/custom_user_dir="{(workspace / "user").as_posix()}"'), encoding="utf-8")
    env = os.environ.copy()
    base = [executable, "--path", str(project)]
    import_log = workspace / "import.log"
    result = execute(base + ["--headless", "--editor", "--import", "--quit"], import_log, 180, env)
    if result != 0 or errors(import_log.read_text(encoding="utf-8", errors="replace")):
        print(f"FAIL import ({result}); see {import_log}")
        return 1
    results = []
    for name in names:
        if name in VISUAL and not args.visual:
            results.append({"test": name, "status": "SKIP", "reason": "requires rendering"})
            print(f"SKIP {name}: requires --visual", flush=True)
            continue
        # Each scene starts without a save left behind by a previous scene.
        for filename in ("savegame.json", "profile.json", "user_settings.cfg"):
            (project / ".godot" / filename).unlink(missing_ok=True)
        command = base + ([] if args.visual else ["--headless"]) + [f"res://tests/{name}.tscn"]
        if name == "farm_cycle":
            command += ["--", f"--seed={args.seed}"]
        log = workspace / f"{name}.log"
        code = execute(command, log, args.timeout, env, fail_fast=True)
        output = log.read_text(encoding="utf-8", errors="replace")
        failures = errors(output)
        passed = is_success(name, code, output)
        status = "PASS" if passed else "FAIL"
        results.append({"test": name, "status": status, "exit": code, "errors": failures,
                        "shutdown_warnings": [line for line in output.splitlines()
                                              if SHUTDOWN_LEAK.match(line)]})
        print(f"{status} {name} (exit={code})", flush=True)
        for failure in failures[:3]:
            print(f"  {failure}", flush=True)
    (workspace / "results.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
    return int(any(r["status"] == "FAIL" for r in results))


if __name__ == "__main__":
    raise SystemExit(main())
