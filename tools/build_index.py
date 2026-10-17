#!/usr/bin/env python3
"""Regenerate game/data/index.json. --check fails if the committed index is stale."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "game" / "data"
INDEX = DATA / "index.json"


def res(path: Path) -> str:
    rel = path.relative_to(ROOT / "game").as_posix()
    return f"res://{rel}"


def collect() -> dict:
    skills = sorted(res(p) for p in (DATA / "skills").glob("*.json"))
    mobs = sorted(res(p) for p in (DATA / "mobs").glob("*.json"))
    maps = sorted(res(p) for p in (DATA / "maps").glob("*.json"))
    items_dir = DATA / "items"
    items = sorted(res(p) for p in items_dir.glob("*.json")) if items_dir.exists() else []
    quests = sorted(res(p) for p in (DATA / "quests").glob("*.json")) if (DATA / "quests").exists() else []
    npcs = sorted(res(p) for p in (DATA / "npcs").glob("*.json")) if (DATA / "npcs").exists() else []
    dialogues = (
        sorted(res(p) for p in (DATA / "dialogue").glob("*.json")) if (DATA / "dialogue").exists() else []
    )
    index: dict = {
        "schema_version": 1,
        "stats": res(DATA / "stats.json"),
        "level_table": res(DATA / "level_table.json"),
        "skills": skills,
        "mobs": mobs,
        "maps": maps,
    }
    if items:
        index["items"] = items
    drop = DATA / "drop_tables.json"
    if drop.exists():
        index["drop_tables"] = [res(drop)]
    classes = DATA / "classes.json"
    if classes.exists():
        index["classes"] = [res(classes)]
    if quests:
        index["quests"] = quests
    if npcs:
        index["npcs"] = npcs
    if dialogues:
        index["dialogues"] = dialogues
    shops = DATA / "shops.json"
    if shops.exists():
        index["shops"] = [res(shops)]
    return index


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    generated = collect()
    text = json.dumps(generated, indent=2) + "\n"
    if args.check:
        if not INDEX.exists():
            print("missing game/data/index.json", file=sys.stderr)
            return 1
        current = json.loads(INDEX.read_text(encoding="utf-8"))
        if current != generated:
            print("game/data/index.json is stale; run python3 tools/build_index.py", file=sys.stderr)
            return 1
        print("OK: index.json is up to date")
        return 0
    INDEX.write_text(text, encoding="utf-8")
    print(f"wrote {INDEX}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
