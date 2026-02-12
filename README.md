# Roblox Script Parser

Minimal plugin + local server to export Studio scripts to disk.

## Install
- Python: `pip install -r requirements.txt` (or `pip install flask`)
- Run server: `python server/app.py`
- Studio: enable HTTP Requests; add `plugin/Plugin.main.lua` as a Plugin.
  - If you install via `.rbxmx`, build one with `python tools/build_plugin_rbxmx.py` (outputs `dist/ParsePlugin.rbxmx`).

## Use
1. Open the Script Parser dock.
2. Settings (top):
   - Python server URL
   - Output folder name
   - Include UI (optional): exports UI roots as JSON files
   - Include Objects (optional): exports non-UI, non-script instances as JSON files
3. Select services to scan.
4. Click "Export" to write scripts to disk.
5. After editing locally, click "Review & Sync" to review changes and sync selected files back into Studio.
   - New local files can be created in the output folder and will show up as added items (e.g. `ServerScriptService/Folder2/MyScript.server.lua`).
   - New local instance files can be created and synced as added items (e.g. `StarterGui/MyUi.ScreenGui`).

## Output
- Root folder: `projects/<Output folder name>/` (for example: `projects/MyGame_output/`)
- Default structure: `<Service>/<...>/<ScriptName>.<type>.lua`
- If a script contains other scripts, it becomes a folder: `<Service>/<...>/<ScriptName>/<ScriptName>.<type>.lua` (nested scripts are written alongside it)
- Extensions: `.server.lua` (Script), `.module.lua` (ModuleScript), `.local.lua` (LocalScript)
- UI/Objects: `<Service>/<...>/<Name>.<ClassName>` containing JSON (when enabled)

## Notes
- Large exports are chunked into multiple requests to avoid the 1MB limit.
- Output root can be overridden with `RBX_PARSE_OUT` env var. Relative paths are resolved under `projects/`; absolute paths are used as-is.
- Instance diffs normalize float precision via `RBX_PARSE_FLOAT_DECIMALS` (default `5`) to reduce noise.
- Sync uses the local server `/diff` endpoint to compare exported files against current Studio sources.
