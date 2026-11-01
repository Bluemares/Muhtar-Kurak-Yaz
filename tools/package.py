"""Package the tested game, excluding stale executables and personal saves."""
from pathlib import Path
import sys
import zipfile


def package(root):
    build = Path(root) / "build"
    outputs = []
    for name in ("web", "windows"):
        source = build / name
        output = build / ("MuhtarKurakYaz_" + name + ".zip")
        if name == "windows":
            current = source / "MuhtarKurakYaz-Guncel.exe"
            if not current.is_file():
                current = source / "MuhtarKurakYaz.exe"
            if not current.is_file():
                raise FileNotFoundError(current)
            files = [(current, "MuhtarKurakYaz.exe")]
        else:
            files = [(p, p.relative_to(source).as_posix()) for p in source.rglob("*")
                     if p.is_file() and p.suffix not in (".cfg", ".log", ".tmp", ".bak")
                     and p.name not in ("savegame.json", "profile.json")]
            if not any(n == "index.html" for _, n in files):
                raise FileNotFoundError(source / "index.html")
        staging = output.with_suffix(".zip.tmp")
        with zipfile.ZipFile(staging, "w", zipfile.ZIP_DEFLATED) as archive:
            for path, arcname in files:
                archive.write(path, arcname)
        staging.replace(output)
        outputs.append(output)
    return outputs


if __name__ == "__main__":
    for output in package(Path(sys.argv[1]).resolve()):
        print(output.name, round(output.stat().st_size / 1e6, 1), "MB")
