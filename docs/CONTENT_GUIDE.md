# Content guide

Stub. Full recipes ship in Phase 13.

Until then:

1. Add or edit JSON under `game/data/` with `"schema_version": 1` and `snake_case` ids.
2. Run `python3 tools/build_index.py` so `game/data/index.json` lists every file.
3. Run `python3 tools/validate_data.py`.
4. Maps: one `.tscn` in `game/content/maps/` plus a JSON entry. Do not discover files with `DirAccess`.
5. Original names only. Prefixes: `wpn_`, `pot_`, `etc_`, `q_`, `npc_`, `dt_`, `shop_`.
6. Credit third-party assets in `docs/ASSET_CREDITS.md`.
