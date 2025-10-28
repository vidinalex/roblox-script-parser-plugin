from flask import Flask, request, jsonify
from pathlib import Path
import os
import json

app = Flask(__name__)


def safe_name(name: str) -> str:
	return "".join(c for c in name if c.isalnum() or c in ("-", "_", " ")).rstrip()


def write_script(root_dir: Path, service: str, item: dict, include_tags: bool):
    # Build nested folders for each path segment, removing duplicates
    raw_segments = item.get("path", [])
    name = item.get("name", "Script")
    class_name = item.get("class", "Script")
    source = item.get("source", "")
    tags = item.get("tags") or []

    # Normalize segments: strip leading service name duplicates and trailing script name duplicates
    normalized = [safe_name(s) for s in raw_segments if isinstance(s, str) and len(s) > 0]
    if normalized and normalized[0].lower() == safe_name(service).lower():
        normalized = normalized[1:]
    # Remove consecutive duplicate names (e.g., testmodule/testmodule)
    deduped: list[str] = []
    for seg in normalized:
        if not deduped or deduped[-1].lower() != seg.lower():
            deduped.append(seg)
    # Avoid final folder duplicating the script name; we'll create ScriptName/ScriptName.lua anyway
    if deduped and deduped[-1].lower() == safe_name(name).lower():
        deduped = deduped[:-1]

    service_dir = root_dir / safe_name(service)
    current = service_dir
    for seg in deduped:
        current = current / seg

    # Determine extension based on class
    ext = ".lua"
    if class_name == "ModuleScript":
        ext = ".module.lua"
    elif class_name == "LocalScript":
        ext = ".local.lua"
    elif class_name == "Script":
        ext = ".server.lua"

    # Decide flat vs nested: if path resolves to just service/script, write flat
    # When there are no deeper segments (after normalization), write directly under service
    use_nested = len(deduped) > 0

    header = ""
    if include_tags and tags:
        header = f"-- TAGS: {', '.join(tags)}\n"

    if use_nested:
        script_folder = current / safe_name(name)
        script_folder.mkdir(parents=True, exist_ok=True)
        file_path = script_folder / f"{safe_name(name)}{ext}"
    else:
        (current).mkdir(parents=True, exist_ok=True)
        file_path = current / f"{safe_name(name)}{ext}"

    file_path.write_text(header + source, encoding="utf-8")


@app.post("/upload")
def upload():
	data = request.get_json(force=True, silent=True)
	if not isinstance(data, dict):
		return jsonify({"ok": False, "error": "Invalid JSON"}), 400

	requested = data.get("outputFolderName")
	base = requested if isinstance(requested, str) and len(requested.strip()) > 0 else None
	default_env = os.environ.get("RBX_PARSE_OUT")
	output_root = base or default_env or "output"

	output_dir = Path(output_root).resolve()
	output_dir.mkdir(parents=True, exist_ok=True)

	include_tags = bool(data.get("includeTags"))

	roots = data.get("roots", [])
	for root in roots:
		service = root.get("service", "UnknownService")
		items = root.get("items", [])
		for item in items:
			write_script(output_dir, service, item, include_tags)

	return jsonify({"ok": True, "output": str(output_dir)})


if __name__ == "__main__":
	app.run(host="127.0.0.1", port=5000, debug=False)


