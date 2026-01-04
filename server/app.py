from flask import Flask, request, jsonify
from pathlib import Path
from datetime import datetime, timezone
import json
import os
import hashlib
from typing import Optional

app = Flask(__name__)

MANIFEST_FILENAME = ".parser_manifest.json"
README_FILENAME = "README_Parser.md"


def _normalize_number(value):
	# NOTE: In Python, bool is a subclass of int. Keep bools intact.
	if isinstance(value, bool) or value is None:
		return value
	if isinstance(value, int):
		return value
	if isinstance(value, float):
		# Default to 5 decimals to absorb tiny float drift from Studio serialization
		# (e.g. 0.11372549019607843 vs 0.113725513...).
		decimals = int(os.environ.get("RBX_PARSE_FLOAT_DECIMALS", "5"))
		rounded = round(value, decimals)
		# Collapse integer-like floats to ints to avoid 1 vs 1.0 noise.
		if abs(rounded - round(rounded)) < 1e-12:
			return int(round(rounded))
		return rounded
	return value


def _normalize_json_value(value):
	"""
	Normalize JSON-decoded values to reduce false-positive diffs.

	- Rounds floats to a stable precision (default 5 decimals)
	- Collapses integer-like floats to ints
	- Recursively normalizes nested dicts/lists
	"""
	value = _normalize_number(value)
	if isinstance(value, list):
		return [_normalize_json_value(v) for v in value]
	if isinstance(value, dict):
		out = {}
		for k, v in value.items():
			# JSON object keys should be strings; ignore anything else.
			if isinstance(k, str):
				out[k] = _normalize_json_value(v)
		return out
	return value


def safe_name(name: str) -> str:
	# Keep names as close as possible to Studio while remaining filesystem-safe.
	# Windows is the strictest target: https://learn.microsoft.com/en-us/windows/win32/fileio/naming-a-file
	text = str(name or "")
	text = text.replace("\0", "")

	invalid = set('<>:"/\\|?*')
	clean = "".join(c for c in text if (ord(c) >= 32 and c not in invalid)).strip()

	# Windows cannot end a path component with a dot or space.
	if os.name == "nt":
		clean = clean.rstrip(". ").strip()

	if not clean:
		return "Unnamed"

	if os.name == "nt":
		upper = clean.upper()
		reserved = {
			"CON",
			"PRN",
			"AUX",
			"NUL",
			*(f"COM{i}" for i in range(1, 10)),
			*(f"LPT{i}" for i in range(1, 10)),
		}
		if upper in reserved:
			clean = "_" + clean

	return clean


def safe_name_legacy(name: str) -> str:
	"""
	Legacy sanitization used by earlier versions of the exporter.

	This is intentionally lossy (e.g. drops '@' and '.') but is kept so the
	server can map older on-disk paths back to Studio paths.
	"""
	text = str(name or "")
	clean = "".join(c for c in text if c.isalnum() or c in ("-", "_", " ")).strip()
	return clean if clean else "Unnamed"


def normalize_script_path(service: str, item: dict) -> list[str]:
	raw_segments = item.get("path", [])
	name = safe_name(str(item.get("name", "Script")))

	segments = [safe_name(s) for s in raw_segments if isinstance(s, str) and s.strip()]
	if segments and segments[0].lower() == safe_name(service).lower():
		segments = segments[1:]

	# Ensure the script's own name is included as the last segment for stable parent detection.
	if not segments:
		return [name]
	if segments[-1].lower() != name.lower():
		segments.append(name)
	else:
		segments[-1] = name
	return segments


def normalize_instance_path(service: str, item: dict) -> list[str]:
	raw_segments = item.get("path", [])
	name = safe_name(str(item.get("name", "Instance")))

	segments = [safe_name(s) for s in raw_segments if isinstance(s, str) and s.strip()]
	if segments and segments[0].lower() == safe_name(service).lower():
		segments = segments[1:]

	if not segments:
		return [name]
	if segments[-1].lower() != name.lower():
		segments.append(name)
	else:
		segments[-1] = name
	return segments


def _normalize_tree_node(obj) -> dict:
	if not isinstance(obj, dict):
		return {"class": "", "name": "", "props": {}, "attrs": {}, "children": []}
	props = obj.get("props", {})
	attrs = obj.get("attrs", {})
	children = obj.get("children", [])
	if not isinstance(props, dict):
		props = {}
	if not isinstance(attrs, dict):
		attrs = {}
	if not isinstance(children, list):
		children = []
	# Normalize leaf values to avoid float/representation drift (e.g., Color3/Vector components).
	props = {k: _normalize_json_value(v) for k, v in props.items() if isinstance(k, str)}
	attrs = {k: _normalize_json_value(v) for k, v in attrs.items() if isinstance(k, str)}
	return {
		"class": str(obj.get("class", "")),
		"name": str(obj.get("name", "")),
		"props": props,
		"attrs": attrs,
		"children": children,
	}


def canonicalize_instance_tree(tree) -> dict:
	"""
	Convert an arbitrary instance tree into a canonical, comparable shape.

	- Ensures each node has: class/name/props/attrs/children
	- Ensures props/attrs are dicts (treats [] and other types as empty dicts)
	- Canonicalizes children recursively
	- Sorts children deterministically for stable comparison (handles duplicate names)
	"""

	node = _normalize_tree_node(tree)

	children: list[dict] = []
	for child in node["children"]:
		if isinstance(child, dict):
			children.append(canonicalize_instance_tree(child))

	def child_base_key(n: dict) -> tuple[str, str]:
		return (str(n.get("name", "")).lower(), str(n.get("class", "")).lower())

	def child_sig(n: dict) -> str:
		try:
			normalized = json.dumps(n, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
			return hashlib.sha256(normalized.encode("utf-8", errors="replace")).hexdigest()
		except Exception:
			return ""

	# Sort primarily by (name,class). Only compute a content signature when needed to
	# stabilize ordering among duplicates of (name,class).
	grouped: dict[tuple[str, str], list[dict]] = {}
	for c in children:
		grouped.setdefault(child_base_key(c), []).append(c)

	ordered: list[dict] = []
	for k in sorted(grouped.keys()):
		group = grouped[k]
		if len(group) == 1:
			ordered.append(group[0])
		else:
			group.sort(key=child_sig)
			ordered.extend(group)

	children = ordered
	node["children"] = children
	return node


def merge_instance_tree(studio_tree: dict, local_tree: dict) -> dict:
	"""
	Merge `local_tree` on top of `studio_tree` to support partial local JSON.

	This makes `/diff_instances` stable even if local files omit properties that
	Studio reports (defaults or properties not tracked by the plugin exporter).
	"""

	base = _normalize_tree_node(studio_tree)
	overlay = _normalize_tree_node(local_tree)

	result = {
		"class": overlay["class"] or base["class"],
		"name": overlay["name"] or base["name"],
		"props": dict(base["props"]),
		"attrs": dict(base["attrs"]),
		"children": [],
	}

	for k, v in overlay["props"].items():
		if isinstance(k, str):
			result["props"][k] = _normalize_json_value(v)

	for k, v in overlay["attrs"].items():
		if isinstance(k, str):
			result["attrs"][k] = _normalize_json_value(v)

	def child_key(node: dict) -> tuple[str, str]:
		return (str(node.get("class", "")), str(node.get("name", "")))

	# NOTE: Children can legally contain duplicates of (class,name). Match by occurrence index
	# within each (class,name) group to avoid false diffs.
	base_groups: dict[tuple[str, str], list[dict]] = {}
	for child in base["children"]:
		if not isinstance(child, dict):
			continue
		cn = _normalize_tree_node(child)
		base_groups.setdefault(child_key(cn), []).append(cn)

	overlay_groups: dict[tuple[str, str], list[dict]] = {}
	for child in overlay["children"]:
		if not isinstance(child, dict):
			continue
		cn = _normalize_tree_node(child)
		overlay_groups.setdefault(child_key(cn), []).append(cn)

	def group_sort_key(k: tuple[str, str]) -> tuple[str, str]:
		return (k[1].lower(), k[0].lower())

	merged_children: list[dict] = []
	for ck in sorted(set(base_groups.keys()) | set(overlay_groups.keys()), key=group_sort_key):
		base_list = base_groups.get(ck, [])
		overlay_list = overlay_groups.get(ck, [])
		for i in range(max(len(base_list), len(overlay_list))):
			if i < len(base_list) and i < len(overlay_list):
				merged_children.append(merge_instance_tree(base_list[i], overlay_list[i]))
			elif i < len(overlay_list):
				merged_children.append(merge_instance_tree({}, overlay_list[i]))
			else:
				merged_children.append(base_list[i])

	def child_base_key(n: dict) -> tuple[str, str]:
		return (str(n.get("name", "")).lower(), str(n.get("class", "")).lower())

	def child_sig(n: dict) -> str:
		try:
			normalized = json.dumps(n, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
			return hashlib.sha256(normalized.encode("utf-8", errors="replace")).hexdigest()
		except Exception:
			return ""

	grouped: dict[tuple[str, str], list[dict]] = {}
	for c in merged_children:
		if isinstance(c, dict):
			grouped.setdefault(child_base_key(c), []).append(c)

	ordered: list[dict] = []
	for k in sorted(grouped.keys()):
		group = grouped[k]
		if len(group) == 1:
			ordered.append(group[0])
		else:
			group.sort(key=child_sig)
			ordered.extend(group)

	merged_children = ordered
	result["children"] = merged_children
	return result


def script_ext(class_name: str) -> str:
	if class_name == "ModuleScript":
		return ".module.lua"
	if class_name == "LocalScript":
		return ".local.lua"
	if class_name == "Script":
		return ".server.lua"
	return ".lua"


def strip_tags_header(text: str) -> str:
	# Legacy hook (kept for backward compatibility).
	# TAGS are treated as normal source now (no stripping in diff/load).
	return text


def repo_root() -> Path:
	# server/app.py -> repo root
	return Path(__file__).resolve().parent.parent


def resolve_output_dir(data: dict) -> Path:
	requested = data.get("outputFolderName")
	base = requested if isinstance(requested, str) and len(requested.strip()) > 0 else None
	default_env = os.environ.get("RBX_PARSE_OUT")
	output_root = base or default_env or "output"

	output_path = Path(output_root)
	if not output_path.is_absolute():
		output_path = repo_root() / output_path
	output_dir = output_path.resolve()
	output_dir.mkdir(parents=True, exist_ok=True)
	return output_dir


def sha256_text(text: str) -> str:
	return hashlib.sha256(text.encode("utf-8", errors="replace")).hexdigest()


def load_manifest(output_dir: Path) -> dict:
	path = output_dir / MANIFEST_FILENAME
	if not path.exists():
		return {"version": 1, "scripts": {}, "instances": {}}
	try:
		obj = json.loads(path.read_text(encoding="utf-8", errors="replace"))
	except (OSError, json.JSONDecodeError):
		return {"version": 1, "scripts": {}, "instances": {}}
	if not isinstance(obj, dict):
		return {"version": 1, "scripts": {}, "instances": {}}
	obj.setdefault("version", 1)
	obj.setdefault("scripts", {})
	obj.setdefault("instances", {})
	if not isinstance(obj.get("scripts"), dict):
		obj["scripts"] = {}
	if not isinstance(obj.get("instances"), dict):
		obj["instances"] = {}
	return obj


def save_manifest(output_dir: Path, manifest: dict) -> None:
	path = output_dir / MANIFEST_FILENAME
	manifest["updatedAt"] = datetime.now(timezone.utc).isoformat()
	path.write_text(json.dumps(manifest, ensure_ascii=False, sort_keys=True, indent=2) + "\n", encoding="utf-8")


def export_flags_from_payload(data: dict) -> dict:
	flags = data.get("exportFlags")
	out = {"scripts": False, "ui": False, "objects": False}

	if isinstance(flags, dict):
		out["scripts"] = bool(flags.get("scripts"))
		out["ui"] = bool(flags.get("ui"))
		out["objects"] = bool(flags.get("objects"))

	# Infer from payload if not supplied.
	if not out["scripts"]:
		out["scripts"] = isinstance(data.get("roots"), list) and len(data.get("roots") or []) > 0

	instances = data.get("instances")
	if isinstance(instances, list):
		for item in instances:
			if not isinstance(item, dict):
				continue
			mode = str(item.get("mode") or "").lower()
			if mode == "ui":
				out["ui"] = True
			if mode == "object":
				out["objects"] = True

	return out


def write_readme(output_dir: Path, flags: dict) -> None:
	contains: list[str] = []
	if flags.get("scripts"):
		contains.append("Scripts")
	if flags.get("ui"):
		contains.append("UI")
	if flags.get("objects"):
		contains.append("Game objects")
	if not contains:
		contains = ["(unknown)"]

	text = f"""# README_Parser

This folder is generated by the **Roblox Script Parser** plugin + local server.

## Contains
- {", ".join(contains)}

## How to use
1. Edit the exported files locally.
2. In Roblox Studio, open the plugin → **Review & Sync** to preview and sync changes back to Studio.

## Notes
- The exporter tracks what it last exported in `{MANIFEST_FILENAME}` so it can avoid overwriting local edits.
- If you re-export and a file was edited locally, the server may skip overwriting it to preserve your changes.
- UI/object export uses a **best-effort, whitelisted** set of properties and value types; unsupported properties are omitted.
"""
	(output_dir / README_FILENAME).write_text(text, encoding="utf-8")


def iter_records_from_payload(data: dict) -> list[tuple[str, dict, list[str]]]:
	records: list[tuple[str, dict, list[str]]] = []
	roots = data.get("roots", [])
	for root in roots:
		if not isinstance(root, dict):
			continue
		service = str(root.get("service", "UnknownService"))
		items = root.get("items", [])
		if not isinstance(items, list):
			continue
		for item in items:
			if not isinstance(item, dict):
				continue
			normalized = normalize_script_path(service, item)
			records.append((service, item, normalized))
	return records


def parent_paths_by_service(records: list[tuple[str, dict, list[str]]]) -> dict[str, set[tuple[str, ...]]]:
	paths_by_service: dict[str, set[tuple[str, ...]]] = {}
	for service, _item, normalized in records:
		paths_by_service.setdefault(service, set()).add(tuple(normalized))

	parent_by_service: dict[str, set[tuple[str, ...]]] = {}
	for service, paths in paths_by_service.items():
		parents: set[tuple[str, ...]] = set()
		for path in paths:
			for i in range(1, len(path)):
				prefix = path[:i]
				if prefix in paths:
					parents.add(prefix)
		parent_by_service[service] = parents
	return parent_by_service


def local_file_path(
	output_dir: Path,
	service: str,
	item: dict,
	normalized_path: list[str],
	is_parent_script: bool,
) -> Path:
	name = normalized_path[-1] if normalized_path else safe_name(str(item.get("name", "Script")))
	class_name = str(item.get("class", "Script"))
	ext = script_ext(class_name)

	service_dir = output_dir / safe_name(service)
	dir_segments = [seg for seg in normalized_path[:-1] if seg]
	current = service_dir
	for seg in dir_segments:
		current = current / seg

	if is_parent_script:
		return current / name / f"{name}{ext}"
	return current / f"{name}{ext}"


def existing_local_file_path(output_dir: Path, service: str, item: dict, normalized_path: list[str]) -> Optional[Path]:
	name = normalized_path[-1] if normalized_path else safe_name(str(item.get("name", "Script")))
	class_name = str(item.get("class", "Script"))
	ext = script_ext(class_name)

	service_dir = output_dir / safe_name(service)
	dir_segments = [seg for seg in normalized_path[:-1] if seg]
	current = service_dir
	for seg in dir_segments:
		current = current / seg

	flat = current / f"{name}{ext}"
	folder = current / name / f"{name}{ext}"

	candidates: list[Path] = []
	if flat.exists():
		candidates.append(flat)
	if folder.exists():
		candidates.append(folder)

	# Backward-compatibility: older exports used a stricter, lossy sanitizer.
	legacy_dir_segments = [safe_name_legacy(seg) for seg in normalized_path[:-1] if seg]
	legacy_name = safe_name_legacy(name)
	if legacy_dir_segments != dir_segments or legacy_name != name:
		legacy_current = service_dir
		for seg in legacy_dir_segments:
			legacy_current = legacy_current / seg
		legacy_flat = legacy_current / f"{legacy_name}{ext}"
		legacy_folder = legacy_current / legacy_name / f"{legacy_name}{ext}"
		if legacy_flat.exists():
			candidates.append(legacy_flat)
		if legacy_folder.exists():
			candidates.append(legacy_folder)

	if not candidates:
		return None
	if len(candidates) == 1:
		return candidates[0]

	# Prefer the newest file if both exist (handles stale outputs)
	def mtime(p: Path) -> float:
		try:
			return p.stat().st_mtime
		except OSError:
			return 0.0

	candidates.sort(key=mtime, reverse=True)
	return candidates[0]


def instance_local_file_path(output_dir: Path, service: str, item: dict, normalized_path: list[str]) -> Path:
	name = normalized_path[-1] if normalized_path else safe_name(str(item.get("name", "Instance")))
	class_name = safe_name(str(item.get("class", "Folder")))

	service_dir = output_dir / safe_name(service)
	dir_segments = [seg for seg in normalized_path[:-1] if seg]
	current = service_dir
	for seg in dir_segments:
		current = current / seg
	current.mkdir(parents=True, exist_ok=True)
	return current / f"{name}.{class_name}"


def class_from_filename(filename: str) -> str:
	lower = filename.lower()
	if lower.endswith(".server.lua"):
		return "Script"
	if lower.endswith(".local.lua"):
		return "LocalScript"
	if lower.endswith(".module.lua"):
		return "ModuleScript"
	return "ModuleScript"


def script_name_from_filename(filename: str) -> str:
	lower = filename.lower()
	if lower.endswith(".server.lua"):
		return filename[: -len(".server.lua")]
	if lower.endswith(".local.lua"):
		return filename[: -len(".local.lua")]
	if lower.endswith(".module.lua"):
		return filename[: -len(".module.lua")]
	if lower.endswith(".lua"):
		return filename[: -len(".lua")]
	return filename


def safe_rel_path(path: Path, base: Path) -> str:
	base_resolved = base.resolve()
	path_resolved = path.resolve()
	try:
		path_resolved.relative_to(base_resolved)
	except ValueError:
		raise ValueError("path escapes base directory")
	return str(path_resolved.relative_to(base_resolved)).replace("\\", "/")


def write_script(
	root_dir: Path,
	service: str,
	item: dict,
	is_parent_script: bool,
	normalized_path: list[str],
	manifest: dict,
):
	name = normalized_path[-1] if normalized_path else safe_name(str(item.get("name", "Script")))
	class_name = str(item.get("class", "Script"))
	source = str(item.get("source", ""))

	service_dir = root_dir / safe_name(service)
	dir_segments = [seg for seg in normalized_path[:-1] if seg]
	current = service_dir
	for seg in dir_segments:
		current = current / seg
	current.mkdir(parents=True, exist_ok=True)

	ext = script_ext(class_name)
	if is_parent_script:
		script_folder = current / name
		script_folder.mkdir(parents=True, exist_ok=True)
		file_path = script_folder / f"{name}{ext}"
	else:
		file_path = current / f"{name}{ext}"

	new_text = source
	new_hash = sha256_text(new_text.replace("\r\n", "\n"))

	rel = safe_rel_path(file_path, root_dir)
	existing_hash = None
	recorded_hash = None
	if isinstance(manifest.get("scripts"), dict):
		recorded_hash = manifest["scripts"].get(rel)

	if file_path.exists():
		try:
			existing_text = file_path.read_text(encoding="utf-8", errors="replace").replace("\r\n", "\n")
			existing_hash = sha256_text(existing_text)
		except OSError:
			existing_hash = None

		# Only overwrite if:
		# - the manifest says the file matches the last export, or
		# - the file already matches the new content.
		if recorded_hash is not None and existing_hash is not None and recorded_hash != existing_hash:
			manifest.setdefault("skipped", []).append({"type": "script", "relPath": rel, "reason": "local edits"})
			return False
		if existing_hash is not None and existing_hash != new_hash and recorded_hash is None:
			manifest.setdefault("skipped", []).append({"type": "script", "relPath": rel, "reason": "no manifest entry"})
			return False

	file_path.write_text(new_text, encoding="utf-8")
	manifest.setdefault("scripts", {})[rel] = new_hash
	return True


def write_instance(root_dir: Path, service: str, item: dict, normalized_path: list[str], manifest: dict):
	raw_tree = item.get("tree") or {}
	try:
		tree = canonicalize_instance_tree(raw_tree)
	except Exception:
		tree = {"error": "invalid tree", "raw": raw_tree}
	path = instance_local_file_path(root_dir, service, item, normalized_path)
	try:
		text = json.dumps(tree, ensure_ascii=False, sort_keys=True, indent=2) + "\n"
	except TypeError:
		text = json.dumps({"error": "non-serializable tree"}, ensure_ascii=False, sort_keys=True, indent=2) + "\n"

	normalized = json.dumps(tree, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
	new_hash = sha256_text(normalized)
	rel = safe_rel_path(path, root_dir)
	existing_hash = None
	recorded_hash = None
	if isinstance(manifest.get("instances"), dict):
		recorded_hash = manifest["instances"].get(rel)

	if path.exists():
		try:
			raw = path.read_text(encoding="utf-8", errors="replace")
			obj = json.loads(raw)
			existing_hash = sha256_text(json.dumps(obj, ensure_ascii=False, sort_keys=True, separators=(",", ":")))
		except (OSError, json.JSONDecodeError, TypeError):
			existing_hash = None

		if recorded_hash is not None and existing_hash is not None and recorded_hash != existing_hash:
			manifest.setdefault("skipped", []).append({"type": "instance", "relPath": rel, "reason": "local edits"})
			return False
		if existing_hash is not None and existing_hash != new_hash and recorded_hash is None:
			manifest.setdefault("skipped", []).append({"type": "instance", "relPath": rel, "reason": "no manifest entry"})
			return False

	path.write_text(text, encoding="utf-8")
	manifest.setdefault("instances", {})[rel] = new_hash
	return True


@app.post("/upload")
def upload():
	data = request.get_json(force=True, silent=True)
	if not isinstance(data, dict):
		return jsonify({"ok": False, "error": "Invalid JSON"}), 400

	output_dir = resolve_output_dir(data)
	flags = export_flags_from_payload(data)
	flags["scripts"] = True
	manifest = load_manifest(output_dir)

	records = iter_records_from_payload(data)
	parent_by_service = parent_paths_by_service(records)
	wrote = 0
	skipped = 0
	for service, item, normalized in records:
		is_parent = tuple(normalized) in parent_by_service.get(service, set())
		if write_script(output_dir, service, item, is_parent, normalized, manifest):
			wrote += 1
		else:
			skipped += 1

	write_readme(output_dir, flags)
	save_manifest(output_dir, manifest)
	return jsonify({"ok": True, "output": str(output_dir), "wrote": wrote, "skipped": skipped})


@app.post("/upload_instances")
def upload_instances():
	data = request.get_json(force=True, silent=True)
	if not isinstance(data, dict):
		return jsonify({"ok": False, "error": "Invalid JSON"}), 400

	output_dir = resolve_output_dir(data)
	flags = export_flags_from_payload(data)
	manifest = load_manifest(output_dir)
	if isinstance(manifest.get("scripts"), dict) and len(manifest.get("scripts") or {}) > 0:
		flags["scripts"] = True

	instances = data.get("instances", [])
	if not isinstance(instances, list):
		return jsonify({"ok": False, "error": "instances must be a list"}), 400

	wrote = 0
	skipped = 0
	for item in instances:
		if not isinstance(item, dict):
			continue
		service = str(item.get("service", "UnknownService"))
		normalized = normalize_instance_path(service, item)
		if write_instance(output_dir, service, item, normalized, manifest):
			wrote += 1
		else:
			skipped += 1

	write_readme(output_dir, flags)
	save_manifest(output_dir, manifest)
	return jsonify({"ok": True, "output": str(output_dir), "wrote": wrote, "skipped": skipped})


@app.post("/skipped")
def skipped():
	data = request.get_json(force=True, silent=True)
	if not isinstance(data, dict):
		return jsonify({"ok": False, "error": "Invalid JSON"}), 400

	output_dir = resolve_output_dir(data)

	skipped_list = data.get("skipped") or []
	log_path = output_dir / "skipped.txt"

	with log_path.open("a", encoding="utf-8") as f:
		for entry in skipped_list:
			service = entry.get("service", "?")
			name = entry.get("name", "?")
			cls = entry.get("class", "?")
			path = "/".join(entry.get("path", []))
			reason = entry.get("reason", "unknown")
			f.write(f"{service}/{path}/{name} [{cls}] - {reason}\n")

	return jsonify({"ok": True, "wrote": len(skipped_list)})


@app.post("/diff")
def diff():
	data = request.get_json(force=True, silent=True)
	if not isinstance(data, dict):
		return jsonify({"ok": False, "error": "Invalid JSON"}), 400

	output_dir = resolve_output_dir(data)
	records = iter_records_from_payload(data)

	changes: list[dict] = []
	missing_local: list[dict] = []
	skipped_large: list[dict] = []

	max_read_bytes = 900 * 1024
	for service, item, normalized in records:
		path = existing_local_file_path(output_dir, service, item, normalized)

		if not path:
			missing_local.append(
				{
					"service": service,
					"name": item.get("name"),
					"class": item.get("class"),
					"path": item.get("path"),
					"file": None,
				}
			)
			continue

		try:
			if path.stat().st_size > max_read_bytes:
				skipped_large.append(
					{
						"service": service,
						"name": item.get("name"),
						"class": item.get("class"),
						"path": item.get("path"),
						"file": str(path),
						"reason": "file too large",
					}
				)
				continue

			local_text = path.read_text(encoding="utf-8", errors="replace").replace("\r\n", "\n")
		except OSError as e:
			skipped_large.append(
				{
					"service": service,
					"name": item.get("name"),
					"class": item.get("class"),
					"path": item.get("path"),
					"file": str(path),
					"reason": str(e),
				}
			)
			continue

		local_text = strip_tags_header(local_text)
		studio_text = str(item.get("source", "")).replace("\r\n", "\n")

		if local_text != studio_text:
			changes.append(
				{
					"service": service,
					"name": item.get("name"),
					"class": item.get("class"),
					"path": item.get("path"),
					"file": str(path),
					"localSource": local_text,
				}
			)

	return jsonify(
		{
			"ok": True,
			"output": str(output_dir),
			"changes": changes,
			"missingLocal": missing_local,
			"skippedLarge": skipped_large,
		}
	)


@app.post("/diff_instances")
def diff_instances():
	data = request.get_json(force=True, silent=True)
	if not isinstance(data, dict):
		return jsonify({"ok": False, "error": "Invalid JSON"}), 400

	output_dir = resolve_output_dir(data)
	instances = data.get("instances", [])
	if not isinstance(instances, list):
		return jsonify({"ok": False, "error": "instances must be a list"}), 400

	changes: list[dict] = []
	missing_local: list[dict] = []
	skipped_large: list[dict] = []

	max_read_bytes = 900 * 1024
	for item in instances:
		if not isinstance(item, dict):
			continue
		service = str(item.get("service", "UnknownService"))
		normalized = normalize_instance_path(service, item)
		path = instance_local_file_path(output_dir, service, item, normalized)
		if not path.exists():
			missing_local.append(
				{
					"service": service,
					"name": item.get("name"),
					"class": item.get("class"),
					"path": item.get("path"),
					"file": None,
					"relPath": None,
				}
			)
			continue

		try:
			if path.stat().st_size > max_read_bytes:
				skipped_large.append(
					{
						"service": service,
						"name": item.get("name"),
						"class": item.get("class"),
						"path": item.get("path"),
						"file": str(path),
						"relPath": safe_rel_path(path, output_dir),
						"reason": "file too large",
					}
				)
				continue
			local_text = path.read_text(encoding="utf-8", errors="replace").replace("\r\n", "\n")
		except OSError as e:
			skipped_large.append(
				{
					"service": service,
					"name": item.get("name"),
					"class": item.get("class"),
					"path": item.get("path"),
					"file": str(path),
					"relPath": safe_rel_path(path, output_dir),
					"reason": str(e),
				}
			)
			continue

		try:
			local_obj = json.loads(local_text)
		except json.JSONDecodeError:
			changes.append(
				{
					"service": service,
					"name": item.get("name"),
					"class": item.get("class"),
					"path": item.get("path"),
					"file": str(path),
					"relPath": safe_rel_path(path, output_dir),
				}
			)
			continue

		studio_tree = item.get("tree") or {}
		canon_studio = canonicalize_instance_tree(studio_tree)
		canon_local = canonicalize_instance_tree(local_obj)
		effective_local = merge_instance_tree(canon_studio, canon_local)

		local_norm = json.dumps(effective_local, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
		studio_norm = json.dumps(canon_studio, ensure_ascii=False, sort_keys=True, separators=(",", ":"))

		if local_norm != studio_norm:
			changes.append(
				{
					"service": service,
					"name": item.get("name"),
					"class": item.get("class"),
					"path": item.get("path"),
					"file": str(path),
					"relPath": safe_rel_path(path, output_dir),
				}
			)

	return jsonify(
		{
			"ok": True,
			"output": str(output_dir),
			"changes": changes,
			"missingLocal": missing_local,
			"skippedLarge": skipped_large,
		}
	)


@app.post("/local_index")
def local_index():
	data = request.get_json(force=True, silent=True)
	if not isinstance(data, dict):
		return jsonify({"ok": False, "error": "Invalid JSON"}), 400

	output_dir = resolve_output_dir(data)

	service_filter = None
	services = data.get("services")
	if isinstance(services, list) and services:
		service_filter = {str(s) for s in services if isinstance(s, str) and s.strip()}

	studio_paths = data.get("studioPaths")
	studio_path_set: set[tuple[str, ...]] = set()
	legacy_to_real: dict[tuple[str, ...], Optional[tuple[str, ...]]] = {}
	if isinstance(studio_paths, list):
		for p in studio_paths:
			if not isinstance(p, list) or len(p) == 0:
				continue
			if not all(isinstance(seg, str) and seg.strip() for seg in p):
				continue
			if service_filter is not None and p[0] not in service_filter:
				continue
			tp = tuple(p)
			studio_path_set.add(tp)

			legacy = tuple(safe_name_legacy(seg) for seg in p)
			existing = legacy_to_real.get(legacy)
			if existing is None:
				# Either first time, or already marked ambiguous.
				if legacy not in legacy_to_real:
					legacy_to_real[legacy] = tp
			elif existing != tp:
				# Ambiguous: multiple Studio paths collide under legacy sanitization.
				legacy_to_real[legacy] = None

	def map_to_studio_path(segments: list[str]) -> list[str]:
		if not studio_path_set:
			return segments
		t = tuple(segments)
		if t in studio_path_set:
			return segments
		legacy = tuple(safe_name_legacy(seg) for seg in segments)
		mapped = legacy_to_real.get(legacy)
		if mapped:
			return list(mapped)
		return segments

	items: list[dict] = []
	for file_path in output_dir.rglob("*.lua"):
		if not file_path.is_file():
			continue

		try:
			rel = safe_rel_path(file_path, output_dir)
		except ValueError:
			continue

		parts = [p for p in rel.split("/") if p]
		if len(parts) < 2:
			continue

		service = parts[0]
		if service_filter is not None and service not in service_filter:
			continue
		filename = parts[-1]
		class_name = class_from_filename(filename)
		script_name = script_name_from_filename(filename)

		dirs = parts[1:-1]
		if dirs and dirs[-1].lower() == script_name.lower():
			full_segments = map_to_studio_path([service] + dirs + [script_name])
			collapsed_segments = map_to_studio_path([service] + dirs[:-1] + [script_name])
			if studio_path_set:
				if tuple(full_segments) in studio_path_set:
					path_segments = full_segments
				elif tuple(collapsed_segments) in studio_path_set:
					path_segments = collapsed_segments
				else:
					path_segments = full_segments
			else:
				path_segments = full_segments
		else:
			path_segments = map_to_studio_path([service] + dirs + [script_name])

		try:
			size = file_path.stat().st_size
		except OSError:
			size = None

		items.append(
			{
				"relPath": rel,
				"service": service,
				"path": path_segments,
				"name": script_name,
				"class": class_name,
				"size": size,
			}
		)

	return jsonify({"ok": True, "output": str(output_dir), "items": items})


@app.post("/local_index_instances")
def local_index_instances():
	data = request.get_json(force=True, silent=True)
	if not isinstance(data, dict):
		return jsonify({"ok": False, "error": "Invalid JSON"}), 400

	output_dir = resolve_output_dir(data)

	service_filter = None
	services = data.get("services")
	if isinstance(services, list) and services:
		service_filter = {str(s) for s in services if isinstance(s, str) and s.strip()}

	studio_paths = data.get("studioPaths")
	studio_path_set: set[tuple[str, ...]] = set()
	legacy_to_real: dict[tuple[str, ...], Optional[tuple[str, ...]]] = {}
	if isinstance(studio_paths, list):
		for p in studio_paths:
			if not isinstance(p, list) or len(p) == 0:
				continue
			if not all(isinstance(seg, str) and seg.strip() for seg in p):
				continue
			if service_filter is not None and p[0] not in service_filter:
				continue
			tp = tuple(p)
			studio_path_set.add(tp)

			legacy = tuple(safe_name_legacy(seg) for seg in p)
			existing = legacy_to_real.get(legacy)
			if existing is None:
				if legacy not in legacy_to_real:
					legacy_to_real[legacy] = tp
			elif existing != tp:
				legacy_to_real[legacy] = None

	def map_to_studio_path(segments: list[str]) -> list[str]:
		if not studio_path_set:
			return segments
		t = tuple(segments)
		if t in studio_path_set:
			return segments
		legacy = tuple(safe_name_legacy(seg) for seg in segments)
		mapped = legacy_to_real.get(legacy)
		if mapped:
			return list(mapped)
		return segments

	items: list[dict] = []
	for file_path in output_dir.rglob("*"):
		if not file_path.is_file():
			continue
		if file_path.suffix.lower() == ".lua":
			continue
		if file_path.name.lower() in ("skipped.txt",):
			continue

		try:
			rel = safe_rel_path(file_path, output_dir)
		except ValueError:
			continue

		parts = [p for p in rel.split("/") if p]
		if len(parts) < 2:
			continue

		service = parts[0]
		if service_filter is not None and service not in service_filter:
			continue

		class_name = file_path.suffix[1:] if file_path.suffix.startswith(".") else ""
		name = file_path.stem
		if not class_name or not name:
			continue

		try:
			if file_path.stat().st_size > 900 * 1024:
				continue
			raw = file_path.read_text(encoding="utf-8", errors="replace")
			obj = json.loads(raw)
		except (OSError, json.JSONDecodeError):
			continue
		if not isinstance(obj, dict):
			continue
		if "class" not in obj or "name" not in obj:
			continue

		dirs = parts[1:-1]
		path_segments = map_to_studio_path([service] + dirs + [name])

		try:
			size = file_path.stat().st_size
		except OSError:
			size = None

		items.append(
			{
				"relPath": rel,
				"service": service,
				"path": path_segments,
				"name": (path_segments[-1] if path_segments else name),
				"class": class_name,
				"size": size,
			}
		)

	return jsonify({"ok": True, "output": str(output_dir), "items": items})


@app.post("/local_get")
def local_get():
	data = request.get_json(force=True, silent=True)
	if not isinstance(data, dict):
		return jsonify({"ok": False, "error": "Invalid JSON"}), 400

	output_dir = resolve_output_dir(data)
	rel = data.get("relPath")
	if not isinstance(rel, str) or not rel.strip():
		return jsonify({"ok": False, "error": "relPath required"}), 400

	candidate = (output_dir / rel).resolve()
	try:
		_ = safe_rel_path(candidate, output_dir)
	except ValueError:
		return jsonify({"ok": False, "error": "Invalid path"}), 400

	if not candidate.exists() or not candidate.is_file():
		return jsonify({"ok": False, "error": "File not found"}), 404

	max_read_bytes = 900 * 1024
	try:
		if candidate.stat().st_size > max_read_bytes:
			return jsonify({"ok": False, "error": "File too large"}), 413
		text = candidate.read_text(encoding="utf-8", errors="replace").replace("\r\n", "\n")
	except OSError as e:
		return jsonify({"ok": False, "error": str(e)}), 500

	text = strip_tags_header(text)
	return jsonify({"ok": True, "relPath": rel, "source": text})


@app.post("/local_get_instances")
def local_get_instances():
	data = request.get_json(force=True, silent=True)
	if not isinstance(data, dict):
		return jsonify({"ok": False, "error": "Invalid JSON"}), 400

	output_dir = resolve_output_dir(data)
	rel = data.get("relPath")
	if not isinstance(rel, str) or not rel.strip():
		return jsonify({"ok": False, "error": "relPath required"}), 400

	candidate = (output_dir / rel).resolve()
	try:
		_ = safe_rel_path(candidate, output_dir)
	except ValueError:
		return jsonify({"ok": False, "error": "Invalid path"}), 400

	if not candidate.exists() or not candidate.is_file():
		return jsonify({"ok": False, "error": "File not found"}), 404

	max_read_bytes = 900 * 1024
	try:
		if candidate.stat().st_size > max_read_bytes:
			return jsonify({"ok": False, "error": "File too large"}), 413
		text = candidate.read_text(encoding="utf-8", errors="replace").replace("\r\n", "\n")
	except OSError as e:
		return jsonify({"ok": False, "error": str(e)}), 500

	try:
		tree = json.loads(text)
	except json.JSONDecodeError as e:
		return jsonify({"ok": False, "error": f"Invalid JSON: {e}"}), 400

	try:
		canon = canonicalize_instance_tree(tree)
	except Exception:
		canon = tree
	pretty = json.dumps(canon, ensure_ascii=False, sort_keys=True, indent=2) + "\n"
	return jsonify({"ok": True, "relPath": rel, "tree": canon, "pretty": pretty})


if __name__ == "__main__":
	app.run(host="127.0.0.1", port=5000, debug=False)


