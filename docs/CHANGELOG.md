# Changelog

## Phase 0 — M0 Skeleton (2026-10-17)

Architecture exists end to end with no gameplay.

- Godot **4.7.2-stable** project in `game/`. GUT **9.7.1** vendored.
- Autoloads: Log, Config, EventBus, DataRegistry, Net, GameState, AudioManager, SceneRouter.
- `LocalAuthority` + `WorldSim` + `MapInstance` load `map_test_flat` and assign eid 1.
- Headless dedicated server hosts ENet and logs JSON `Channel 1 ready`.
- Data: `stats.json`, `level_table.json`, `novice_strike`, `puddlet`, `map_test_flat` + schemas + `tools/build_index.py` / `validate_data.py`.
- GUT: 20 tests (config, ids, rate limiter, ring buffer, registry, codec).
- CI: data + godot jobs (`.github/workflows/ci.yml`). Export presets include JSON `include_filter`.
- Cursor bootstrap: working memory, Skyrope skills/rules, Context7 + GitHub MCP.

### Play-test script (M0)

1. `make test` — 20 GUT tests pass.
2. `make run` — 640×360 window, grey floor. Log: `entered_map map_test_flat eid=1`.
3. `make server` — JSON log includes `"Channel 1 ready"`. Ctrl+C / window-close exits.
4. Optional: `make export` after installing Godot 4.7.2 export templates; run the Linux server binary and confirm it loads data.

Headless smoke already verified:

```
godot --headless --path game --quit-after 120
# [INFO] client: entered_map map_test_flat eid=1

godot --headless --path game --quit-after 180 -- --server --port=7799
# {"msg":"Channel 1 ready", ...}
```

Stop here for play-test. Next: Phase 1 movement.
