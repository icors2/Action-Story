#!/usr/bin/env python3
"""Validate game/data/*.json against JSON Schemas and cross-references. Exit 1 on any error."""
from __future__ import annotations

import json
import sys
from pathlib import Path

try:
    from jsonschema import Draft202012Validator
except ImportError:  # noqa: BLE001
    Draft202012Validator = None  # type: ignore[misc,assignment]

ROOT = Path(__file__).resolve().parents[1] / "game"
DATA = ROOT / "data"
SCHEMAS = DATA / "schemas"
errors: list[str] = []


def res_to_path(res: str) -> Path:
    return ROOT / res.removeprefix("res://")


def load(p: Path):
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except Exception as e:  # noqa: BLE001
        errors.append(f"{p}: {e}")
        return {}


if Draft202012Validator is None:
    print("warning: jsonschema not installed; skipping schema checks (pip install jsonschema)", file=sys.stderr)

index = load(DATA / "index.json")
ids: dict[str, set[str]] = {}
for category, files in index.items():
    if category == "schema_version":
        continue
    schema_file = SCHEMAS / f"{category}.schema.json"
    validator = None
    if Draft202012Validator is not None and schema_file.exists():
        validator = Draft202012Validator(load(schema_file))
    for res in files if isinstance(files, list) else [files]:
        doc = load(res_to_path(res))
        if validator:
            for err in validator.iter_errors(doc):
                errors.append(f"{res}: {'/'.join(map(str, err.path))}: {err.message}")
        bucket_key = category
        entries = []
        if isinstance(doc, dict):
            if category in ("stats", "level_table"):
                continue
            entries = doc.get(category, [])
        for entry in entries:
            if isinstance(entry, dict) and "id" in entry:
                bucket = ids.setdefault(bucket_key, set())
                if entry["id"] in bucket:
                    errors.append(f"{res}: duplicate {category} id {entry['id']}")
                bucket.add(entry["id"])
                if "scene" in entry:
                    scene_path = res_to_path(entry["scene"])
                    if not scene_path.exists():
                        errors.append(f"{res}: {entry['id']} scene not found {entry['scene']}")

if "drop_tables" in index:
    known_drops = ids.get("drop_tables", set())
    for res in index.get("mobs", []):
        for mob in load(res_to_path(res)).get("mobs", []):
            if mob.get("drop_table") not in known_drops:
                errors.append(f"mob {mob.get('id')}: unknown drop_table {mob.get('drop_table')}")

if errors:
    print("\n".join(errors))
    sys.exit(1)
print(f"OK: {sum(len(v) for v in ids.values())} definitions validated")
