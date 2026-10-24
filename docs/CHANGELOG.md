# Changelog

## Phase 2 — Combat & mobs (2026-10-24)

Basic attack, respawning mobs, contact damage, death/respawn. No loot or EXP yet.

- `DamageFormula` + `HitQuery` + `CombatResolver` (sim-only). `novice_strike` via Ctrl or J.
- `StatsComponent` / `HealthComponent` / `Hurtbox`. Novice `base_weapon_attack` 80 in `stats.json` (D-022).
- `MobEntity` + `MobBrain`: Puddlet (patrol, aggro on hit) and Capshroom (aggro on sight, jumps).
- Spawners on `map_test_movement`: 2 Puddlets on the ground, 1 Capshroom on the mid platform. Respawn from data (`respawn_s`).
- Client: interpolated `MobView`, damage numbers, 3 s HP bars, hit flash, cosmetic attack, Respawn prompt.
- Player death → 50% HP at the map spawn. EXP penalty is Phase 3.
- GUT: 49 tests (formula, health, cast timing, hit query, spawner, snapshot size).

### Play-test script (M2 combat)

1. Checkout `cursor/phase-2-combat-ca25` (or re-download the ZIP). Import once: `godot --headless --import --path game`
2. Play: `godot --path game` (Windows: `& "C:\path\to\Godot_v4.7.2-stable_win64.exe" --path game`)
3. Expect: `spawned 3 mobs on map_test_movement`, `entered_map map_test_movement eid=1`. Two blue Puddlets on the floor, one red Capshroom on a middle platform.
4. Walk up to a Puddlet. **Ctrl or J** (or gamepad X) swings. You stop on the ground to attack. Numbers float up; a red HP bar appears for 3 s. Puddlet flinches and chases. About **3–5 hits** should kill it.
5. Dead mobs vanish after a short pause and come back after ~8–10 s.
6. Touch a mob: knockback, blink invincibility (~1.2 s), F3 HP drops. Repeat until you die. **Respawn** button or **R** — you return at the left spawn with half HP.
7. Capshroom should notice you and hop if you are above it.
8. Overlay `corrections>1px` should stay ~0 while walking in LOCAL.

Stop here. Next: Phase 3 RPG systems (EXP, levels, AP/SP). Do not expect loot yet.

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
6. **Brown rope** (left platforms) and **yellow ladder** (right platforms) should be visible. Stand on one, **Up** to grab, **Up/Down** to climb, **Jump + Left/Right** to hop off.
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
