"""Conservative, read-only inventory of unused bundled models.

Review candidates before deletion. Runtime and standalone test scripts are roots.
The gallery enumerates whatever remains; enumeration is not gameplay use.
Custom building overrides, characters, pets, textures and licenses are preserved.
"""
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def audit():
    files = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT).decode().split("\0")
    sources = [ROOT / f for f in files if Path(f).suffix in
               {".gd", ".tscn", ".tres", ".godot", ".py"} and (ROOT / f).exists()
               and f != "tools/audit_assets.py"]
    text = "\n".join(p.read_text(encoding="utf-8", errors="replace") for p in sources)
    literals = re.findall(r'''["']([^"'\n]+)["']''', text)
    unused = []
    for filename in files:
        p = ROOT / filename
        if p.suffix != ".glb" or not p.exists():
            continue
        if p.parent.name not in {"nature", "town", "car"}:
            continue
        name = p.stem
        # Includes full paths and bare names in dynamic selection arrays.
        if any(name == s or s.endswith("/" + name) or s.endswith("/" + name + ".glb")
               for s in literals):
            continue
        for asset in (p, Path(str(p) + ".import")):
            if asset.exists():
                unused.append({"path": asset.relative_to(ROOT).as_posix(),
                               "bytes": asset.stat().st_size})
    return unused


if __name__ == "__main__":
    candidates = audit()
    print(json.dumps({"candidates": candidates, "files": len(candidates),
                      "bytes": sum(p["bytes"] for p in candidates)}, indent=2))
