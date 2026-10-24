---
name: verify-godot-change
description: Prove a Skyrope game change works: headless boot, GUT, data validation, and architecture greps. Use after any game/sim/shared/client/data/tools edit.
---

# Verify a Godot change

## When to use

- After implementing or fixing anything under `game/`, `tools/`, or game CI
- As the smoke bar for `implement-skyrope-phase`

## Preconditions

- `godot` on PATH matches `.godot-version` (4.7.2-stable)
- `game/project.godot` exists (Phase 0+)
- `game/.godot/` exists. If not: `godot --headless --import --path game` first. Fresh ZIP/clone without import fails autoloads (`Could not find type "StatsConfig"`).

## Steps

1. Headless boot (catches autoload/script errors):
   `godot --headless --path game --quit-after 120`
2. GUT:
   `godot --headless --path game -s addons/gut/gut_cmdln.gd -gexit`
   or `make test` if the Makefile exists.
3. Data (once `tools/` exist):
   `python3 tools/build_index.py --check && python3 tools/validate_data.py`
4. Architecture greps (fail the change if they match):
   - No hit queries in presentation: `intersect_shape` under `game/client/`
   - No sim imports in UI: `sim/` or `PlayerEntity` under `game/client/ui/`
   - No built-in replication nodes: `MultiplayerSynchronizer` / `MultiplayerSpawner`
5. Dedicated server smoke when you touched boot/server/net:
   `godot --headless --path game -- --server`
   Expect JSON logs including channel ready. Interrupt after it is up if it does not exit on its own.
6. Cursor layout only if you edited `.cursor/` or `AGENTS.md`: `npm run verify`

Compile/export success alone is not enough.

## Verify

- Headless boot exits 0
- GUT exits 0 with no skipped tests you introduced
- Greps are clean
- Data check passes if data or schemas changed

## Failure modes

- Passing the editor play button but skipping headless → CI will fail
- Deleting or pending a test to go green → forbidden
- Forgetting JSON `include_filter` on export presets → exported server has no data
