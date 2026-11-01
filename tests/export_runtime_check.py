from pathlib import Path
import re
import subprocess
import sys

project = Path('project.godot')
presets = Path('export_presets.cfg')
original_project = project.read_bytes()
original_presets = presets.read_bytes()
try:
    text = original_project.decode('utf-8')
    text = re.sub(r'^run/main_scene=.*$', 'run/main_scene="res://tests/'+sys.argv[1]+'.tscn"', text, flags=re.M)
    project.write_text(text, encoding='utf-8')
    text = original_presets.decode('utf-8')
    preset = text.split('[preset.1]')[0].replace('preset.0','preset.2').replace('name="Windows"','name="RuntimeCheck"')
    preset = preset.replace('tests/*, docs/*', 'tests/shots/*, tests/_cmp/*, tests/_out/*, docs/*')
    presets.write_text(text+'\n'+preset, encoding='utf-8')
    with open('C:/Users/erkol/.codex/tools/godot/runtime-export.log','w') as log:
        subprocess.run(['C:/Users/erkol/.codex/tools/godot/Godot_v4.5.1-stable_win64_console.exe','--headless','--path','.', '--export-release','RuntimeCheck','C:/Users/erkol/.codex/tools/godot/RuntimeCheck.exe'], stdout=log,stderr=log,check=True)
finally:
    project.write_bytes(original_project)
    presets.write_bytes(original_presets)
