# Roblox Script Parser

Minimal plugin + local server to export Studio scripts to disk.

## Install
- Python: `pip install flask`
- Run server: `python server/app.py`
- Studio: enable HTTP Requests; add `plugin/Plugin.main.lua` as a Plugin.

## Use
1. Open the Script Parser dock.
2. Settings (top):
   - Python server URL
   - Output folder name
   - Include Tags (optional)
3. Select services to scan.
4. Click "Scan and Send".

## Output
- Flat when directly under a service: `<Service>/<ScriptName>.<type>.lua`
- Nested otherwise: `<Service>/<...>/<ScriptName>/<ScriptName>.<type>.lua`
- Extensions: `.server.lua` (Script), `.module.lua` (ModuleScript), `.local.lua` (LocalScript)
- Optional header: `-- TAGS: A, B` (when Include Tags is enabled and tags exist)

## Notes
- Large exports are chunked into multiple requests to avoid the 1MB limit.
- Output root can be overridden with `RBX_PARSE_OUT` env var.