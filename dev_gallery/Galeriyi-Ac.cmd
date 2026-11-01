@echo off
set "GALLERY_GODOT=C:\Users\erkol\OneDrive\Desktop\Godot.exe"
if not exist "%GALLERY_GODOT%" set "GALLERY_GODOT=C:\Users\erkol\.codex\tools\godot\Godot_v4.5.1-stable_win64_console.exe"
if not exist "%GALLERY_GODOT%" (
  echo Godot bulunamadi. Godot editorunde dev_gallery/gallery.tscn dosyasini acip F6 tusuna basin.
  pause
  exit /b 1
)
start "Model Galerisi" "%GALLERY_GODOT%" --path "%~dp0.." --rendering-method gl_compatibility res://dev_gallery/gallery.tscn
