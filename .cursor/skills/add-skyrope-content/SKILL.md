---
name: add-skyrope-content
description: Add a data-driven Skyrope mob, item, skill, map, quest, or NPC: JSON, schema, index rebuild, and placeholder scene if needed. Use when adding content rather than engine code.
---

# Add Skyrope content

## When to use

- Adding or changing entries in `game/data/`
- Authoring a map scene that data will reference
- Phase 13+ content expansion; also Phase 0+ sample defs

## Preconditions

- IDs are `snake_case`, unique per category, never renamed after Phase 11 (use `aliases` instead)
- Prefixes: `wpn_`, `pot_`, `etc_`, `dlg_`, `q_`, `npc_`, `dt_`, `shop_`
- Original names only. No MapleStory/Nexon names or ripped assets
- `"schema_version": 1` on every file

## Steps

1. Read `docs/CONTENT_GUIDE.md` (stub until Phase 13) and the matching example in `BUILD_SCOPE.md` §7.2.
2. Add or edit JSON under `game/data/`. Cast-minded: Godot parses JSON numbers as float; defs use `int(d["hp"])`.
3. If you add a file, list it in `game/data/index.json` via `python3 tools/build_index.py` (never hand-discover with `DirAccess`).
4. Satisfy `game/data/schemas/*.schema.json`. Run `python3 tools/validate_data.py`.
5. Cross-refs must exist (drop table → item, portal → map, quest → mob/item/npc).
6. Maps: one `.tscn` + JSON entry. Follow node names in BUILD_SCOPE Phase 5 (`Ground`, `Platforms` in group `oneway_platforms`, markers). Placeholder art = colored shapes; credit third-party assets in `docs/ASSET_CREDITS.md`.
7. Views/scenes referenced by `scene` / `icon` fields must exist or use Phase-appropriate placeholders.
8. Do not add a new skill *type* or hard-coded stat unless the existing four types / JSON fields cannot express it. Decision Log if you must.

## Verify

- `python3 tools/build_index.py --check`
- `python3 tools/validate_data.py`
- `make test` if defs or registry behavior changed

## Failure modes

- Adding a data file but not `index.json` → export/runtime miss
- Hard-coding balance numbers in GDScript → move to JSON
- Broken references that only fail in the editor → validator + `DataRegistry.validate_references()`
