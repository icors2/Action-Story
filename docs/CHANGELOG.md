# Changelog

## Phase 1 — Movement (2026-10-24)

Walk, jump, one-way drop-through, ropes/ladders, LOCAL prediction.

- Default map: `map_test_movement` (D-020). Green solid tiles, amber one-way platforms, rope + ladder.
- `MovementMotor` + `ClimbQuery` + jitter `InputQueue`. Tunables in `data/stats.json` (D-021).
- Client: `Keybinds`, `InputSampler`, predicted `PlayerEntity`, `PlayerView`, `FollowCamera`, F3 overlay.
- LOCAL reconcile via `Predictor`. Corrections > 1 px are counted on the overlay (expect ~0).
- GUT: 30 tests (input queue/edges, motor determinism, jump height, drop-through, climb, WorldSim land).

### Play-test script (M1 movement)

1. Import once if needed: `godot --headless --import --path game`
2. Play: `godot --path game` (Windows: `& "C:\path\to\Godot_v4.7.2-stable_win64.exe" --path game`)
3. Expect: `entered_map map_test_movement eid=1`, blue rectangle with a yellow nose, F3 overlay.
4. **Arrows or WASD** — run. **Space or Alt** — jump (~3.5 tiles).
5. Land on an amber platform from below. **Down + Jump** drops through. Solid green ground does not drop through.
6. Stand under the rope or ladder, **Up** to grab, **Up/Down** to climb, **Jump + Left/Right** to hop off. Climb off the top onto the platform.
7. Overlay `corrections>1px` should stay 0 while walking/jumping in LOCAL.
8. F3 hides the overlay.

Stop here. Next: Phase 2 combat.

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
