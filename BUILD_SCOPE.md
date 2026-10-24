# BUILD_SCOPE.md — "Project Skyrope"
### A 2D side-scrolling action MMORPG built in Godot 4 (GDScript), server-authoritative from day one

> **Codename:** Project Skyrope (placeholder, rename anytime: search and replace `skyrope`).
> **Owner:** Chris O'Neal
> **Target engine:** Godot **4.3 or newer** (pin one exact 4.x stable version at Phase 0 and record it in `docs/DECISIONS.md`. Never upgrade mid-phase.)
> **Language:** Typed GDScript (game client + dedicated server). Python 3.12 (FastAPI) for the account/backend service and tooling.
> **Hosting:** Docker Compose on a Linux homelab, tested over Tailscale. Later: a VPS.
> **Document status:** Living document. Cursor updates the checkboxes. Humans make the architecture changes, and they go through the Decision Log (§14).

---

## Table of Contents

0. [How to use this document with Cursor](#0-how-to-use-this-document-with-cursor)
1. [Master Progress Checklist](#1-master-progress-checklist)
2. [Project Overview](#2-project-overview)
3. [Tech Stack Decisions](#3-tech-stack-decisions)
4. [Networking Model](#4-networking-model)
5. [Repository Structure](#5-repository-structure)
6. [Architecture](#6-architecture)
7. [Data-Driven Content & Schemas](#7-data-driven-content--schemas)
8. [Coding Standards & Conventions](#8-coding-standards--conventions)
9. [Boilerplate (Starter Code)](#9-boilerplate-starter-code)
10. [Phased Roadmap (Phase 0 → 17)](#10-phased-roadmap-phase-0--17)
11. [Milestones](#11-milestones)
12. [Testing Strategy](#12-testing-strategy)
13. [Art & Audio Pipeline](#13-art--audio-pipeline)
14. [Risks, Decision Log, Glossary](#14-risks-decision-log-glossary)
15. [Appendices (protocol table, collision layers, input map, ports)](#15-appendices)

---

## 0. How to use this document with Cursor

Put this file at the root of an empty git repository and open the repo in Cursor. Then paste this kickoff message to the agent:

```text
Read BUILD_SCOPE.md completely before writing any code. It is the source of truth for
architecture, folder layout, conventions and the phased roadmap.

Work on exactly ONE phase at a time, starting with the first phase whose checklist is not
complete. Within that phase, do the tasks in order. After each task:
  1. Run the project headless and the GUT test suite (commands in §12).
  2. Fix every error and warning you introduced.
  3. Tick the task's checkbox in BUILD_SCOPE.md ("- [ ]" -> "- [x]").
  4. Make one git commit using the convention in §8.6.
Do NOT start the next phase until every acceptance criterion of the current phase passes.
At the end of the phase, update §1 (Master Progress Checklist), write a short summary in
docs/CHANGELOG.md, and stop so I can play-test.
If a task conflicts with the architecture in §3–§7, STOP and ask. Do not improvise a
different architecture. Add proposed changes to docs/DECISIONS.md as "Proposed".
```

### 0.1 Rules for the coding agent (non-negotiable)

1. **One phase at a time.** Never implement features from a later phase "because it's easy now". The architecture already leaves room for them.
2. **The Authority pattern is law.** Gameplay state (HP, EXP, inventory, currency, positions of record, loot, quest state) is changed **only** inside the simulation (`game/sim/`), and only in response to an *intent*. Presentation code (`game/client/`) never mutates game state. See §6.4.
3. **Data, not code.** Stats, skills, mobs, items, drop tables, quests, NPCs, shops and maps are JSON in `game/data/`. If you're about to hard-code a number that a designer would want to tweak, put it in data.
4. **Typed GDScript everywhere.** Every variable, parameter and return value gets a type. `untyped_declaration` warnings are treated as errors (see §9.1).
5. **No god scripts.** Hard limit of 400 lines per `.gd` file (aim for under 250). One responsibility per script.
6. **Tests accompany logic.** Every pure-logic function in `game/sim/` and `game/shared/` gets GUT tests in the same task.
7. **Keep it runnable.** After every task, `godot --headless --path game --quit-after 120` must exit without script errors, and the test suite must pass.
8. **Don't add dependencies** (addons, pip packages, Docker images) beyond those listed in §3 without adding a Decision Log entry.
9. **No copyrighted assets or names** from MapleStory/Nexon or any other game (see §2.6).
10. **Update this document**: tick checkboxes, and append any discovered pitfalls to the phase's *Pitfalls* list.

### 0.2 How a human (Chris) uses it
- Read §2–§7 once. Those sections lock in the decisions.
- After each phase, play-test using the phase's *Acceptance Criteria* and either approve it or file fixes.
- Big changes go into `docs/DECISIONS.md` first, then get reflected here.

---

## 1. Master Progress Checklist

Tick a phase only when **all** of its acceptance criteria pass.

| # | Phase | Milestone | Status |
|---|-------|-----------|--------|
| 0 | Project setup, tooling, CI, skeleton architecture | — | - [x] |
| 1 | Core movement & physics (one-way platforms, ropes, ladders) | — | - [x] |
| 2 | Combat & mobs | — | - [ ] |
| 3 | RPG systems (stats, leveling, AP/SP, classes, skills) | — | - [ ] |
| 4 | Items, inventory, equipment, drops, currency | — | - [ ] |
| 5 | Maps, portals, tilemaps, parallax, camera | — | - [ ] |
| 6 | UI / HUD | **M1 Vertical Slice** | - [ ] |
| 7 | NPCs, dialogue, quests, shops | — | - [ ] |
| 8 | Save & local persistence | **M2 Single-player Complete** | - [ ] |
| 9 | Networking foundation (dedicated server, connect, spawn, movement sync) | — | - [ ] |
| 10 | Networked combat, mobs, loot, EXP | **M3 Multiplayer Prototype** | - [ ] |
| 11 | Accounts, login, character select/create, DB persistence | — | - [ ] |
| 12 | Social: chat, parties, friends, trading | **M4 Online Feature-Complete Core** | - [ ] |
| 13 | Content pipeline & tools | — | - [ ] |
| 14 | Audio, VFX, polish | — | - [ ] |
| 15 | Security, anti-cheat, load testing | — | - [ ] |
| 16 | Deployment (homelab Docker, monitoring, backups), closed alpha | **M5 Closed Alpha** | - [ ] |
| 17 | Post-launch / later features | **M6 Open Beta and beyond** | - [ ] |

---

## 2. Project Overview

### 2.1 Elevator pitch
A cozy-but-grindy 2D side-scrolling action MMORPG. You run, jump, climb ropes, and fight waves of cute monsters across layered platform maps. You level up, pick a class path, gear up from drops, take on quests from NPCs, and party up with friends. It's inspired by classic 2000s Korean side-scroller MMOs, with original art, names and world.

### 2.2 Design pillars
1. **Tactile platforming.** Movement must feel snappy and predictable: fixed jump arcs, ropes and ladders, drop-through platforms. Network lag must never make movement feel bad, which is why client-side prediction is mandatory.
2. **Satisfying, readable combat.** Big damage numbers, hit-stop, knockback, mobs that explode into loot.
3. **Visible progression.** Every session yields levels, gear, or quest progress. Data-driven tuning makes balancing fast.
4. **Social by default.** Seeing other players on the map, parties sharing EXP, chat. The world feels alive.
5. **Small-team sustainable.** Everything is data-driven, testable, and deployable with one `docker compose up`.

### 2.3 Scope: MVP (through Milestone M5 Closed Alpha)
- 1 starting class ("Novice") plus 4 first-job classes: **Vanguard** (STR melee), **Arcanist** (INT magic), **Ranger** (DEX ranged), **Shade** (LUK thief).
- 3–4 skills per first-job class, levels 1–30.
- 1 starter town, 6–8 hunting maps, 1 dungeon map, 10–12 mob types, 1 mini-boss.
- ~80 items: weapons per class, hat/top/bottom/shoes/gloves, potions, etc-items (quest drops).
- 15–20 quests (kill, collect, talk, deliver), 3 shops.
- Online: accounts, up to 3 characters per account, 1 world with 1–2 channels, map chat, whisper, parties (up to 6), friends list, player-to-player trading.
- Persistence in PostgreSQL. Hosted on the homelab and tested with friends over Tailscale.

### 2.4 Later (post-alpha, Phase 17+)
Guilds, boss raids, party quests (PQs), second-job advancement, crafting, a player marketplace, pets, cosmetic-only shop, mounts, more worlds and channels, mobile/controller polish, a VPS deployment, Steam build.

### 2.5 Non-goals (explicitly out of scope)
- Browser/web client (ENet doesn't run in browsers; see §3). We might revisit it via a WebSocket transport later, and the transport is abstracted to make that possible.
- Pay-to-win or real-money mechanics of any kind.
- Procedural world generation.
- 3D, isometric views, or free-roam open-world maps.
- Massive scale (1000+ concurrent players). The target is **≤ 100 CCU per channel** and **≤ 300 CCU total** on homelab hardware.
- Custom game engine work or C++ modules. If GDScript is too slow somewhere, profile it first. GDExtension is a last resort that needs a Decision Log entry.
- Hand-rolled cryptography. We use TLS (DTLS optional) and standard libraries (argon2, JWT/HMAC).

### 2.6 Legal note
- **Do not use any MapleStory/Nexon assets, sprites, sounds, music, maps, names, item names, mob names, skill names, UI layouts copied pixel-for-pixel, or logos.** That includes private-server asset dumps (WZ files). Nexon actively enforces its IP.
- Use only placeholder art you generate (colored shapes) or assets whose license explicitly permits commercial use and modification (CC0, or a paid license that allows it). Record every third-party asset in `docs/ASSET_CREDITS.md` with its source URL, license and author.
- Original names only: classes (Vanguard/Arcanist/Ranger/Shade), currency (**Glimmer**), towns (e.g. "Bramblewick"), mobs ("Puddlet", "Capshroom", "Gearbug"...).
- Game mechanics and genre conventions (ropes, AP/SP, party quests) are not copyrightable. Specific expression is, so make everything visibly original.
- Open-source private-server projects may be read **for architecture ideas only**. Never copy their code, data tables or assets.

---

## 3. Tech Stack Decisions

| Concern | Decision | Rationale |
|---|---|---|
| Engine | **Godot 4.3+**, one pinned 4.x stable version (`GODOT_VERSION` in `.godot-version`) | Free and MIT licensed. Excellent 2D (TileMapLayer, one-way collision, CharacterBody2D). Built-in high-level multiplayer and ENet. Headless mode for servers. |
| Language | **Typed GDScript** | Fast iteration, first-class editor support, and the same language on client and server. Typing catches errors and improves performance. |
| Server | **Headless Godot dedicated server from the same project** (`--server` user arg or the `dedicated_server` feature tag) | Shares 100% of the simulation code (movement physics, combat, data) with the client, which is what makes client prediction match the server. One codebase means no drift. |
| Single-player / offline | **In-process "local server"** (LocalAuthority runs the same `WorldSim` the server runs) | Phases 1–8 exercise the exact authority code that later runs on the server, so there's no rewrite in Phase 9. |
| Game transport | **ENet (UDP) via `ENetMultiplayerPeer` + Godot `@rpc`**, with custom snapshot/input packing in `PackedByteArray` | UDP with reliable and unreliable channels is ideal for action games. It's built in and battle-tested. WebSocket is TCP (head-of-line blocking hurts movement) and is only needed for browsers, which is a non-goal. |
| Replication | **Custom snapshot + input system** (NOT `MultiplayerSynchronizer`/`MultiplayerSpawner`) | We need client prediction + reconciliation, per-map interest management, multiple maps per server process, and compact bit-packed snapshots. The built-in nodes don't give that control. |
| Account/backend service | **Small custom service: Python 3.12 + FastAPI + SQLAlchemy 2 + Alembic + asyncpg** | Characters, inventories and items are relational and owned by us, so one Postgres schema is the single source of truth. Nakama would duplicate concerns (its social/party/chat features would need to be server-authoritative inside our Godot server anyway, e.g. trading), adds a runtime in Go/Lua/TS, and splits character data between two systems. Chris already knows Python, and the service is small (auth, characters, tickets, persistence API). |
| Database | **PostgreSQL 16+** | Relational, transactional (trades and item moves need ACID), JSONB for flexible blobs (quest state, keybinds). |
| Cache / pub-sub | **Redis: optional, deferred to Phase 12+** (cross-channel whispers/friends presence), Decision Log entry required | YAGNI until there are multiple channel processes. Before then, the backend plus Postgres handles presence. |
| Content format | **JSON files + JSON Schema** in `game/data/`, loaded into typed definition classes by `DataRegistry` | Diffable in git, editable by Cursor/Python tools, validated in CI, readable by the backend if needed. Godot `.tres` resources are harder to diff, validate and share outside Godot. |
| Maps | **Godot scenes using `TileMapLayer`** nodes, plus marker nodes (spawns, portals, ropes). Map metadata lives in JSON. | Native editor and collision. TileMapLayer replaces the deprecated TileMap in 4.3+. Tiled is optional (Phase 13 importer) but not the source of truth. |
| Tests | **GUT 9.x** (the Godot 4 line; use the release matching the pinned Godot minor version) + pytest (backend) | GUT is the de-facto Godot unit test framework, with a CLI runner for CI. |
| CI | **GitHub Actions**: data validation, headless GUT run, client/server exports, backend pytest, Docker build | Catches broken exports and data early. |
| Deployment | **Docker Compose** on the homelab: `postgres`, `backend`, `gameserver-ch1` (+ `ch2`), `db-backup`. Tailscale for private testing. | One-command deploy. Same images later on a VPS. |
| Pixel art | Aseprite (or LibreSprite), exported to PNG sprite sheets + JSON | Industry standard for pixel art. See §13. |
| Audio | `.ogg` (music), `.wav` (short SFX); Godot audio buses | See §13. |

### 3.1 Version pinning
- `.godot-version` at the repo root contains, for example, `4.4.1-stable` (whatever is current at Phase 0). CI and the Dockerfile read it.
- GUT is vendored into `game/addons/gut/` (committed), version recorded in `docs/DECISIONS.md`.
- The backend pins dependencies in `backend/pyproject.toml` with a lock file (`uv.lock` or `requirements.lock`).
- **Upgrade policy:** Godot minor upgrades only between milestones, on a branch, with the full test suite plus a play-test.

---

## 4. Networking Model

### 4.1 Topology
```
 ┌──────────────┐  HTTPS (REST, JWT)   ┌──────────────────┐     SQL      ┌────────────┐
 │ Godot Client │ ───────────────────▶ │ backend (FastAPI)│ ───────────▶ │ PostgreSQL │
 │              │                      └──────────────────┘              └────────────┘
 │              │  ENet/UDP (game)              ▲  internal REST (service token)
 │              │ ───────────────────▶ ┌────────┴─────────┐
 └──────────────┘                      │ gameserver-chN   │  headless Godot, one process
                                       │ (WorldSim, maps) │  per channel, all maps of the world
                                       └──────────────────┘
```
- **Login flow:** client → `POST /auth/login` → access JWT → `GET /characters` → `POST /characters/{id}/join` → backend returns `{host, port, join_ticket}` (single-use, 30s TTL, HMAC-signed, bound to account_id + character_id + channel). Client connects over ENet and sends `c2s_hello(protocol_version, join_ticket)`. The server verifies the ticket's HMAC locally and redeems it with the backend (`POST /internal/tickets/redeem`, which enforces single use and one active session per account), then loads the character via `GET /internal/characters/{id}` and spawns the player.
- **Persistence flow:** the game server is the only writer of live character state. It autosaves dirty characters every 60s, on map change, on logout/disconnect, and immediately on critical transactions (trade completion, NPC purchase over a threshold), using `PUT /internal/characters/{id}` with an incrementing `save_version` (optimistic concurrency).

### 4.2 Rates and timing (constants live in `game/shared/net/net_config.gd`)
| Constant | Value | Notes |
|---|---|---|
| Physics tick (client & server) | **60 Hz** (`physics/common/physics_ticks_per_second=60`) | Same fixed step on both sides, required for prediction to match. |
| Simulation tick | **60 Hz**, one sim tick per physics frame | `tick` is a monotonically increasing int. |
| Client input send | **every tick (60 Hz)**, each packet carries the last **3** input frames (redundancy vs. loss) | Inputs are tiny (~6 bytes per frame). |
| Server snapshot send | **20 Hz** (every 3rd tick) | Per map, only to peers on that map (interest management). |
| Interpolation delay | **100 ms** (2 snapshots), adaptive 66–200 ms based on jitter | Remote players and mobs render in the past. |
| Max snapshot payload | Target < 1,000 bytes | Below the MTU, so no fragmentation. Quantize positions to 0.5 px (int16 relative to the map origin). |
| Server input buffer | 2–4 ticks per player | Absorbs jitter. If an input is missing, repeat the last input (max 6 ticks), then use neutral input. |
| Timeout | 10 s without packets → disconnect | ENet peer timeout configured explicitly. |

### 4.3 Client-side prediction & reconciliation (local player movement)
1. Each tick the client samples input into an `InputFrame {seq, tick, move_x, move_y, buttons}`, applies it locally through the **shared `MovementMotor`** (the same code the server runs), stores it in a ring buffer of pending frames, and sends it.
2. The server applies frames in `seq` order, simulates, and includes `last_processed_seq` and the authoritative motor state (`pos`, `vel`, `motor_state`, `facing`, `on_floor`, `climb_id`) for that player in that player's snapshot.
3. On receiving a snapshot, the client drops pending frames with `seq <= last_processed_seq`, sets its body to the server state, and **re-simulates** the remaining pending frames in the same physics frame.
4. If the corrected position differs from the displayed position by < 24 px, the **visual** node (Sprite) is smoothed toward the body over ~100 ms. If it differs by more, it snaps (teleport/knockback).
5. **Why re-sim is safe here:** players collide only with **static** terrain (no player-player or player-mob physical collision, which matches the genre). Static terrain is identical on client and server. Ropes/ladders are detected via **direct space queries** (`PhysicsDirectSpaceState2D.intersect_point/intersect_shape`), not Area2D signals, because signals only update once per physics frame and would break re-simulation.

### 4.4 Interpolation (everything that isn't the local player)
- Remote players, mobs, drops and projectiles are rendered from a snapshot buffer at `render_time = server_time_estimate - interp_delay`, lerping between the two surrounding snapshots. If the buffer runs dry, extrapolate for at most 100 ms and then freeze.
- The client estimates server time with a simple clock sync: a `c2s_ping(client_time)` / `s2c_pong(client_time, server_tick)` RTT exchange every 2 s, smoothed with an EMA.

### 4.5 Server authority (what the client can and cannot do)
| Client MAY | Client MAY NOT |
|---|---|
| Send movement input frames | Send positions |
| Send intents: `attack(skill_id, facing)`, `pickup(drop_id)`, `use_item(slot)`, `equip(slot)`, `talk(npc_id)`, `chat(...)`, `trade_*`... | Report damage, hits, EXP, loot, quest completion, currency changes |
| Play attack animations and SFX immediately (cosmetic) | Decide whether an attack hit |
| Predict its own movement | Predict HP/MP or inventory changes (the UI waits for server results; typical latency on Tailscale is under 50 ms) |

- **Combat:** the server validates skill ownership, cooldown, MP, state (not dead or stunned) and rate. It resolves hits with **shape queries** at the attacker's server position + facing against mob hurtboxes, rolls damage with the server RNG, applies knockback, and emits `DamageEvent`s. Light **lag compensation** (rewinding mob positions by the client's interpolation delay, max 200 ms) is optional in Phase 15.
- **Loot:** drops are server entities with an owner/party claim window (3 s for the killer's party, then free-for-all), and an expiry (60 s). Pickup is validated by distance (≤ 48 px) and inventory space.
- **EXP:** awarded by the server proportional to damage dealt, with a party share bonus.

### 4.6 Anti-cheat basics (built in from Phase 9; hardened in Phase 15)
- Never trust the client (see the table above). All formulas and RNG live on the server.
- Movement: the server simulates from inputs, so speed hacks can't move a player faster. Input rate limiting: frames whose `tick` runs ahead of the expected rate are dropped, and repeated violations lead to a kick.
- Per-peer token-bucket rate limits on every RPC (e.g. chat 5/5 s, intents 30/s).
- Validate every RPC argument: types, ranges, string lengths, IDs that exist and are near the player.
- Item duplication defense: every item instance has a server-generated unique `uid`. All item moves are transactional (DB transaction on trade commit). Save versions are checked.
- Protocol version handshake: mismatched clients are rejected with a clear message.
- Audit log table for trades, drops of rare items, and admin commands.

### 4.7 Transport abstraction
All network I/O goes through the `Net` autoload (`game/shared/net/net.gd`). Gameplay code depends on the `Authority` interface (§6.4), never on `multiplayer` directly. Swapping ENet for `WebSocketMultiplayerPeer` later only touches `Net`.

---

## 5. Repository Structure

**Decision:** a **monorepo** with **one Godot project** (`game/`) that builds both the client and the dedicated server through export presets and feature tags, plus a separate `backend/` Python service. The Godot project lives in a subfolder so Godot doesn't try to import backend/tooling files.

Why one Godot project and not separate client/server projects: prediction requires *identical* simulation code. RPC paths and checksums must match on both sides (Godot validates that the RPC configuration of a node matches between peers). Data files are shared. Two projects would mean copying code and guaranteed drift. Client-only code (UI, VFX, audio) is isolated in `game/client/` and stripped or never loaded on the server.

```
skyrope/
├── BUILD_SCOPE.md                 # this file
├── README.md                      # quick start
├── .godot-version                 # e.g. 4.4.1-stable (single source of truth for CI/Docker)
├── .gitignore
├── .gitattributes                 # LFS for *.aseprite, *.psd, *.wav, large *.ogg
├── .editorconfig
├── Makefile                       # make test, make server, make client, make export, make up
├── docs/
│   ├── DECISIONS.md               # decision log (ADR-lite)
│   ├── CHANGELOG.md
│   ├── ASSET_CREDITS.md
│   ├── PROTOCOL.md                # generated/maintained message list (mirrors §15.1)
│   ├── CONTENT_GUIDE.md           # how to add mobs/items/skills/maps/quests
│   └── RUNBOOK.md                 # ops: deploy, backup, restore, ban, rollback
├── game/                          # ── THE GODOT PROJECT (res:// root) ──
│   ├── project.godot
│   ├── export_presets.cfg         # "Linux Client", "Windows Client", "Linux Server"
│   ├── .gutconfig.json
│   ├── addons/
│   │   └── gut/                   # vendored GUT
│   ├── boot/
│   │   ├── boot.tscn              # main scene: decides client / server / local mode
│   │   └── boot.gd
│   ├── shared/                    # used by client AND server; no UI, no audio
│   │   ├── autoload/              # event_bus.gd, log.gd, config.gd, data_registry.gd
│   │   ├── net/                   # net.gd (autoload), net_config.gd, protocol.gd, codec.gd, input_frame.gd
│   │   ├── authority/             # authority.gd (interface), local_authority.gd, remote_authority.gd
│   │   ├── defs/                  # typed content definitions: item_def.gd, mob_def.gd, skill_def.gd ...
│   │   ├── util/                  # id_allocator.gd, rate_limiter.gd, ring_buffer.gd, math_util.gd
│   │   └── constants.gd           # collision layers, enums
│   ├── sim/                       # ── authoritative simulation (runs in LocalAuthority and server) ──
│   │   ├── world/                 # world_sim.gd, map_instance.gd, map_instance.tscn
│   │   ├── entities/              # entity.gd, player_entity.gd/.tscn, mob_entity.gd/.tscn, drop_entity.gd, projectile_entity.gd, npc_entity.gd
│   │   ├── components/            # stats_component.gd, health_component.gd, hurtbox.gd, cooldowns.gd, buffs.gd, inventory.gd
│   │   ├── movement/              # movement_motor.gd, motor_state.gd, climb_query.gd
│   │   ├── combat/                # damage_formula.gd, combat_resolver.gd, hit_query.gd, knockback.gd
│   │   ├── ai/                    # mob_brain.gd, brain_states/*.gd, spawner.gd
│   │   ├── progression/           # leveling.gd, exp_distributor.gd, class_advancement.gd
│   │   ├── items/                 # item_instance.gd, loot_roller.gd, equipment.gd, shop_service.gd
│   │   ├── quests/                # quest_service.gd, quest_state.gd, dialogue_runner.gd
│   │   ├── social/                # chat_service.gd, party_service.gd, trade_service.gd (Phase 12)
│   │   └── persistence/           # character_record.gd, record_migrations.gd, storage.gd (interface), local_file_storage.gd, backend_storage.gd
│   ├── server/                    # server-only glue (never loaded by the client build)
│   │   ├── server_main.gd/.tscn   # boots WorldSim, opens ENet, tick loop
│   │   ├── session_manager.gd     # peer_id <-> account/character, auth handshake
│   │   ├── snapshot_builder.gd
│   │   ├── backend_client.gd      # HTTPRequest wrapper for internal API
│   │   └── admin_commands.gd
│   ├── client/                    # client-only presentation
│   │   ├── client_main.gd/.tscn   # world view root
│   │   ├── views/                 # player_view.gd/.tscn, mob_view.gd/.tscn, drop_view.gd, npc_view.gd, remote_player_view.gd
│   │   ├── prediction/            # predictor.gd, interpolation_buffer.gd, clock_sync.gd
│   │   ├── input/                 # input_sampler.gd, keybinds.gd
│   │   ├── camera/                # follow_camera.gd
│   │   ├── ui/                    # hud/, windows/ (inventory, stats, skills, quest log, shop, dialogue, chat, party, trade), login/, char_select/
│   │   ├── vfx/                   # damage_number.tscn, hit_spark.tscn, level_up.tscn
│   │   └── audio/                 # audio_manager.gd (autoload), bus_layout.tres
│   ├── content/                   # scenes + art referenced by data
│   │   ├── maps/                  # map_town_bramblewick.tscn, map_field_01.tscn ...
│   │   ├── tilesets/              # *.tres TileSet + PNG atlases
│   │   ├── sprites/               # characters/, mobs/, items/, npcs/, fx/  (PNG sheets + .tres SpriteFrames)
│   │   ├── ui/                    # theme.tres, fonts/, icons/
│   │   └── audio/                 # music/, sfx/
│   ├── data/                      # ── DATA-DRIVEN CONTENT (JSON) ──
│   │   ├── index.json             # manifest of every data file (required for exports)
│   │   ├── classes.json  stats.json  level_table.json
│   │   ├── skills/*.json  mobs/*.json  items/*.json  drop_tables.json
│   │   ├── maps/*.json  quests/*.json  npcs/*.json  shops.json  dialogue/*.json
│   │   └── schemas/*.schema.json  # JSON Schema (draft 2020-12), used by tools/validate_data.py
│   └── tests/
│       ├── unit/                  # test_damage_formula.gd, test_leveling.gd, test_inventory.gd ...
│       ├── integration/           # test_local_authority.gd, test_server_loopback.gd
│       └── helpers/               # factories.gd, fake_storage.gd
├── backend/                       # ── ACCOUNT / PERSISTENCE SERVICE ──
│   ├── pyproject.toml
│   ├── app/
│   │   ├── main.py  config.py  db.py  security.py
│   │   ├── models/                # SQLAlchemy models
│   │   ├── routers/               # auth.py, characters.py, internal.py, health.py
│   │   └── services/              # tickets.py, characters.py
│   ├── migrations/                # Alembic
│   └── tests/
├── tools/
│   ├── validate_data.py           # JSON Schema + cross-reference validation
│   ├── build_index.py             # regenerates game/data/index.json
│   ├── balance_sheet.py           # exports data -> CSV for spreadsheet balancing
│   ├── tiled_import/              # optional Phase 13 Tiled -> .tscn importer
│   ├── bots/                      # headless bot client launcher for load tests
│   └── netsim.sh                  # tc/netem latency & loss simulation
├── docker/
│   ├── gameserver.Dockerfile
│   ├── backend.Dockerfile
│   ├── docker-compose.yml
│   ├── docker-compose.dev.yml
│   └── .env.example
└── .github/workflows/ci.yml
```

---

## 6. Architecture

### 6.1 Layers (dependency direction: top may depend on lower layers only)

```
┌───────────────────────────────────────────────────────────────────┐
│ PRESENTATION  game/client/   views, UI, VFX, audio, camera, input │  client only
├───────────────────────────────────────────────────────────────────┤
│ AUTHORITY     game/shared/authority/  Authority interface          │
│               LocalAuthority (in-process) | RemoteAuthority (net)  │
├───────────────────────────────────────────────────────────────────┤
│ NETWORK       game/shared/net/  Net autoload, protocol, codec      │
│               game/server/     sessions, snapshots, backend client │
├───────────────────────────────────────────────────────────────────┤
│ SIMULATION    game/sim/  WorldSim, MapInstance, entities,          │  runs on server
│               components, movement, combat, AI, items, quests      │  AND in LocalAuthority
├───────────────────────────────────────────────────────────────────┤
│ DATA          game/shared/defs/ + game/data/*.json + DataRegistry  │
└───────────────────────────────────────────────────────────────────┘
```
Hard rules:
- `sim/` **never** references `client/`, UI nodes, `AudioStreamPlayer`, `Camera2D`, `Input`, or the `Net` autoload. It receives intents and input frames as plain objects and emits results as `SimEvent`s.
- `client/` **never** writes to sim entities. It reads state through the Authority (snapshots/events) and sends intents.
- `server/` glues `Net` ↔ `WorldSim`. `LocalAuthority` glues the client ↔ an in-process `WorldSim`.

### 6.2 Runtime modes (decided in `boot/boot.gd`)
| Mode | How it starts | What runs |
|---|---|---|
| `LOCAL` (Phases 1–8, and later "offline practice") | Default when launching the client without `--connect` | Client presentation + `LocalAuthority` hosting an in-process `WorldSim`. No sockets. |
| `SERVER` | `OS.has_feature("dedicated_server")` **or** `--server` in `OS.get_cmdline_user_args()` **or** `DisplayServer.get_name() == "headless"` with `--server` | `server_main.tscn`: WorldSim + Net(ENet host) + SessionManager. No client nodes are instantiated. |
| `CLIENT` (Phase 9+) | `--connect=host:port`, or the login flow | Client presentation + `RemoteAuthority` over ENet. |
| `TEST` | GUT runner | No boot scene. Tests instantiate sims directly. |

### 6.3 Entities, IDs and composition
- **Entity IDs (`eid: int`)**: runtime IDs allocated by `IdAllocator` inside each `WorldSim` (monotonic, starting at 1, never reused during a process lifetime). The same scheme runs in LOCAL and SERVER modes. Clients never allocate eids.
- **Persistent IDs**: `account_id`, `character_id` (bigint from Postgres; in LOCAL mode from the save file), and `item uid` (string, 16-char random base32 generated by the sim and unique forever). Never confuse eids with persistent IDs.
- **Entity kinds:** `PLAYER, MOB, DROP, PROJECTILE, NPC, PORTAL` (enum in `shared/constants.gd`).
- **Composition over inheritance (ECS-lite with nodes):**
  - `Entity` (base script on a `CharacterBody2D` or `Area2D` root) holds `eid`, `kind`, `map_id`, and a `components` lookup.
  - Behavior lives in **component nodes** that are children of the entity: `StatsComponent`, `HealthComponent`, `Hurtbox`, `Cooldowns`, `Buffs`, `Inventory` (players), `MobBrain` (mobs), `MovementMotor` (players/mobs).
  - Components find siblings through `entity.get_component(&"HealthComponent")`, which is cached at `_ready`. Never use long `get_node("../../..")` paths.
  - Max inheritance depth: `Entity → PlayerEntity` / `MobEntity`. No deeper.
- **Sim entities have no sprites.** Each has a matching **View** in `client/views/` (e.g. `MobView`) that the client spawns when it sees the eid in a snapshot or local event, and frees when the eid disappears. In LOCAL mode the views are driven by the same snapshot/event stream (LocalAuthority produces snapshots every tick), so **presentation code is identical in LOCAL and CLIENT modes**.

### 6.4 The Intent → Authority → Result pattern
```
 [Input / UI]                 [Authority]                        [Simulation]
 InputSampler ──InputFrame──▶ Authority.submit_input(frame) ──▶ WorldSim.queue_input(eid, frame)
 Hotkey "Q"  ──Intent──────▶ Authority.submit_intent(intent) ─▶ WorldSim.handle_intent(eid, intent)
                                                                     │ validate → mutate → emit
 Views/HUD  ◀──snapshot────── Authority.snapshot_received   ◀───────┤ SnapshotBuilder
 Views/HUD  ◀──SimEvent────── Authority.event_received      ◀───────┘ DamageEvent, ExpEvent, ItemGained...
```
- **Intent** = a small typed object (`shared/net/protocol.gd`) with `type: int` and `args: Array`. Examples: `Intent.cast(skill_id, facing)`, `Intent.pickup(drop_eid)`, `Intent.equip(inv_tab, slot)`, `Intent.talk(npc_eid)`, `Intent.dialogue_choice(choice_idx)`, `Intent.buy(shop_id, item_id, qty)`.
- **Authority** (abstract) exposes: `submit_input`, `submit_intent`, signals `snapshot_received(snapshot)`, `event_received(event)`, `entered_map(map_id, self_eid)`, `disconnected(reason)`.
- **LocalAuthority** owns a `WorldSim` child, forwards intents directly, and emits snapshots every tick plus events immediately (no serialization except in debug mode, where it round-trips through the codec to catch serialization bugs early. Turn on `Config.local_codec_roundtrip = true` in tests).
- **RemoteAuthority** serializes intents through `Net` and deserializes snapshots/events.
- **Results** are `SimEvent`s: `{type, tick, data: Array}`. The client reacts (damage numbers, inventory refresh) only to events, never by predicting the outcome.

### 6.5 Simulation structure
- `WorldSim` (one per process) owns `MapInstance`s keyed by `map_id` and instantiates maps lazily when the first player enters. Maps unload after 5 minutes empty (server).
- `MapInstance` is a `SubViewport` with its **own `World2D`** (`world_2d = World2D.new()`), so every map has an isolated physics space even though all maps share one server process. Rendering is disabled (`render_target_update_mode = UPDATE_DISABLED`). Inside it: the map scene (TileMapLayers, markers), and the entity container.
- Tick order inside `MapInstance.step(tick)` (fixed, documented, tested):
  1. Apply buffered player input frames → `MovementMotor.step`
  2. Process queued intents (validate → execute)
  3. Mob brains think (every tick for movement, decisions every 6 ticks)
  4. Projectiles move and resolve hits
  5. Combat resolution (queued hit queries) → damage → deaths → EXP → loot rolls
  6. Buffs/cooldowns/regen timers advance
  7. Spawners respawn mobs; drops expire
  8. Emit events; mark dirty for snapshot
- **Determinism:** not lockstep. We need *movement* determinism between client and server (same code, same fixed dt, same static collision), and *reproducible* RNG for tests. All randomness goes through an injected `RandomNumberGenerator` owned by `WorldSim` (seeded from `Config.rng_seed` in tests, randomized in production). Never call the global `randf()` in sim code.

### 6.6 Autoloads (in this order in `project.godot`)
| Autoload | Script | Responsibility | Loaded on |
|---|---|---|---|
| `Log` | `shared/autoload/log.gd` | Leveled logging (`Log.info(tag, msg)`), stdout flush, JSON lines on the server | all |
| `Config` | `shared/autoload/config.gd` | Parses cmdline user args + env vars + `user://settings.cfg`; exposes mode, ports, URLs, seeds | all |
| `EventBus` | `shared/autoload/event_bus.gd` | **Client-side presentation** signals only (UI ↔ UI decoupling). Not used by sim. | all (no-op on server) |
| `DataRegistry` | `shared/autoload/data_registry.gd` | Loads and validates all JSON into typed defs at startup; read-only afterwards | all |
| `Net` | `shared/net/net.gd` | ENet peer, RPC endpoints, packet routing, stats | all (inactive in LOCAL) |
| `GameState` | `client/game_state.gd` | Client-side *view model* of the local player (last known stats, inventory snapshot, settings). Read-only mirror of authority data. | all (empty on server) |
| `AudioManager` | `client/audio/audio_manager.gd` | Music crossfade, SFX pooling | all (no-op on server) |
| `SceneRouter` | `client/scene_router.gd` | Screen transitions (login → char select → world), fade | all (no-op on server) |

> Autoloads exist on both client and server because Godot autoloads are project-wide. Client-only autoloads must early-return in `_ready()` when `Config.is_server()`.

### 6.7 Event bus conventions
- Sim → presentation uses **Authority signals and SimEvents only**.
- `EventBus` signals are past-tense facts named `noun_verbed`: `inventory_window_toggled`, `hotkey_pressed(slot)`, `chat_message_received(msg)`.
- Local node communication uses the node's own signals ("call down, signal up"). Use `EventBus` only for cross-tree UI communication.
- Every `EventBus` signal is declared with typed args in `event_bus.gd` with a one-line comment. No ad-hoc string signals.
- Disconnect signals in `_exit_tree()` when connecting to autoloads from short-lived nodes, or use `CONNECT_ONE_SHOT` as appropriate.

### 6.8 Collision layers (named in `project.godot` → `layer_names/2d_physics/*`)
See §15.2. Summary: 1 `world`, 2 `platform_oneway`, 3 `player_body`, 4 `mob_body`, 5 `player_hurtbox`, 6 `mob_hurtbox`, 7 `climbable`, 8 `portal`, 9 `drop`, 10 `npc`, 11 `projectile`, 12 `mob_wall` (invisible edges mobs can't pass).

---

## 7. Data-Driven Content & Schemas

**Decision:** JSON files in `game/data/` validated by JSON Schema (`game/data/schemas/`) in CI via `tools/validate_data.py`. At runtime, `DataRegistry` parses them into **typed definition classes** (`shared/defs/*.gd`, `RefCounted` with typed fields and `static func from_dict()`).

Why not Godot `.tres` Resources: JSON diffs cleanly in PRs, can be bulk-edited by scripts and Cursor, validated with standard tooling, exported to spreadsheets, and read by the Python backend if it ever needs item definitions. The trade-off (no inspector editing) is acceptable, and a Phase 13 in-editor data browser can be added.

### 7.1 Global data rules
- IDs are `snake_case` strings, globally unique per category, and **never renamed** after Phase 11 (they're stored in the DB). If a rename is needed, add an `aliases` entry.
- Every file has `"schema_version": 1`.
- Numbers: JSON numbers parse as `float` in Godot. Defs must cast them explicitly with `int(d["hp"])`.
- Cross-references (e.g. a drop table referencing an item id) are validated by `validate_data.py` **and** at runtime by `DataRegistry.validate_references()`. A broken reference fails startup in debug builds.
- `index.json` lists every data file. Exported builds can't reliably enumerate `res://` directories, so **never use DirAccess to discover data files**. Run `tools/build_index.py` (CI checks it's up to date).
- Export presets must include `data/*.json` in `include_filter` (non-resource files aren't exported by default!).

### 7.2 Schemas by example

**`classes.json`**
```json
{
  "schema_version": 1,
  "classes": [
    {
      "id": "novice", "name": "Novice", "tier": 0, "parent": null,
      "primary_stat": "str", "secondary_stat": "dex",
      "advance_level": 10, "advance_quest": "q_job_advance_intro",
      "base_hp_per_level": [12, 16], "base_mp_per_level": [6, 8],
      "starting_skills": ["novice_strike"],
      "allowed_weapon_types": ["sword", "club", "wand", "bow", "dagger"]
    },
    {
      "id": "vanguard", "name": "Vanguard", "tier": 1, "parent": "novice",
      "primary_stat": "str", "secondary_stat": "dex",
      "base_hp_per_level": [24, 28], "base_mp_per_level": [4, 6],
      "advance_requirements": { "level": 10, "stats": { "str": 35 } },
      "allowed_weapon_types": ["sword", "club"]
    }
  ]
}
```

**`stats.json`** (global constants for formulas: the only place balance constants live)
```json
{
  "schema_version": 1,
  "ap_per_level": 5, "sp_per_level": 3, "starting_ap": 0,
  "base_stats": { "str": 4, "dex": 4, "int": 4, "luk": 4 },
  "crit_base_rate": 0.05, "crit_multiplier": 1.5,
  "mastery_base": 0.15, "defense_factor": 0.5,
  "level_diff_damage_penalty_per_level": 0.02,
  "hp_regen_interval_s": 10, "mp_regen_interval_s": 10,
  "death_exp_loss_pct": 0.05, "invincibility_after_hit_s": 1.2
}
```

**`level_table.json`**
```json
{ "schema_version": 1, "max_level": 70, "exp_to_next": [15, 34, 57, 92, 135, 372, 560, 840, 1242, 1716] }
```
(`exp_to_next[i]` = EXP needed to go from level i+1 to i+2. Generated by `tools/gen_level_table.py` from a curve, then hand-tuned.)

**`skills/vanguard.json`**
```json
{
  "schema_version": 1,
  "skills": [
    {
      "id": "vanguard_cleave", "name": "Cleave", "class": "vanguard", "type": "active_attack",
      "max_level": 20, "required_skills": {},
      "animation": "attack_swing", "cast_time_s": 0.45, "hit_frame_s": 0.18,
      "hitbox": { "shape": "rect", "offset": [28, -18], "size": [64, 40] },
      "max_targets": 3, "hits": 1,
      "levels": { "mp_cost": [6, 20], "damage_pct": [120, 260], "cooldown_s": [0, 0] },
      "knockback": [60, -40], "sfx": "sfx_cleave", "vfx": "fx_slash_arc"
    },
    {
      "id": "vanguard_war_cry", "name": "War Cry", "class": "vanguard", "type": "buff",
      "max_level": 10, "animation": "cast",
      "levels": { "mp_cost": [10, 25], "duration_s": [30, 120], "cooldown_s": [5, 5] },
      "buff": { "stat": "weapon_attack", "add": [2, 20] }
    }
  ]
}
```
`levels` values are `[at_level_1, at_max_level]`, linearly interpolated (rounded) unless an explicit array of length `max_level` is given.

**`mobs/field_mobs.json`**
```json
{
  "schema_version": 1,
  "mobs": [
    {
      "id": "puddlet", "name": "Puddlet", "level": 2, "hp": 35, "mp": 0,
      "weapon_attack": 8, "defense": 2, "accuracy": 10, "avoid": 2,
      "exp": 6, "move_speed": 40, "jump": false,
      "behavior": "patrol_aggro_on_hit", "aggro_range": 0, "chase_speed": 55,
      "contact_damage": true, "knockback_resist": 0.0,
      "drop_table": "dt_puddlet",
      "scene": "res://content/sprites/mobs/puddlet/puddlet_view.tscn",
      "body_size": [24, 18], "respawn_s": 8
    }
  ]
}
```

**`items/equips.json`** (one item schema with a `category` discriminator)
```json
{
  "schema_version": 1,
  "items": [
    {
      "id": "wpn_rusty_sword", "name": "Rusty Sword", "category": "equip", "slot": "weapon",
      "weapon_type": "sword", "req": { "level": 1, "str": 0, "class": ["novice", "vanguard"] },
      "stats": { "weapon_attack": 17, "attack_speed": 6 },
      "upgrade_slots": 7, "price_buy": 250, "price_sell": 50,
      "icon": "res://content/sprites/items/wpn_rusty_sword.png", "tradeable": true
    },
    {
      "id": "pot_red_small", "name": "Small Red Tonic", "category": "use",
      "effect": { "type": "heal", "hp": 50, "mp": 0 }, "cooldown_s": 0.5,
      "stack_max": 100, "price_buy": 25, "price_sell": 5,
      "icon": "res://content/sprites/items/pot_red_small.png", "tradeable": true
    },
    {
      "id": "etc_puddlet_drop", "name": "Puddlet Bubble", "category": "etc",
      "stack_max": 200, "price_sell": 2,
      "icon": "res://content/sprites/items/etc_puddlet_drop.png", "tradeable": true
    }
  ]
}
```

**`drop_tables.json`**
```json
{
  "schema_version": 1,
  "drop_tables": [
    {
      "id": "dt_puddlet",
      "currency": { "chance": 0.7, "min": 3, "max": 9 },
      "entries": [
        { "item": "etc_puddlet_drop", "chance": 0.55, "min": 1, "max": 1 },
        { "item": "pot_red_small",    "chance": 0.08, "min": 1, "max": 2 },
        { "item": "wpn_rusty_sword",  "chance": 0.005 }
      ],
      "quest_entries": [
        { "item": "etc_puddlet_drop", "chance": 0.6, "quest": "q_bubble_trouble" }
      ]
    }
  ]
}
```
Each entry rolls independently. `quest_entries` only roll for players with the quest active (evaluated per looter).

**`maps/field_01.json`**
```json
{
  "schema_version": 1,
  "id": "field_01", "name": "Sunny Ledges", "region": "bramblewick",
  "scene": "res://content/maps/map_field_01.tscn",
  "music": "bgm_sunny_ledges", "return_map": "town_bramblewick",
  "bounds": [0, 0, 2560, 960], "type": "field",
  "spawns": [
    { "mob": "puddlet", "marker_group": "spawn_a", "max_alive": 12 },
    { "mob": "capshroom", "marker_group": "spawn_b", "max_alive": 6 }
  ],
  "portals": [
    { "id": "west", "to_map": "town_bramblewick", "to_portal": "east" },
    { "id": "east", "to_map": "field_02", "to_portal": "west" }
  ],
  "npcs": [],
  "flags": { "pvp": false, "allow_teleport": true }
}
```
The `.tscn` contains `Marker2D` nodes named after portal ids (in group `portals`) and spawn markers (in groups `spawn_a`, `spawn_b`). JSON references markers by name/group. That keeps geometry in the scene and rules in data.

**`quests/bramblewick.json`**
```json
{
  "schema_version": 1,
  "quests": [
    {
      "id": "q_bubble_trouble", "name": "Bubble Trouble", "giver": "npc_mara", "turn_in": "npc_mara",
      "req": { "level": 3, "quests_completed": [] },
      "objectives": [
        { "type": "collect", "item": "etc_puddlet_drop", "count": 10 },
        { "type": "kill", "mob": "puddlet", "count": 15 }
      ],
      "rewards": { "exp": 120, "currency": 300, "items": [{ "item": "pot_red_small", "qty": 10 }] },
      "dialogue": { "offer": "dlg_mara_offer", "in_progress": "dlg_mara_progress", "complete": "dlg_mara_complete" },
      "repeatable": false
    }
  ]
}
```
Objective types: `kill`, `collect` (consumed on turn-in unless `"keep": true`), `talk`, `reach_map`, `reach_level`, `deliver`.

**`npcs/bramblewick.json`**
```json
{
  "schema_version": 1,
  "npcs": [
    { "id": "npc_mara", "name": "Mara the Herbalist", "map": "town_bramblewick", "marker": "npc_mara",
      "default_dialogue": "dlg_mara_idle", "quests": ["q_bubble_trouble"], "shop": null,
      "sprite": "res://content/sprites/npcs/mara.tres" },
    { "id": "npc_holt", "name": "Holt the Smith", "map": "town_bramblewick", "marker": "npc_holt",
      "default_dialogue": "dlg_holt_idle", "quests": [], "shop": "shop_bramblewick_weapons",
      "sprite": "res://content/sprites/npcs/holt.tres" }
  ]
}
```

**`dialogue/mara.json`** (simple node graph, no scripting language)
```json
{
  "schema_version": 1,
  "dialogues": [
    {
      "id": "dlg_mara_offer",
      "nodes": {
        "start": { "text": "Those bubbly Puddlets are clogging my herb beds!", "next": "ask" },
        "ask":   { "text": "Could you bring me 10 of their bubbles?",
                   "choices": [
                     { "text": "Sure!", "action": { "type": "accept_quest", "quest": "q_bubble_trouble" }, "next": "end" },
                     { "text": "Not now.", "next": "end" } ] },
        "end":   { "end": true }
      }
    }
  ]
}
```
Allowed `action` types (validated by the server): `accept_quest`, `complete_quest`, `open_shop`, `give_item`, `warp`, `job_advance`. The client only sends `dialogue_choice(idx)`. The server runs the dialogue state machine.

**`shops.json`**
```json
{
  "schema_version": 1,
  "shops": [
    { "id": "shop_bramblewick_weapons", "buy_rate": 1.0, "sell_rate": 1.0,
      "stock": [ { "item": "wpn_rusty_sword" }, { "item": "pot_red_small" } ] }
  ]
}
```

### 7.3 JSON Schema example (`game/data/schemas/mobs.schema.json`)
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "mobs.schema.json",
  "type": "object",
  "required": ["schema_version", "mobs"],
  "properties": {
    "schema_version": { "const": 1 },
    "mobs": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": ["id", "name", "level", "hp", "weapon_attack", "defense", "exp", "move_speed", "behavior", "drop_table", "scene", "body_size", "respawn_s"],
        "properties": {
          "id": { "type": "string", "pattern": "^[a-z][a-z0-9_]*$" },
          "name": { "type": "string", "minLength": 1, "maxLength": 32 },
          "level": { "type": "integer", "minimum": 1, "maximum": 200 },
          "hp": { "type": "integer", "minimum": 1 },
          "mp": { "type": "integer", "minimum": 0 },
          "weapon_attack": { "type": "integer", "minimum": 0 },
          "defense": { "type": "integer", "minimum": 0 },
          "accuracy": { "type": "integer", "minimum": 0 },
          "avoid": { "type": "integer", "minimum": 0 },
          "exp": { "type": "integer", "minimum": 0 },
          "move_speed": { "type": "number", "minimum": 0 },
          "chase_speed": { "type": "number", "minimum": 0 },
          "jump": { "type": "boolean" },
          "behavior": { "enum": ["stationary", "patrol", "patrol_aggro_on_hit", "patrol_aggro_on_sight", "flying_patrol", "boss"] },
          "aggro_range": { "type": "number", "minimum": 0 },
          "contact_damage": { "type": "boolean" },
          "knockback_resist": { "type": "number", "minimum": 0, "maximum": 1 },
          "drop_table": { "type": "string" },
          "scene": { "type": "string", "pattern": "^res://" },
          "body_size": { "type": "array", "items": { "type": "number" }, "minItems": 2, "maxItems": 2 },
          "respawn_s": { "type": "number", "minimum": 0 }
        }
      }
    }
  }
}
```

### 7.4 Character record (save format, shared by local saves and the DB)
```json
{
  "record_version": 1,
  "character_id": 0,
  "name": "Chris",
  "class_id": "novice",
  "level": 1, "exp": 0,
  "stats": { "str": 4, "dex": 4, "int": 4, "luk": 4 },
  "ap": 0, "sp": 0,
  "hp": 50, "mp": 5,
  "currency": 0,
  "map_id": "town_bramblewick", "spawn_portal": "spawn",
  "skills": { "novice_strike": 1 },
  "inventory": {
    "equip": [ null, { "uid": "K3J9Q2M8X1Z7P4R6", "item": "wpn_rusty_sword", "qty": 1, "upgrades": 0, "rolled": {} } ],
    "use": [], "etc": []
  },
  "equipped": { "weapon": { "uid": "...", "item": "wpn_rusty_sword", "rolled": {} } },
  "quests": { "q_bubble_trouble": { "state": "active", "progress": { "0": 3, "1": 7 } } },
  "keybinds": { "Q": "skill:vanguard_cleave", "1": "item:pot_red_small" },
  "save_version": 0
}
```
`record_migrations.gd` upgrades older `record_version`s step by step (`v1→v2→v3`). The backend stores the record as normalized tables (§9.20) and serves/accepts the same JSON shape on the internal API, so the sim only ever deals with this one shape.

---

## 8. Coding Standards & Conventions

### 8.1 Naming (follows the official GDScript style guide)
| Thing | Convention | Example |
|---|---|---|
| Files & folders | `snake_case` | `movement_motor.gd`, `player_entity.tscn` |
| `class_name` | `PascalCase` | `class_name MovementMotor` |
| Functions, variables | `snake_case` | `func apply_damage(amount: int) -> void` |
| Private members | leading underscore | `var _pending: Array[InputFrame]` |
| Constants & enum values | `CONSTANT_CASE` | `const TICK_RATE := 60` |
| Signals | past tense `snake_case` | `signal died(eid: int)` |
| Node names in scenes | `PascalCase` | `Hurtbox`, `StatsComponent` |
| Data IDs | `snake_case` with category prefix for items/dialogue/quests | `wpn_`, `pot_`, `etc_`, `dlg_`, `q_`, `npc_`, `dt_`, `shop_` |
| Input actions | `snake_case` verbs | `move_left`, `jump`, `attack`, `skill_1` |
| Groups | `snake_case` plural | `portals`, `spawn_a` |

### 8.2 GDScript rules
- **Static typing everywhere**: `var speed: float = 120.0` or `var speed := 120.0`. Typed arrays: `Array[ItemInstance]`. Typed returns on every function, including `-> void`.
- Order inside a script: `class_name`, `extends`, doc comment `##`, signals, enums, constants, `@export`s, public vars, private vars, `@onready` vars, `_init`, `_ready`, other virtuals, public methods, private methods.
- `##` doc comments on every public class and function in `sim/` and `shared/`.
- No `get_node()` with string paths longer than one level. Use `@onready var x: Foo = $Foo` or `%UniqueName`.
- No `await` inside sim tick code (the sim must be synchronous). `await` is fine in the client UI and the server's backend HTTP calls.
- Use `StringName` (`&"name"`) for frequently compared identifiers (states, component names).
- Use `push_error()` for programmer errors and `Log.warn()` for runtime anomalies. Never silently `pass`.
- Avoid `Dictionary` as a pseudo-struct across module boundaries: create a small `RefCounted` class with typed fields. Dictionaries are OK inside JSON parsing and serialization.
- Keep the engine version's typed-collection features in mind: the doc targets 4.3+, so **don't use typed `Dictionary[K, V]`** (4.4+) unless the pinned version supports it **and** a Decision Log entry approves it.
- Physics-related code runs in `_physics_process` only. Sim timers count ticks (`int`), not `Timer` nodes (Timer nodes don't play well with re-simulation and server tick control).

### 8.3 File and scene limits
- `.gd` ≤ 400 lines (hard), target ≤ 250. Functions ≤ 50 lines.
- Scenes are composed: each reusable piece is its own `.tscn` (e.g. `hurtbox.tscn`, `hp_bar.tscn`). Max scene nesting depth for editing comfort: 4.
- A scene's root script must not reach into its children's internals. It talks through exported references or signals.
- No logic in `.tscn` built-in scripts. Always use external `.gd` files.

### 8.4 Scene composition rules
- Sim scenes (`sim/entities/*.tscn`) contain **only** collision shapes, components and markers. No `Sprite2D`, `AnimationPlayer` with visuals, audio or particles.
- View scenes (`client/views/*.tscn`) contain visuals and have **no collision** except UI picking.
- Map scenes contain TileMapLayers + markers + an optional `ParallaxBackground`/`Parallax2D`. The server instance strips or ignores visual layers (dedicated-server export mode strips textures automatically).

### 8.5 Error handling and logging
- Server logs are JSON lines: `{"ts":..., "lvl":"info", "tag":"session", "msg":"...", "peer":12}`. The client logs plain text.
- Every RPC handler validates its input first and logs plus increments a `violations` counter on bad input.

### 8.6 Git workflow
- Branches: `main` (always green), `phase/NN-short-name` for each phase, `fix/...`, `chore/...`.
- Conventional Commits: `feat(combat): add knockback on hit`, `fix(net): reconcile drops stale frames`, `test(items): inventory stacking edge cases`, `docs(scope): tick phase 2 tasks`, `chore(ci): cache godot binary`.
- One task = one commit (squash small fix-ups). Merge a phase branch to `main` with a PR once acceptance criteria pass and CI is green.
- Tag milestones: `m1-vertical-slice`, `m3-mp-prototype`, etc.
- Never commit `.godot/` (the import cache), `export/`, `build/`, `.env`, or user saves.

### 8.7 How Cursor should work (process)
1. Read the current phase section fully. Re-read §6 before touching sim/net code.
2. For each task: write the code, write or extend the tests, run the tests, run the project headless, fix, tick the box, commit.
3. If something in a later phase would need changes to an earlier design, write it in the phase's *Pitfalls* list and in `docs/DECISIONS.md` as **Proposed**. Do not refactor on your own.
4. At the end of a phase, produce `docs/CHANGELOG.md` notes and a play-test script (what to try, what to expect).
5. Never delete tests to make the suite pass. Never mark a task complete if its tests are skipped or pending.

---

## 9. Boilerplate (Starter Code)

> These are **starting points**, written to be valid Godot 4.3+ GDScript. Cursor should create these files in Phase 0 (or the phase noted), then extend them. They're kept short. Expand the TODOs in the phase where they belong, not earlier. Indentation in real files is **tabs** (Godot default).

### 9.1 `game/project.godot` (key settings)
Create it through the editor, then make sure these keys exist:
```ini
config_version=5

[application]
config/name="Skyrope"
run/main_scene="res://boot/boot.tscn"
config/features=PackedStringArray("4.3")   ; editor rewrites this to the pinned version
run/flush_stdout_on_print=true              ; needed for docker logs / journald
config/use_custom_user_dir=true
config/custom_user_dir_name="skyrope"

[autoload]
Log="*res://shared/autoload/log.gd"
Config="*res://shared/autoload/config.gd"
EventBus="*res://shared/autoload/event_bus.gd"
DataRegistry="*res://shared/autoload/data_registry.gd"
Net="*res://shared/net/net.gd"
GameState="*res://client/game_state.gd"
AudioManager="*res://client/audio/audio_manager.gd"
SceneRouter="*res://client/scene_router.gd"

[debug]
gdscript/warnings/untyped_declaration=2      ; 2 = error
gdscript/warnings/unsafe_property_access=1
gdscript/warnings/unsafe_method_access=1
gdscript/warnings/unsafe_cast=1
gdscript/warnings/unsafe_call_argument=1
gdscript/warnings/return_value_discarded=0

[display]
window/size/viewport_width=640
window/size/viewport_height=360
window/size/window_width_override=1920
window/size/window_height_override=1080
window/stretch/mode="canvas_items"
window/stretch/scale_mode="integer"

[layer_names]
2d_physics/layer_1="world"
2d_physics/layer_2="platform_oneway"
2d_physics/layer_3="player_body"
2d_physics/layer_4="mob_body"
2d_physics/layer_5="player_hurtbox"
2d_physics/layer_6="mob_hurtbox"
2d_physics/layer_7="climbable"
2d_physics/layer_8="portal"
2d_physics/layer_9="drop"
2d_physics/layer_10="npc"
2d_physics/layer_11="projectile"
2d_physics/layer_12="mob_wall"

[physics]
common/physics_ticks_per_second=60
common/max_physics_steps_per_frame=8
common/physics_jitter_fix=0.0               ; fixed-step determinism matters more than smoothing

[rendering]
renderer/rendering_method="gl_compatibility"
textures/canvas_textures/default_texture_filter=0   ; nearest (pixel art)
2d/snap/snap_2d_transforms_to_pixel=true
2d/snap/snap_2d_vertices_to_pixel=true
```
Input actions are registered in code by `client/input/keybinds.gd` (`InputMap.add_action` + default events) so they stay remappable and diffable. See §15.3.

### 9.2 `game/export_presets.cfg` (essentials only; create the presets in the editor)
```ini
[preset.0]
name="Linux Client"
platform="Linux"
runnable=true
export_filter="all_resources"
include_filter="data/*.json, data/**/*.json"
exclude_filter="tests/*, addons/gut/*, server/*"
export_path="../build/client/linux/skyrope.x86_64"

[preset.1]
name="Windows Client"
platform="Windows Desktop"
runnable=true
export_filter="all_resources"
include_filter="data/*.json, data/**/*.json"
exclude_filter="tests/*, addons/gut/*, server/*"
export_path="../build/client/windows/skyrope.exe"

[preset.2]
name="Linux Server"
platform="Linux"
runnable=false
dedicated_server=true                        ; "Export as dedicated server": strips visuals, adds feature tag
export_filter="all_resources"
include_filter="data/*.json, data/**/*.json"
exclude_filter="tests/*, addons/gut/*, client/ui/*"
export_path="../build/server/skyrope_server.x86_64"
```
> ⚠️ The client presets exclude `server/*`. That means **no client-reachable script may `preload()` anything in `server/`**. The server preset can't exclude `client/` entirely, because the RPC-bearing `Net` autoload and the shared map scenes must exist on both sides. Only exclude UI folders.

### 9.3 `.gitignore` and `.gitattributes`
```gitignore
# Godot
game/.godot/
game/.import/
*.translation
export.cfg
export_credentials.cfg
# Builds
build/
*.pck
*.x86_64
*.exe
# Python
__pycache__/
.venv/
*.pyc
.pytest_cache/
# Secrets & local data
.env
docker/.env
backups/
*.log
# OS / editors
.DS_Store
.vscode/
.idea/
```
```gitattributes
*.aseprite filter=lfs diff=lfs merge=lfs -text
*.psd      filter=lfs diff=lfs merge=lfs -text
*.wav      filter=lfs diff=lfs merge=lfs -text
*.ogg      filter=lfs diff=lfs merge=lfs -text
*.gd       text eol=lf
*.tscn     text eol=lf
*.tres     text eol=lf
*.json     text eol=lf
```

### 9.4 `game/boot/boot.gd`
```gdscript
extends Node
## Entry scene. Picks the runtime mode and hands off to the right root scene.

const SERVER_SCENE := "res://server/server_main.tscn"
const CLIENT_SCENE := "res://client/client_main.tscn"
const LOGIN_SCENE := "res://client/ui/login/login_screen.tscn"


func _ready() -> void:
	Log.info("boot", "Skyrope starting mode=%s godot=%s" % [Config.mode_name(), Engine.get_version_info()["string"]])
	if not DataRegistry.is_loaded():
		Log.error("boot", "Data failed to load; aborting")
		get_tree().quit(1)
		return
	match Config.mode:
		Config.Mode.SERVER:
			_switch_to.call_deferred(SERVER_SCENE)
		Config.Mode.CLIENT:
			_switch_to.call_deferred(LOGIN_SCENE)   # Phase 11; before that: CLIENT_SCENE
		_:
			_switch_to.call_deferred(CLIENT_SCENE)  # LOCAL mode


func _switch_to(path: String) -> void:
	var err: Error = get_tree().change_scene_to_file(path)
	if err != OK:
		Log.error("boot", "Failed to load %s (%s)" % [path, error_string(err)])
		get_tree().quit(1)
```

### 9.5 `game/shared/autoload/log.gd`
```gdscript
extends Node
## Leveled logger. JSON lines on the server, readable text on the client.

enum Level { DEBUG, INFO, WARN, ERROR }

var min_level: Level = Level.INFO
var json_lines: bool = false


func debug(tag: String, msg: String, fields: Dictionary = {}) -> void:
	_emit(Level.DEBUG, tag, msg, fields)


func info(tag: String, msg: String, fields: Dictionary = {}) -> void:
	_emit(Level.INFO, tag, msg, fields)


func warn(tag: String, msg: String, fields: Dictionary = {}) -> void:
	_emit(Level.WARN, tag, msg, fields)


func error(tag: String, msg: String, fields: Dictionary = {}) -> void:
	_emit(Level.ERROR, tag, msg, fields)


func _emit(level: Level, tag: String, msg: String, fields: Dictionary) -> void:
	if level < min_level:
		return
	var lvl_name: String = String(Level.keys()[level]).to_lower()
	if json_lines:
		var rec: Dictionary = {"ts": Time.get_unix_time_from_system(), "lvl": lvl_name, "tag": tag, "msg": msg}
		rec.merge(fields)
		print(JSON.stringify(rec))
	else:
		var extra: String = "" if fields.is_empty() else " " + JSON.stringify(fields)
		print("[%s] %s: %s%s" % [lvl_name.to_upper(), tag, msg, extra])
	if level == Level.ERROR:
		push_error("%s: %s" % [tag, msg])
	elif level == Level.WARN:
		push_warning("%s: %s" % [tag, msg])
```

### 9.6 `game/shared/autoload/config.gd`
```gdscript
extends Node
## Runtime configuration from cmdline user args (after `--`), env vars, and user settings.

enum Mode { LOCAL, CLIENT, SERVER, TEST }

var mode: Mode = Mode.LOCAL
var server_port: int = 7777
var max_clients: int = 100
var connect_host: String = ""
var connect_port: int = 7777
var backend_url: String = "http://localhost:8080"
var service_token: String = ""      # server -> backend internal API
var ticket_hmac_key: String = ""    # shared with backend, server only
var channel_id: int = 1
var rng_seed: int = 0               # 0 = randomize
var local_codec_roundtrip: bool = false
var data_dir: String = "/data"      # server heartbeat/shutdown files


func _init() -> void:
	_parse_args(OS.get_cmdline_user_args())
	_parse_env()
	if OS.has_feature("dedicated_server"):
		mode = Mode.SERVER


func is_server() -> bool:
	return mode == Mode.SERVER


func mode_name() -> String:
	return String(Mode.keys()[mode])


func _parse_args(args: PackedStringArray) -> void:
	for arg: String in args:
		if arg == "--server":
			mode = Mode.SERVER
		elif arg.begins_with("--port="):
			server_port = int(arg.get_slice("=", 1))
		elif arg.begins_with("--connect="):
			mode = Mode.CLIENT
			var target: String = arg.get_slice("=", 1)
			connect_host = target.get_slice(":", 0)
			if target.contains(":"):
				connect_port = int(target.get_slice(":", 1))
		elif arg.begins_with("--seed="):
			rng_seed = int(arg.get_slice("=", 1))
		elif arg == "--codec-roundtrip":
			local_codec_roundtrip = true


func _parse_env() -> void:
	server_port = _env_int("SKYROPE_PORT", server_port)
	max_clients = _env_int("SKYROPE_MAX_CLIENTS", max_clients)
	channel_id = _env_int("SKYROPE_CHANNEL", channel_id)
	backend_url = OS.get_environment("SKYROPE_BACKEND_URL") if OS.has_environment("SKYROPE_BACKEND_URL") else backend_url
	service_token = OS.get_environment("SKYROPE_SERVICE_TOKEN")
	ticket_hmac_key = OS.get_environment("SKYROPE_TICKET_KEY")
	if OS.has_environment("SKYROPE_DATA_DIR"):
		data_dir = OS.get_environment("SKYROPE_DATA_DIR")


func _env_int(key: String, fallback: int) -> int:
	return int(OS.get_environment(key)) if OS.has_environment(key) else fallback
```

### 9.7 `game/shared/autoload/event_bus.gd`
```gdscript
extends Node
## Client-side presentation signals ONLY. The simulation must never use this.
## Naming: noun_verbed, past tense, typed args.

signal window_toggled(window_id: StringName, is_open: bool)  ## a UI window opened/closed
signal hotkey_pressed(slot: StringName)                      ## a quickslot key was pressed
signal chat_line_added(channel: int, sender: String, text: String) ## chat log should show a line
signal system_message_posted(text: String)                   ## "You gained 12 EXP" etc.
signal tooltip_requested(item_id: StringName, screen_pos: Vector2)
signal tooltip_dismissed()
signal map_transition_started(map_id: StringName)
signal map_transition_finished(map_id: StringName)
```

### 9.8 `game/shared/constants.gd`
```gdscript
class_name Const
## Project-wide enums and physics layer helpers.

enum EntityKind { PLAYER, MOB, DROP, PROJECTILE, NPC, PORTAL }

enum Layer {
	WORLD = 1, PLATFORM_ONEWAY = 2, PLAYER_BODY = 3, MOB_BODY = 4,
	PLAYER_HURTBOX = 5, MOB_HURTBOX = 6, CLIMBABLE = 7, PORTAL = 8,
	DROP = 9, NPC = 10, PROJECTILE = 11, MOB_WALL = 12,
}

enum InvTab { EQUIP, USE, ETC }

const GROUP_ONEWAY := &"oneway_platforms"
const GROUP_PORTALS := &"portals"
const INVENTORY_SLOTS_PER_TAB := 24


static func bit(layer: int) -> int:
	return 1 << (layer - 1)


static func mask(layers: Array[int]) -> int:
	var m: int = 0
	for l: int in layers:
		m |= bit(l)
	return m
```

### 9.9 Data registry and definitions

`game/shared/defs/base_def.gd`
```gdscript
class_name BaseDef
extends RefCounted
## Base for all read-only content definitions loaded from JSON.

var id: StringName = &""
var source_path: String = ""


## Linear interpolation helper for skill/level tables: [at_min, at_max] or explicit per-level arrays.
static func level_value(values: Variant, level: int, max_level: int) -> float:
	if values is Array:
		var arr: Array = values
		if arr.size() == max_level and max_level != 2:
			return float(arr[clampi(level, 1, max_level) - 1])
		if arr.size() == 2:
			if max_level <= 1:
				return float(arr[0])
			var t: float = float(clampi(level, 1, max_level) - 1) / float(max_level - 1)
			return roundf(lerpf(float(arr[0]), float(arr[1]), t))
	elif values is float or values is int:
		return float(values)
	push_error("level_value: unsupported value %s" % [values])
	return 0.0
```

`game/shared/defs/mob_def.gd`
```gdscript
class_name MobDef
extends BaseDef

var display_name: String
var level: int
var hp: int
var weapon_attack: int
var defense: int
var accuracy: int
var avoid: int
var exp: int
var move_speed: float
var chase_speed: float
var can_jump: bool
var behavior: StringName
var aggro_range: float
var contact_damage: bool
var knockback_resist: float
var drop_table: StringName
var scene_path: String
var body_size: Vector2
var respawn_ticks: int


static func from_dict(d: Dictionary) -> MobDef:
	var m := MobDef.new()
	m.id = StringName(d["id"])
	m.display_name = String(d["name"])
	m.level = int(d["level"])
	m.hp = int(d["hp"])
	m.weapon_attack = int(d["weapon_attack"])
	m.defense = int(d["defense"])
	m.accuracy = int(d.get("accuracy", 0))
	m.avoid = int(d.get("avoid", 0))
	m.exp = int(d["exp"])
	m.move_speed = float(d["move_speed"])
	m.chase_speed = float(d.get("chase_speed", d["move_speed"]))
	m.can_jump = bool(d.get("jump", false))
	m.behavior = StringName(d["behavior"])
	m.aggro_range = float(d.get("aggro_range", 0.0))
	m.contact_damage = bool(d.get("contact_damage", true))
	m.knockback_resist = float(d.get("knockback_resist", 0.0))
	m.drop_table = StringName(d["drop_table"])
	m.scene_path = String(d["scene"])
	var size: Array = d["body_size"]
	m.body_size = Vector2(float(size[0]), float(size[1]))
	m.respawn_ticks = int(float(d["respawn_s"]) * NetConfig.TICK_RATE)
	return m
```

`game/shared/defs/skill_def.gd`
```gdscript
class_name SkillDef
extends BaseDef

var display_name: String
var class_id: StringName
var type: StringName              # active_attack | buff | passive | projectile
var max_level: int
var animation: StringName
var cast_ticks: int
var hit_tick: int
var hitbox_offset: Vector2
var hitbox_size: Vector2
var max_targets: int
var hits: int
var levels: Dictionary            # raw per-level tables
var knockback: Vector2
var buff: Dictionary


static func from_dict(d: Dictionary) -> SkillDef:
	var s := SkillDef.new()
	s.id = StringName(d["id"])
	s.display_name = String(d["name"])
	s.class_id = StringName(d["class"])
	s.type = StringName(d["type"])
	s.max_level = int(d["max_level"])
	s.animation = StringName(d.get("animation", "attack_swing"))
	s.cast_ticks = int(float(d.get("cast_time_s", 0.4)) * NetConfig.TICK_RATE)
	s.hit_tick = int(float(d.get("hit_frame_s", 0.15)) * NetConfig.TICK_RATE)
	var hb: Dictionary = d.get("hitbox", {})
	if not hb.is_empty():
		s.hitbox_offset = Vector2(float(hb["offset"][0]), float(hb["offset"][1]))
		s.hitbox_size = Vector2(float(hb["size"][0]), float(hb["size"][1]))
	s.max_targets = int(d.get("max_targets", 1))
	s.hits = int(d.get("hits", 1))
	s.levels = d.get("levels", {})
	var kb: Array = d.get("knockback", [0, 0])
	s.knockback = Vector2(float(kb[0]), float(kb[1]))
	s.buff = d.get("buff", {})
	return s


func value(key: String, skill_level: int) -> float:
	return BaseDef.level_value(levels.get(key, 0), skill_level, max_level)
```
(Create `ClassDef`, `ItemDef`, `DropTableDef`, `MapDef`, `QuestDef`, `NpcDef`, `DialogueDef`, `ShopDef`, `StatsConfig` the same way, in the phase that first needs each one.)

`game/shared/autoload/data_registry.gd`
```gdscript
extends Node
## Loads every JSON content file listed in res://data/index.json into typed defs.
## Read-only after load. Fails loudly on any error.

const INDEX_PATH := "res://data/index.json"

var stats: StatsConfig
var level_table: PackedInt64Array = PackedInt64Array()
var classes: Dictionary = {}       # StringName -> ClassDef
var skills: Dictionary = {}        # StringName -> SkillDef
var mobs: Dictionary = {}          # StringName -> MobDef
var items: Dictionary = {}         # StringName -> ItemDef
var drop_tables: Dictionary = {}   # StringName -> DropTableDef
var maps: Dictionary = {}          # StringName -> MapDef
var quests: Dictionary = {}
var npcs: Dictionary = {}
var dialogues: Dictionary = {}
var shops: Dictionary = {}

var _loaded: bool = false
var _errors: PackedStringArray = PackedStringArray()


func _ready() -> void:
	_loaded = load_all()
	if not _loaded:
		for e: String in _errors:
			Log.error("data", e)


func is_loaded() -> bool:
	return _loaded


func errors() -> PackedStringArray:
	return _errors


func load_all() -> bool:
	_errors.clear()
	var index: Dictionary = _read_json(INDEX_PATH)
	if index.is_empty():
		return false
	stats = StatsConfig.from_dict(_read_json(String(index["stats"])))
	level_table = PackedInt64Array(_read_json(String(index["level_table"])).get("exp_to_next", []))
	_load_category(index, "mobs", "mobs", mobs, func(d: Dictionary) -> BaseDef: return MobDef.from_dict(d))
	_load_category(index, "skills", "skills", skills, func(d: Dictionary) -> BaseDef: return SkillDef.from_dict(d))
	# TODO(phase N): classes, items, drop_tables, maps, quests, npcs, dialogues, shops
	validate_references()
	return _errors.is_empty()


func mob(id: StringName) -> MobDef:
	var d: MobDef = mobs.get(id)
	if d == null:
		push_error("Unknown mob id: %s" % id)
	return d


func skill(id: StringName) -> SkillDef:
	var d: SkillDef = skills.get(id)
	if d == null:
		push_error("Unknown skill id: %s" % id)
	return d


## Cross-reference checks (drop tables -> items, mobs -> drop tables, quests -> npcs ...).
func validate_references() -> void:
	for m: MobDef in mobs.values():
		if not drop_tables.is_empty() and not drop_tables.has(m.drop_table):
			_errors.append("mob %s references unknown drop_table %s" % [m.id, m.drop_table])
	# TODO: extend per phase.


func _load_category(index: Dictionary, index_key: String, array_key: String, target: Dictionary, factory: Callable) -> void:
	for path: String in index.get(index_key, []):
		var root: Dictionary = _read_json(path)
		for entry: Dictionary in root.get(array_key, []):
			var def: BaseDef = factory.call(entry)
			if def == null:
				_errors.append("%s: failed to parse entry %s" % [path, entry.get("id", "?")])
				continue
			if target.has(def.id):
				_errors.append("%s: duplicate id %s" % [path, def.id])
				continue
			def.source_path = path
			target[def.id] = def


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		_errors.append("missing data file %s (is it in index.json and the export include_filter?)" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		_errors.append("invalid JSON object in %s" % path)
		return {}
	return parsed
```

`game/data/index.json` (generated by `tools/build_index.py`)
```json
{
  "schema_version": 1,
  "stats": "res://data/stats.json",
  "level_table": "res://data/level_table.json",
  "classes": ["res://data/classes.json"],
  "skills": ["res://data/skills/novice.json", "res://data/skills/vanguard.json"],
  "mobs": ["res://data/mobs/field_mobs.json"],
  "items": ["res://data/items/equips.json", "res://data/items/use.json", "res://data/items/etc.json"],
  "drop_tables": ["res://data/drop_tables.json"],
  "maps": ["res://data/maps/town_bramblewick.json", "res://data/maps/field_01.json"],
  "quests": ["res://data/quests/bramblewick.json"],
  "npcs": ["res://data/npcs/bramblewick.json"],
  "dialogues": ["res://data/dialogue/mara.json"],
  "shops": ["res://data/shops.json"]
}
```

### 9.10 Protocol, intents, events, input frames

`game/shared/net/net_config.gd`
```gdscript
class_name NetConfig
## Network/timing constants. Changing these requires bumping Protocol.VERSION.

const TICK_RATE: int = 60
const TICK_DT: float = 1.0 / 60.0
const SNAPSHOT_EVERY_TICKS: int = 3            # 20 Hz
const INPUT_REDUNDANCY: int = 3
const INTERP_DELAY_S: float = 0.1
const MAX_PENDING_INPUTS: int = 120            # 2 s of prediction history
const PEER_TIMEOUT_MS: int = 10_000
const CHANNEL_RELIABLE: int = 0
const CHANNEL_INPUT: int = 1
const CHANNEL_SNAPSHOT: int = 2
const POS_QUANT: float = 2.0                   # 0.5 px precision
```

`game/shared/net/protocol.gd`
```gdscript
class_name Protocol
## Wire-level enums. Append-only; never renumber. Bump VERSION on any breaking change.

const VERSION: int = 1

enum IntentType {
	CAST = 1, PICKUP = 2, USE_ITEM = 3, EQUIP = 4, UNEQUIP = 5, MOVE_ITEM = 6, DROP_ITEM = 7,
	ALLOC_AP = 8, ALLOC_SP = 9, TALK = 10, DIALOGUE_CHOICE = 11, BUY = 12, SELL = 13,
	ENTER_PORTAL = 14, RESPAWN = 15, CHAT = 16, SET_KEYBIND = 17,
	PARTY_INVITE = 30, PARTY_ACCEPT = 31, PARTY_LEAVE = 32,
	TRADE_REQUEST = 40, TRADE_ACCEPT = 41, TRADE_OFFER_ITEM = 42, TRADE_OFFER_CURRENCY = 43,
	TRADE_LOCK = 44, TRADE_CONFIRM = 45, TRADE_CANCEL = 46,
	FRIEND_ADD = 50, FRIEND_REMOVE = 51,
}

enum EventType {
	ENTITY_SPAWNED = 1, ENTITY_DESPAWNED = 2, DAMAGE = 3, DIED = 4, EXP_GAINED = 5,
	LEVEL_UP = 6, STATS_CHANGED = 7, VITALS_CHANGED = 8, INVENTORY_CHANGED = 9,
	CURRENCY_CHANGED = 10, ITEM_GAINED = 11, SKILL_CAST = 12, BUFF_APPLIED = 13,
	BUFF_EXPIRED = 14, MAP_CHANGED = 15, DIALOGUE_SHOW = 16, DIALOGUE_CLOSED = 17,
	QUEST_UPDATED = 18, SHOP_OPENED = 19, CHAT = 20, SYSTEM_MESSAGE = 21,
	INTENT_REJECTED = 22, FULL_STATE = 23, PARTY_UPDATED = 30, TRADE_UPDATED = 40,
}

enum Scope { PLAYER, MAP, WORLD }

enum Reject { NONE, INVALID, COOLDOWN, NO_MP, BUSY, OUT_OF_RANGE, INVENTORY_FULL, NOT_ALLOWED, RATE_LIMITED, NOT_ENOUGH_CURRENCY }

enum Disconnect { NONE, VERSION_MISMATCH, BAD_TICKET, DUPLICATE_LOGIN, KICKED, SERVER_SHUTDOWN, TIMEOUT }
```

`game/shared/net/intent.gd`
```gdscript
class_name Intent
extends RefCounted
## A request from a player to the authority. Never trusted; always validated by the sim.

var type: int = 0
var client_seq: int = 0     # echoed back in INTENT_REJECTED so the UI can react
var args: Array = []


static func make(t: int, a: Array = []) -> Intent:
	var i := Intent.new()
	i.type = t
	i.args = a
	return i


static func cast(skill_id: StringName, facing: int) -> Intent:
	return make(Protocol.IntentType.CAST, [String(skill_id), signi(facing)])


static func pickup(drop_eid: int) -> Intent:
	return make(Protocol.IntentType.PICKUP, [drop_eid])


static func use_item(tab: int, slot: int) -> Intent:
	return make(Protocol.IntentType.USE_ITEM, [tab, slot])


func to_wire() -> Array:
	return [type, client_seq, args]


## Returns null if malformed. Argument-level validation happens in the sim handler.
static func from_wire(w: Variant) -> Intent:
	if typeof(w) != TYPE_ARRAY:
		return null
	var a: Array = w
	if a.size() != 3 or typeof(a[0]) != TYPE_INT or typeof(a[1]) != TYPE_INT or typeof(a[2]) != TYPE_ARRAY:
		return null
	if (a[2] as Array).size() > 8:
		return null
	var i := Intent.new()
	i.type = a[0]
	i.client_seq = a[1]
	i.args = a[2]
	return i
```

`game/shared/net/sim_event.gd`
```gdscript
class_name SimEvent
extends RefCounted
## An authoritative result emitted by the simulation.

var type: int
var tick: int
var scope: int = Protocol.Scope.MAP
var target_eid: int = 0     # for Scope.PLAYER
var data: Array = []


static func make(t: int, p_tick: int, p_data: Array, p_scope: int = Protocol.Scope.MAP, p_target: int = 0) -> SimEvent:
	var e := SimEvent.new()
	e.type = t
	e.tick = p_tick
	e.data = p_data
	e.scope = p_scope
	e.target_eid = p_target
	return e


func to_wire() -> Array:
	return [type, tick, data]


static func from_wire(w: Array) -> SimEvent:
	return SimEvent.make(int(w[0]), int(w[1]), w[2])
```

`game/shared/net/input_frame.gd`
```gdscript
class_name InputFrame
extends RefCounted
## One tick of player input. 6 bytes on the wire.

const BTN_JUMP_HELD: int = 1 << 0
const BTN_JUMP_PRESSED: int = 1 << 1   # edge, computed client-side so redundancy is safe

var seq: int = 0        # u32, increments every tick
var move_x: int = 0     # -1, 0, 1
var move_y: int = 0     # -1 up, 0, 1 down
var buttons: int = 0


func pressed(btn: int) -> bool:
	return (buttons & btn) != 0


func encode(buf: StreamPeerBuffer) -> void:
	buf.put_u32(seq)
	buf.put_u8((move_x + 1) | ((move_y + 1) << 2))
	buf.put_u8(buttons)


static func decode(buf: StreamPeerBuffer) -> InputFrame:
	var f := InputFrame.new()
	f.seq = buf.get_u32()
	var axes: int = buf.get_u8()
	f.move_x = clampi((axes & 0b11) - 1, -1, 1)
	f.move_y = clampi(((axes >> 2) & 0b11) - 1, -1, 1)
	f.buttons = buf.get_u8() & (BTN_JUMP_HELD | BTN_JUMP_PRESSED)
	return f


static func neutral(p_seq: int) -> InputFrame:
	var f := InputFrame.new()
	f.seq = p_seq
	return f
```

`game/shared/net/codec.gd` (snapshot packing)
```gdscript
class_name Codec
## Compact binary encoding for snapshots and input batches.

static func encode_inputs(frames: Array[InputFrame]) -> PackedByteArray:
	var buf := StreamPeerBuffer.new()
	buf.put_u8(frames.size())
	for f: InputFrame in frames:
		f.encode(buf)
	return buf.data_array


static func decode_inputs(bytes: PackedByteArray) -> Array[InputFrame]:
	var out: Array[InputFrame] = []
	if bytes.size() < 1 or bytes.size() > 64:
		return out
	var buf := StreamPeerBuffer.new()
	buf.data_array = bytes
	var n: int = mini(buf.get_u8(), NetConfig.INPUT_REDUNDANCY)
	if bytes.size() < 1 + n * 6:
		return out
	for i: int in n:
		out.append(InputFrame.decode(buf))
	return out


## Snapshot layout:
## u32 tick | u32 last_processed_seq | self MotorState | u16 count | count * EntityState
static func encode_snapshot(tick: int, last_seq: int, self_state: MotorState, entities: Array[EntityState]) -> PackedByteArray:
	var buf := StreamPeerBuffer.new()
	buf.put_u32(tick)
	buf.put_u32(last_seq)
	self_state.encode(buf)
	buf.put_u16(entities.size())
	for e: EntityState in entities:
		e.encode(buf)
	return buf.data_array


static func decode_snapshot(bytes: PackedByteArray) -> Snapshot:
	var buf := StreamPeerBuffer.new()
	buf.data_array = bytes
	var s := Snapshot.new()
	s.tick = buf.get_u32()
	s.last_processed_seq = buf.get_u32()
	s.self_state = MotorState.decode(buf)
	var n: int = buf.get_u16()
	for i: int in n:
		s.entities.append(EntityState.decode(buf))
	return s
```
(`EntityState` = `eid u32, kind u8, def_index u16, x i16, y i16, anim u8, facing+flags u8, hp_pct u8` ≈ 13 bytes, so 70 entities fit in about 1 KB. `Snapshot` holds `tick`, `last_processed_seq`, `self_state`, `entities`. Positions are quantized with `NetConfig.POS_QUANT`.)

### 9.11 `game/shared/net/net.gd` (Net autoload: the ONLY place with `@rpc`)
```gdscript
extends Node
## Transport + RPC endpoints. Same script on client and server (RPC checksums must match).
## Gameplay never calls multiplayer directly; it goes through Authority/SessionManager.

signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)
signal hello_received(peer_id: int, protocol_version: int, ticket: String)
signal inputs_received(peer_id: int, frames: Array[InputFrame])
signal intent_received(peer_id: int, intent: Intent)
signal welcome_received(self_eid: int, map_id: StringName, server_tick: int)
signal snapshot_received(snapshot: Snapshot)
signal event_received(event: SimEvent)
signal connected()
signal connection_failed()
signal disconnected(reason: int)

var _peer: ENetMultiplayerPeer


func host(port: int, max_clients: int) -> Error:
	_peer = ENetMultiplayerPeer.new()
	var err: Error = _peer.create_server(port, max_clients)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = _peer
	multiplayer.peer_connected.connect(func(id: int) -> void: peer_joined.emit(id))
	multiplayer.peer_disconnected.connect(func(id: int) -> void: peer_left.emit(id))
	Log.info("net", "ENet server listening on UDP %d" % port)
	return OK


func join(address: String, port: int) -> Error:
	_peer = ENetMultiplayerPeer.new()
	var err: Error = _peer.create_client(address, port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = _peer
	multiplayer.connected_to_server.connect(func() -> void: connected.emit(), CONNECT_ONE_SHOT)
	multiplayer.connection_failed.connect(func() -> void: connection_failed.emit(), CONNECT_ONE_SHOT)
	multiplayer.server_disconnected.connect(func() -> void: disconnected.emit(Protocol.Disconnect.NONE), CONNECT_ONE_SHOT)
	return OK


func close() -> void:
	if _peer:
		_peer.close()
	multiplayer.multiplayer_peer = null


func kick(peer_id: int, reason: int) -> void:
	s2c_disconnect_reason.rpc_id(peer_id, reason)
	_peer.disconnect_peer(peer_id)   # TODO: delay a few frames so the reason arrives


# ---------- client -> server ----------

@rpc("any_peer", "call_remote", "reliable", NetConfig.CHANNEL_RELIABLE)
func c2s_hello(protocol_version: int, ticket: String) -> void:
	if not multiplayer.is_server():
		return
	hello_received.emit(multiplayer.get_remote_sender_id(), protocol_version, ticket.left(1024))


@rpc("any_peer", "call_remote", "unreliable_ordered", NetConfig.CHANNEL_INPUT)
func c2s_inputs(bytes: PackedByteArray) -> void:
	if not multiplayer.is_server():
		return
	inputs_received.emit(multiplayer.get_remote_sender_id(), Codec.decode_inputs(bytes))


@rpc("any_peer", "call_remote", "reliable", NetConfig.CHANNEL_RELIABLE)
func c2s_intent(wire: Array) -> void:
	if not multiplayer.is_server():
		return
	var intent: Intent = Intent.from_wire(wire)
	if intent != null:
		intent_received.emit(multiplayer.get_remote_sender_id(), intent)


# ---------- server -> client ----------

@rpc("authority", "call_remote", "reliable", NetConfig.CHANNEL_RELIABLE)
func s2c_welcome(self_eid: int, map_id: String, server_tick: int) -> void:
	welcome_received.emit(self_eid, StringName(map_id), server_tick)


@rpc("authority", "call_remote", "unreliable_ordered", NetConfig.CHANNEL_SNAPSHOT)
func s2c_snapshot(bytes: PackedByteArray) -> void:
	snapshot_received.emit(Codec.decode_snapshot(bytes))


@rpc("authority", "call_remote", "reliable", NetConfig.CHANNEL_RELIABLE)
func s2c_event(wire: Array) -> void:
	event_received.emit(SimEvent.from_wire(wire))


@rpc("authority", "call_remote", "reliable", NetConfig.CHANNEL_RELIABLE)
func s2c_disconnect_reason(reason: int) -> void:
	disconnected.emit(reason)


# ---------- helpers used by server code ----------

func send_snapshot(peer_id: int, bytes: PackedByteArray) -> void:
	s2c_snapshot.rpc_id(peer_id, bytes)


func send_event(peer_id: int, event: SimEvent) -> void:
	s2c_event.rpc_id(peer_id, event.to_wire())
```
> Note: if the pinned Godot version rejects class-constant references inside `@rpc(...)` annotations, replace `NetConfig.CHANNEL_*` with the literals `0/1/2` and keep a comment pointing at `NetConfig`.

### 9.12 Authority interface and implementations

`game/shared/authority/authority.gd`
```gdscript
class_name Authority
extends Node
## Abstract gateway between presentation and the authoritative simulation.
## Presentation code depends ONLY on this interface.

signal entered_map(map_id: StringName, self_eid: int, record: Dictionary)
signal snapshot_received(snapshot: Snapshot)
signal event_received(event: SimEvent)
signal disconnected(reason: int)

var self_eid: int = 0
var _next_intent_seq: int = 1


func start(_params: Dictionary) -> void:
	push_error("Authority.start() not implemented")


func stop() -> void:
	pass


## Called every physics tick by the client's InputSampler.
func submit_input(_frame: InputFrame) -> void:
	push_error("Authority.submit_input() not implemented")


## Returns the client_seq assigned to the intent (to correlate rejections).
func submit_intent(intent: Intent) -> int:
	intent.client_seq = _next_intent_seq
	_next_intent_seq += 1
	_send_intent(intent)
	return intent.client_seq


func _send_intent(_intent: Intent) -> void:
	push_error("Authority._send_intent() not implemented")
```

`game/shared/authority/local_authority.gd`
```gdscript
class_name LocalAuthority
extends Authority
## Single-player: hosts an in-process WorldSim and talks to it directly.
## Produces the SAME snapshots/events the server would, so presentation is identical.

const LOCAL_PEER_ID: int = 1

var sim: WorldSim
var storage: CharacterStorage
var _last_seq: int = 0


func start(params: Dictionary) -> void:
	storage = params.get("storage", LocalFileStorage.new())
	sim = WorldSim.new()
	sim.name = "WorldSim"
	sim.seed_rng(Config.rng_seed)
	add_child(sim)
	sim.event_emitted.connect(_on_sim_event)
	var record: CharacterRecord = await storage.load_character(int(params.get("character_id", 1)))
	if record == null:
		record = CharacterRecord.new_default(String(params.get("name", "Adventurer")))
	self_eid = sim.spawn_player(record, LOCAL_PEER_ID)
	entered_map.emit(record.map_id, self_eid, record.to_dict())


func stop() -> void:
	if sim and self_eid != 0:
		await storage.save_character(sim.export_record(self_eid))


func submit_input(frame: InputFrame) -> void:
	_last_seq = frame.seq
	var frames: Array[InputFrame] = [frame]
	sim.queue_input(self_eid, frames)


func _send_intent(intent: Intent) -> void:
	if Config.local_codec_roundtrip:
		intent = Intent.from_wire(intent.to_wire())   # catch serialization bugs early
	sim.handle_intent(self_eid, intent)


func _physics_process(_delta: float) -> void:
	if sim == null or self_eid == 0:
		return
	sim.step()
	if sim.tick % NetConfig.SNAPSHOT_EVERY_TICKS == 0:
		var bytes: PackedByteArray = sim.build_snapshot_for(self_eid)
		snapshot_received.emit(Codec.decode_snapshot(bytes))  # same path as network


func _on_sim_event(map_id: StringName, event: SimEvent) -> void:
	if map_id != sim.map_of(self_eid):
		return
	if event.scope == Protocol.Scope.PLAYER and event.target_eid != self_eid:
		return
	event_received.emit(event)
```

`game/shared/authority/remote_authority.gd` (Phase 9)
```gdscript
class_name RemoteAuthority
extends Authority
## Online play: forwards inputs/intents over Net and surfaces server snapshots/events.

var _input_history: Array[InputFrame] = []


func start(params: Dictionary) -> void:
	Net.welcome_received.connect(_on_welcome)
	Net.snapshot_received.connect(func(s: Snapshot) -> void: snapshot_received.emit(s))
	Net.event_received.connect(func(e: SimEvent) -> void: event_received.emit(e))
	Net.disconnected.connect(func(r: int) -> void: disconnected.emit(r))
	Net.connected.connect(func() -> void: Net.c2s_hello.rpc_id(1, Protocol.VERSION, String(params.get("ticket", ""))), CONNECT_ONE_SHOT)
	var err: Error = Net.join(String(params["host"]), int(params["port"]))
	if err != OK:
		disconnected.emit(Protocol.Disconnect.NONE)


func stop() -> void:
	Net.close()


func submit_input(frame: InputFrame) -> void:
	_input_history.append(frame)
	if _input_history.size() > NetConfig.INPUT_REDUNDANCY:
		_input_history.pop_front()
	Net.c2s_inputs.rpc_id(1, Codec.encode_inputs(_input_history))


func _send_intent(intent: Intent) -> void:
	Net.c2s_intent.rpc_id(1, intent.to_wire())


func _on_welcome(eid: int, map_id: StringName, _server_tick: int) -> void:
	self_eid = eid
	entered_map.emit(map_id, eid, {})   # full record arrives via FULL_STATE event
```

### 9.13 Simulation core

`game/sim/world/world_sim.gd`
```gdscript
class_name WorldSim
extends Node
## The authoritative world. Runs in LocalAuthority (single-player) and on the dedicated server.
## Never references client/, Input, UI, audio, or Net.

signal event_emitted(map_id: StringName, event: SimEvent)

const MAP_INSTANCE_SCENE: PackedScene = preload("res://sim/world/map_instance.tscn")

var tick: int = 0
var rng := RandomNumberGenerator.new()
var ids := IdAllocator.new()

var _maps: Dictionary = {}          # StringName -> MapInstance
var _player_map: Dictionary = {}    # eid -> StringName
var _players: Dictionary = {}       # eid -> PlayerEntity


func seed_rng(seed_value: int) -> void:
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value


## Advance one fixed tick. Called by the owner (LocalAuthority or ServerMain), never self-driven.
func step() -> void:
	tick += 1
	for m: MapInstance in _maps.values():
		m.step(tick)


func spawn_player(record: CharacterRecord, owner_peer: int) -> int:
	var map: MapInstance = get_or_create_map(record.map_id)
	var player: PlayerEntity = map.spawn_player(record, owner_peer, ids.next())
	_players[player.eid] = player
	_player_map[player.eid] = map.map_id
	return player.eid


func despawn_player(eid: int) -> CharacterRecord:
	var record: CharacterRecord = export_record(eid)
	var map: MapInstance = _maps.get(_player_map.get(eid, &""))
	if map:
		map.remove_entity(eid)
	_players.erase(eid)
	_player_map.erase(eid)
	return record


func export_record(eid: int) -> CharacterRecord:
	var p: PlayerEntity = _players.get(eid)
	return p.to_record() if p else null


func queue_input(eid: int, frames: Array[InputFrame]) -> void:
	var p: PlayerEntity = _players.get(eid)
	if p:
		p.input_queue.push_frames(frames)


func handle_intent(eid: int, intent: Intent) -> void:
	var p: PlayerEntity = _players.get(eid)
	if p == null:
		return
	var map: MapInstance = _maps[_player_map[eid]]
	map.handle_intent(p, intent)


func map_of(eid: int) -> StringName:
	return _player_map.get(eid, &"")


func build_snapshot_for(eid: int) -> PackedByteArray:
	var p: PlayerEntity = _players[eid]
	return _maps[_player_map[eid]].build_snapshot(p)


func get_or_create_map(map_id: StringName) -> MapInstance:
	if _maps.has(map_id):
		return _maps[map_id]
	var inst: MapInstance = MAP_INSTANCE_SCENE.instantiate()
	inst.setup(self, DataRegistry.maps[map_id])   # sets own World2D BEFORE entering the tree
	add_child(inst)
	_maps[map_id] = inst
	return inst


## Called by MapInstance; routes events to the owner (server/local authority).
func emit_event(map_id: StringName, event: SimEvent) -> void:
	event_emitted.emit(map_id, event)


func transfer_player(eid: int, to_map: StringName, to_portal: StringName) -> void:
	pass  # TODO(phase 5): remove from old map, spawn in new map at portal, emit MAP_CHANGED
```

`game/sim/world/map_instance.gd`
```gdscript
class_name MapInstance
extends SubViewport
## One loaded map with its own physics space (World2D). Owns all entities on that map.

var map_id: StringName
var def: MapDef
var sim: WorldSim
var entities: Dictionary = {}    # eid -> Entity

var _map_root: Node2D
var _entity_root: Node2D
var _spawners: Array[Spawner] = []


func setup(p_sim: WorldSim, p_def: MapDef) -> void:
	sim = p_sim
	def = p_def
	map_id = p_def.id
	name = "Map_%s" % map_id
	world_2d = World2D.new()                         # isolated physics space per map
	disable_3d = true
	render_target_update_mode = SubViewport.UPDATE_DISABLED
	_map_root = (load(def.scene_path) as PackedScene).instantiate()
	add_child(_map_root)
	_entity_root = Node2D.new()
	_entity_root.name = "Entities"
	add_child(_entity_root)
	# TODO(phase 2): build spawners from def.spawns + marker groups


func step(tick: int) -> void:
	# Fixed order. See BUILD_SCOPE §6.5. Do not reorder without a Decision Log entry.
	for e: Entity in entities.values():
		if e is PlayerEntity:
			(e as PlayerEntity).step_movement(tick)
	for e: Entity in entities.values():
		if e is PlayerEntity:
			(e as PlayerEntity).step_actions(tick)       # casting state machine -> hit queries
	for e: Entity in entities.values():
		if e is MobEntity:
			(e as MobEntity).step_ai(tick)
	# TODO: projectiles, combat queue, buffs/cooldowns/regen, spawners, drop expiry


func spawn_player(record: CharacterRecord, owner_peer: int, eid: int) -> PlayerEntity:
	var p: PlayerEntity = preload("res://sim/entities/player_entity.tscn").instantiate()
	p.eid = eid
	p.owner_peer = owner_peer
	p.map = self
	_entity_root.add_child(p)
	p.apply_record(record)
	p.global_position = spawn_point(record.spawn_portal)
	entities[eid] = p
	emit(SimEvent.make(Protocol.EventType.ENTITY_SPAWNED, sim.tick, [eid, Const.EntityKind.PLAYER]))
	return p


func remove_entity(eid: int) -> void:
	var e: Entity = entities.get(eid)
	if e:
		entities.erase(eid)
		e.queue_free()
		emit(SimEvent.make(Protocol.EventType.ENTITY_DESPAWNED, sim.tick, [eid]))


func handle_intent(player: PlayerEntity, intent: Intent) -> void:
	match intent.type:
		Protocol.IntentType.CAST:
			player.try_cast(intent)
		_:
			reject(player, intent, Protocol.Reject.INVALID)


func reject(player: PlayerEntity, intent: Intent, reason: int) -> void:
	emit(SimEvent.make(Protocol.EventType.INTENT_REJECTED, sim.tick, [intent.client_seq, reason], Protocol.Scope.PLAYER, player.eid))


func emit(event: SimEvent) -> void:
	sim.emit_event(map_id, event)


func space_state() -> PhysicsDirectSpaceState2D:
	return world_2d.direct_space_state


func spawn_point(portal_id: StringName) -> Vector2:
	for marker: Node in _map_root.get_tree().get_nodes_in_group(Const.GROUP_PORTALS):
		if marker is Marker2D and marker.name == portal_id and _map_root.is_ancestor_of(marker):
			return (marker as Marker2D).global_position
	return Vector2.ZERO


func build_snapshot(for_player: PlayerEntity) -> PackedByteArray:
	var states: Array[EntityState] = []
	for e: Entity in entities.values():
		if e != for_player:
			states.append(e.to_entity_state())
	return Codec.encode_snapshot(sim.tick, for_player.input_queue.last_processed_seq, for_player.motor.capture(), states)
```

`game/shared/util/id_allocator.gd`
```gdscript
class_name IdAllocator
extends RefCounted
## Monotonic runtime entity IDs. Never reused within a process lifetime.

var _next: int = 1


func next() -> int:
	var id: int = _next
	_next += 1
	return id
```

### 9.14 Entity and components

`game/sim/entities/entity.gd`
```gdscript
class_name Entity
extends CharacterBody2D
## Base for all simulated entities. Contains NO visuals.
## Components are child nodes extending Component; looked up by node name.

var eid: int = 0
var kind: Const.EntityKind = Const.EntityKind.MOB
var map: MapInstance
var _components: Dictionary = {}   # StringName -> Component


func _ready() -> void:
	for child: Node in get_children():
		if child is Component:
			var c: Component = child
			c.entity = self
			_components[StringName(c.name)] = c
			c.on_attached()


func get_component(component_name: StringName) -> Component:
	return _components.get(component_name)


func has_component(component_name: StringName) -> bool:
	return _components.has(component_name)


func to_entity_state() -> EntityState:
	var s := EntityState.new()
	s.eid = eid
	s.kind = kind
	s.position = global_position
	return s
```

`game/sim/components/component.gd`
```gdscript
class_name Component
extends Node
## Base for entity components. Override on_attached() instead of _ready() for sibling lookups.

var entity: Entity


func on_attached() -> void:
	pass
```

`game/sim/components/stats_component.gd`
```gdscript
class_name StatsComponent
extends Component
## Base stats + equipment + buffs -> derived totals. Recalculate on any change.

signal changed()

const PRIMARY: Array[StringName] = [&"str", &"dex", &"int", &"luk"]

var level: int = 1
var class_id: StringName = &"novice"
var base: Dictionary = {&"str": 4, &"dex": 4, &"int": 4, &"luk": 4}
var equip_bonus: Dictionary = {}    # StringName -> int
var buff_bonus: Dictionary = {}     # StringName -> int
var totals: Dictionary = {}         # computed


func recalculate() -> void:
	totals.clear()
	for src: Dictionary in [base, equip_bonus, buff_bonus]:
		for key: StringName in src.keys():
			totals[key] = int(totals.get(key, 0)) + int(src[key])
	totals[&"crit_rate"] = DataRegistry.stats.crit_base_rate + float(totals.get(&"luk", 0)) * 0.0005
	changed.emit()


func get_total(key: StringName) -> int:
	return int(totals.get(key, 0))


func primary_stat() -> int:
	var cdef: ClassDef = DataRegistry.classes[class_id]
	return get_total(cdef.primary_stat)


func secondary_stat() -> int:
	var cdef: ClassDef = DataRegistry.classes[class_id]
	return get_total(cdef.secondary_stat)
```

`game/sim/components/health_component.gd`
```gdscript
class_name HealthComponent
extends Component
## HP/MP pool with invulnerability frames. Tick-based timers only.

signal damaged(amount: int, source_eid: int, is_crit: bool)
signal healed(amount: int)
signal died(killer_eid: int)

var hp: int = 1
var max_hp: int = 1
var mp: int = 0
var max_mp: int = 0
var invuln_ticks: int = 0


func is_dead() -> bool:
	return hp <= 0


## Returns damage actually dealt (0 if invulnerable/dead).
func apply_damage(amount: int, source_eid: int, is_crit: bool, invuln_after: int = 0) -> int:
	if is_dead() or invuln_ticks > 0 or amount <= 0:
		return 0
	var dealt: int = mini(amount, hp)
	hp -= dealt
	invuln_ticks = invuln_after
	damaged.emit(dealt, source_eid, is_crit)
	if hp <= 0:
		died.emit(source_eid)
	return dealt


func heal(amount: int) -> int:
	if is_dead():
		return 0
	var before: int = hp
	hp = mini(hp + maxi(amount, 0), max_hp)
	if hp != before:
		healed.emit(hp - before)
	return hp - before


func spend_mp(amount: int) -> bool:
	if mp < amount:
		return false
	mp -= amount
	return true


func tick() -> void:
	if invuln_ticks > 0:
		invuln_ticks -= 1
```

`game/sim/components/hurtbox.gd`
```gdscript
class_name Hurtbox
extends Area2D
## Damageable region. Hit detection is done by shape QUERIES (HitQuery), not area signals.

@export var team_layer: Const.Layer = Const.Layer.MOB_HURTBOX


func _ready() -> void:
	collision_layer = Const.bit(team_layer)
	collision_mask = 0
	monitoring = false      # we never listen; others query us
	monitorable = true


func owner_entity() -> Entity:
	return get_parent() as Entity
```

`game/sim/combat/hit_query.gd`
```gdscript
class_name HitQuery
## Resolves "which hurtboxes does this attack box touch" with a direct space query.

static func query_rect(space: PhysicsDirectSpaceState2D, origin: Vector2, facing: int,
		offset: Vector2, size: Vector2, target_layer: int, max_targets: int) -> Array[Entity]:
	var shape := RectangleShape2D.new()
	shape.size = size
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, origin + Vector2(offset.x * signf(facing), offset.y))
	params.collision_mask = Const.bit(target_layer)
	params.collide_with_areas = true
	params.collide_with_bodies = false
	var results: Array[Dictionary] = space.intersect_shape(params, 32)
	var found: Array[Entity] = []
	for r: Dictionary in results:
		var hb: Hurtbox = r["collider"] as Hurtbox
		if hb == null:
			continue
		var e: Entity = hb.owner_entity()
		if e and not found.has(e):
			found.append(e)
	found.sort_custom(func(a: Entity, b: Entity) -> bool: return absf(a.global_position.x - origin.x) < absf(b.global_position.x - origin.x))
	return found.slice(0, max_targets)
```

### 9.15 Movement (shared by client prediction and server)

`game/sim/movement/motor_state.gd`
```gdscript
class_name MotorState
extends RefCounted
## Everything needed to reproduce MovementMotor exactly (for reconciliation).

var position: Vector2
var velocity: Vector2
var state: int
var facing: int = 1
var coyote: int
var jump_buffer: int
var drop_through: int
var climb_x: float
var knockback: int


func encode(buf: StreamPeerBuffer) -> void:
	buf.put_float(position.x); buf.put_float(position.y)
	buf.put_float(velocity.x); buf.put_float(velocity.y)
	buf.put_u8(state); buf.put_8(facing)
	buf.put_u8(coyote); buf.put_u8(jump_buffer); buf.put_u8(drop_through); buf.put_u8(knockback)
	buf.put_float(climb_x)


static func decode(buf: StreamPeerBuffer) -> MotorState:
	var s := MotorState.new()
	s.position = Vector2(buf.get_float(), buf.get_float())
	s.velocity = Vector2(buf.get_float(), buf.get_float())
	s.state = buf.get_u8(); s.facing = buf.get_8()
	s.coyote = buf.get_u8(); s.jump_buffer = buf.get_u8(); s.drop_through = buf.get_u8(); s.knockback = buf.get_u8()
	s.climb_x = buf.get_float()
	return s
```
(The local player's own state is sent as full floats for exact reconciliation. Other entities use quantized `EntityState`.)

`game/sim/movement/movement_motor.gd`
```gdscript
class_name MovementMotor
extends Component
## Deterministic side-scroller movement on a CharacterBody2D.
## Pure function of (MotorState, InputFrame, static terrain). Used by server AND client prediction.
## Ropes/ladders use direct space queries (NOT Area2D signals) so re-simulation works.

enum State { GROUND, AIR, CLIMB }

@export var walk_speed: float = 125.0
@export var accel: float = 1400.0
@export var decel: float = 1800.0
@export var air_control: float = 0.0          # genre feel: committed jumps. Tune 0.0-0.35
@export var jump_velocity: float = -330.0
@export var gravity: float = 1000.0
@export var max_fall: float = 600.0
@export var climb_speed: float = 80.0
@export var coyote_ticks: int = 5
@export var jump_buffer_ticks: int = 6
@export var drop_through_ticks: int = 12

var state: State = State.AIR
var facing: int = 1
var _coyote: int = 0
var _jump_buffer: int = 0
var _drop_through: int = 0
var _climb_x: float = 0.0
var _knockback: int = 0
var _regrab_cooldown: int = 0


func step(frame: InputFrame, dt: float) -> void:
	var body: Entity = entity
	if _drop_through > 0:
		_drop_through -= 1
		if _drop_through == 0:
			body.set_collision_mask_value(Const.Layer.PLATFORM_ONEWAY, true)
	_regrab_cooldown = maxi(_regrab_cooldown - 1, 0)
	if state == State.CLIMB:
		_step_climb(frame, dt)
	else:
		_step_platformer(frame, dt)


func apply_knockback(impulse: Vector2, ticks: int) -> void:
	state = State.AIR
	entity.velocity = impulse
	_knockback = ticks


func capture() -> MotorState:
	var s := MotorState.new()
	s.position = entity.global_position
	s.velocity = entity.velocity
	s.state = state
	s.facing = facing
	s.coyote = _coyote
	s.jump_buffer = _jump_buffer
	s.drop_through = _drop_through
	s.climb_x = _climb_x
	s.knockback = _knockback
	return s


func restore(s: MotorState) -> void:
	entity.global_position = s.position
	entity.velocity = s.velocity
	state = s.state as State
	facing = s.facing
	_coyote = s.coyote
	_jump_buffer = s.jump_buffer
	_drop_through = s.drop_through
	_climb_x = s.climb_x
	_knockback = s.knockback
	entity.set_collision_mask_value(Const.Layer.PLATFORM_ONEWAY, _drop_through == 0 and state != State.CLIMB)


func _step_platformer(frame: InputFrame, dt: float) -> void:
	var body: Entity = entity
	var on_floor: bool = body.is_on_floor()
	if _knockback > 0:
		_knockback -= 1
	else:
		var target: float = float(frame.move_x) * walk_speed
		var rate: float = accel if frame.move_x != 0 else decel
		if not on_floor:
			rate *= air_control
		body.velocity.x = move_toward(body.velocity.x, target, rate * dt)
		if frame.move_x != 0:
			facing = frame.move_x
	_coyote = coyote_ticks if on_floor else maxi(_coyote - 1, 0)
	_jump_buffer = jump_buffer_ticks if frame.pressed(InputFrame.BTN_JUMP_PRESSED) else maxi(_jump_buffer - 1, 0)

	if _jump_buffer > 0 and on_floor and frame.move_y > 0 and _standing_on_oneway():
		body.set_collision_mask_value(Const.Layer.PLATFORM_ONEWAY, false)
		_drop_through = drop_through_ticks
		_jump_buffer = 0
	elif _jump_buffer > 0 and _coyote > 0 and _knockback == 0:
		body.velocity.y = jump_velocity
		_jump_buffer = 0
		_coyote = 0

	if frame.move_y != 0 and _regrab_cooldown == 0 and _try_grab_climbable(frame.move_y):
		return

	body.velocity.y = minf(body.velocity.y + gravity * dt, max_fall)
	body.move_and_slide()
	state = State.GROUND if body.is_on_floor() else State.AIR


func _step_climb(frame: InputFrame, dt: float) -> void:
	var body: Entity = entity
	if frame.pressed(InputFrame.BTN_JUMP_PRESSED) and frame.move_x != 0:
		state = State.AIR
		_regrab_cooldown = 15
		body.velocity = Vector2(float(frame.move_x) * walk_speed * 0.8, jump_velocity * 0.55)
		body.set_collision_mask_value(Const.Layer.PLATFORM_ONEWAY, true)
		facing = frame.move_x
		return
	body.global_position.x = _climb_x
	body.velocity = Vector2(0.0, float(frame.move_y) * climb_speed)
	body.move_and_slide()
	var still_on: bool = ClimbQuery.find(body.map.space_state(), body.global_position) != null
	if not still_on or (frame.move_y > 0 and body.is_on_floor()):
		state = State.AIR   # TODO(phase 1): snap onto the top platform when exiting upward
		body.set_collision_mask_value(Const.Layer.PLATFORM_ONEWAY, true)


func _try_grab_climbable(dir_y: int) -> bool:
	var probe: Vector2 = entity.global_position + Vector2(0.0, -8.0 if dir_y < 0 else 4.0)
	var area: Area2D = ClimbQuery.find(entity.map.space_state(), probe)
	if area == null:
		return false
	state = State.CLIMB
	_climb_x = area.global_position.x
	entity.velocity = Vector2.ZERO
	entity.set_collision_mask_value(Const.Layer.PLATFORM_ONEWAY, false)
	return true


func _standing_on_oneway() -> bool:
	for i: int in entity.get_slide_collision_count():
		var c: KinematicCollision2D = entity.get_slide_collision(i)
		var collider: Object = c.get_collider()
		if c.get_normal().y < -0.7 and collider is Node and (collider as Node).is_in_group(Const.GROUP_ONEWAY):
			return true
	return false
```

`game/sim/movement/climb_query.gd`
```gdscript
class_name ClimbQuery
## Point query against rope/ladder areas (layer CLIMBABLE).

static func find(space: PhysicsDirectSpaceState2D, point: Vector2) -> Area2D:
	var params := PhysicsPointQueryParameters2D.new()
	params.position = point
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = Const.bit(Const.Layer.CLIMBABLE)
	var hits: Array[Dictionary] = space.intersect_point(params, 1)
	return hits[0]["collider"] as Area2D if hits.size() > 0 else null
```

### 9.16 Player action state machine (tick-based)

`game/sim/entities/states/tick_state.gd`
```gdscript
class_name TickState
extends RefCounted
## Base for tick-driven states. Return a state name from tick() to transition, or &"" to stay.

var machine: TickStateMachine
var ticks_in_state: int = 0


func enter(_args: Dictionary) -> void:
	pass


func exit() -> void:
	pass


func tick(_t: int) -> StringName:
	return &""


func can_act() -> bool:
	return false
```

`game/sim/entities/states/tick_state_machine.gd`
```gdscript
class_name TickStateMachine
extends RefCounted

signal state_changed(from: StringName, to: StringName)

var owner_entity: Entity
var current_name: StringName = &""
var current: TickState
var _states: Dictionary = {}   # StringName -> TickState


func add(state_name: StringName, state: TickState) -> void:
	state.machine = self
	_states[state_name] = state


func transition(to: StringName, args: Dictionary = {}) -> void:
	assert(_states.has(to), "Unknown state %s" % to)
	var from: StringName = current_name
	if current:
		current.exit()
	current_name = to
	current = _states[to]
	current.ticks_in_state = 0
	current.enter(args)
	state_changed.emit(from, to)


func tick(t: int) -> void:
	if current == null:
		return
	current.ticks_in_state += 1
	var next: StringName = current.tick(t)
	if next != &"":
		transition(next)
```

`game/sim/entities/states/casting_state.gd`
```gdscript
class_name CastingState
extends TickState
## Locks the player while a skill animation plays; fires the hit on hit_tick.

var _skill: SkillDef
var _skill_level: int
var _facing: int
var _fired: bool


func enter(args: Dictionary) -> void:
	_skill = args["skill"]
	_skill_level = int(args["level"])
	_facing = int(args["facing"])
	_fired = false


func tick(_t: int) -> StringName:
	if not _fired and ticks_in_state >= _skill.hit_tick:
		_fired = true
		var player: PlayerEntity = machine.owner_entity as PlayerEntity
		CombatResolver.resolve_skill_hit(player, _skill, _skill_level, _facing)
	if ticks_in_state >= _skill.cast_ticks:
		return &"idle"
	return &""
```
Other states to create: `IdleState` (`can_act() -> true`), `HurtState` (short lock, knockback), `DeadState` (waits for a RESPAWN intent). Movement is still driven by `MovementMotor`. While `CastingState` is active, the server feeds the motor a neutral `move_x` on the ground (genre convention: you stop to swing), but you keep momentum in the air.

### 9.17 Mob AI skeleton

`game/sim/ai/mob_brain.gd`
```gdscript
class_name MobBrain
extends Component
## Simple tick-based AI: patrol edge-to-edge, aggro, chase on same platform, flinch, die.

enum S { IDLE, PATROL, CHASE, HURT, DEAD }

const THINK_EVERY: int = 6

var def: MobDef
var state: S = S.PATROL
var dir: int = 1
var target_eid: int = 0
var _think_in: int = 0
var _state_ticks: int = 0
var _gravity: float = 1000.0


func on_attached() -> void:
	var health: HealthComponent = entity.get_component(&"HealthComponent") as HealthComponent
	health.damaged.connect(_on_damaged)
	health.died.connect(func(_k: int) -> void: _set_state(S.DEAD))


func step(_tick: int, dt: float) -> void:
	var body: Entity = entity
	_state_ticks += 1
	_think_in -= 1
	if _think_in <= 0:
		_think_in = THINK_EVERY
		_think()
	match state:
		S.IDLE:
			body.velocity.x = 0.0
		S.PATROL:
			if _wall_or_edge_ahead():
				dir = -dir
			body.velocity.x = dir * def.move_speed
		S.CHASE:
			var target: Entity = body.map.entities.get(target_eid)
			if target == null:
				_set_state(S.PATROL)
			else:
				dir = signi(int(target.global_position.x - body.global_position.x)) if absf(target.global_position.x - body.global_position.x) > 4.0 else dir
				body.velocity.x = 0.0 if _wall_or_edge_ahead() else dir * def.chase_speed
		S.HURT:
			body.velocity.x = move_toward(body.velocity.x, 0.0, 600.0 * dt)
			if _state_ticks > 18:
				_set_state(S.CHASE if target_eid != 0 else S.PATROL)
		S.DEAD:
			return
	body.velocity.y = minf(body.velocity.y + _gravity * dt, 600.0)
	body.move_and_slide()


func _think() -> void:
	if state == S.PATROL and entity.map.sim.rng.randf() < 0.05:
		_set_state(S.IDLE)
	elif state == S.IDLE and _state_ticks > 60:
		dir = 1 if entity.map.sim.rng.randf() < 0.5 else -1
		_set_state(S.PATROL)
	# TODO(phase 2): aggro_on_sight using def.aggro_range; drop target if far/dead/other map


func _on_damaged(_amount: int, source_eid: int, _crit: bool) -> void:
	if state == S.DEAD:
		return
	if def.behavior != &"patrol" and source_eid != 0:
		target_eid = source_eid
	_set_state(S.HURT)


func _set_state(s: S) -> void:
	state = s
	_state_ticks = 0


func _wall_or_edge_ahead() -> bool:
	var body: Entity = entity
	if body.is_on_wall():
		return true
	var space: PhysicsDirectSpaceState2D = body.map.space_state()
	var from: Vector2 = body.global_position + Vector2(dir * (def.body_size.x * 0.5 + 2.0), 0.0)
	var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0.0, 24.0),
		Const.mask([Const.Layer.WORLD, Const.Layer.PLATFORM_ONEWAY]))
	var wall_query := PhysicsRayQueryParameters2D.create(body.global_position, from, Const.bit(Const.Layer.MOB_WALL))
	wall_query.collide_with_areas = true
	return space.intersect_ray(query).is_empty() or not space.intersect_ray(wall_query).is_empty()
```

### 9.18 Damage formula (pure, fully unit-tested)

`game/sim/combat/damage_formula.gd`
```gdscript
class_name DamageFormula
## Pure damage math. No node access. All randomness via injected RNG.

class AttackInput:
	var level: int
	var primary: int
	var secondary: int
	var attack: int            # weapon_attack or magic_attack
	var mastery_bonus: float = 0.0
	var crit_rate: float = 0.05
	var skill_pct: float = 100.0

class DefenseInput:
	var level: int
	var defense: int

class Result:
	var amount: int
	var crit: bool
	func _init(a: int, c: bool) -> void:
		amount = a
		crit = c


static func max_base(primary: int, secondary: int, attack: int) -> float:
	return float(primary * 4 + secondary) * float(attack) / 100.0


static func roll(atk: AttackInput, def_in: DefenseInput, cfg: StatsConfig, rng: RandomNumberGenerator) -> Result:
	var hi: float = max_base(atk.primary, atk.secondary, atk.attack) * atk.skill_pct / 100.0
	var mastery: float = clampf(cfg.mastery_base + atk.mastery_bonus, 0.1, 0.9)
	var dmg: float = rng.randf_range(hi * mastery, hi)
	var crit: bool = rng.randf() < atk.crit_rate
	if crit:
		dmg *= cfg.crit_multiplier
	dmg -= float(def_in.defense) * cfg.defense_factor
	var gap: int = maxi(def_in.level - atk.level, 0)
	dmg *= maxf(0.1, 1.0 - float(gap) * cfg.level_diff_damage_penalty_per_level)
	return Result.new(maxi(1, roundi(dmg)), crit)
```

### 9.19 Inventory model (pure logic, used by the Inventory component)

`game/sim/items/inventory_model.gd`
```gdscript
class_name InventoryModel
extends RefCounted
## Tabbed slot inventory with stacking. Pure logic: no nodes, fully testable.

var slots_per_tab: int = Const.INVENTORY_SLOTS_PER_TAB
var tabs: Dictionary = {}   # Const.InvTab -> Array (ItemInstance or null)


func _init(p_slots: int = Const.INVENTORY_SLOTS_PER_TAB) -> void:
	slots_per_tab = p_slots
	for t: int in [Const.InvTab.EQUIP, Const.InvTab.USE, Const.InvTab.ETC]:
		var arr: Array = []
		arr.resize(slots_per_tab)
		tabs[t] = arr


## Adds qty of item_id; returns the quantity that did NOT fit (0 = all added).
func add(item_id: StringName, qty: int, stack_max: int, tab: int, uid_factory: Callable) -> int:
	var arr: Array = tabs[tab]
	var remaining: int = qty
	if stack_max > 1:
		for inst: Variant in arr:
			if remaining == 0:
				break
			if inst != null and (inst as ItemInstance).item_id == item_id:
				var it: ItemInstance = inst
				var space: int = stack_max - it.qty
				var moved: int = mini(space, remaining)
				it.qty += moved
				remaining -= moved
	for i: int in arr.size():
		if remaining == 0:
			break
		if arr[i] == null:
			var put: int = mini(remaining, maxi(stack_max, 1))
			arr[i] = ItemInstance.create(String(uid_factory.call()), item_id, put)
			remaining -= put
	return remaining


func count(item_id: StringName) -> int:
	var total: int = 0
	for t: int in tabs.keys():
		for inst: Variant in tabs[t]:
			if inst != null and (inst as ItemInstance).item_id == item_id:
				total += (inst as ItemInstance).qty
	return total


func free_slots(tab: int) -> int:
	return (tabs[tab] as Array).count(null)
```
`ItemInstance` = `{uid: String, item_id: StringName, qty: int, upgrades: int, rolled: Dictionary}` with `to_dict()/from_dict()`.

### 9.20 Persistence: character record + storage

`game/sim/persistence/character_record.gd`
```gdscript
class_name CharacterRecord
extends RefCounted
## The single save shape used by local saves, the server, and the backend internal API.

const RECORD_VERSION: int = 1

var character_id: int = 0
var name: String = ""
var class_id: StringName = &"novice"
var level: int = 1
var exp: int = 0
var stats: Dictionary = {"str": 4, "dex": 4, "int": 4, "luk": 4}
var ap: int = 0
var sp: int = 0
var hp: int = 50
var mp: int = 5
var currency: int = 0
var map_id: StringName = &"town_bramblewick"
var spawn_portal: StringName = &"spawn"
var skills: Dictionary = {}
var inventory: Dictionary = {"equip": [], "use": [], "etc": []}
var equipped: Dictionary = {}
var quests: Dictionary = {}
var keybinds: Dictionary = {}
var save_version: int = 0


static func new_default(char_name: String) -> CharacterRecord:
	var r := CharacterRecord.new()
	r.name = char_name
	r.skills = {"novice_strike": 1}
	return r


func to_dict() -> Dictionary:
	return {
		"record_version": RECORD_VERSION, "character_id": character_id, "name": name,
		"class_id": String(class_id), "level": level, "exp": exp, "stats": stats.duplicate(),
		"ap": ap, "sp": sp, "hp": hp, "mp": mp, "currency": currency,
		"map_id": String(map_id), "spawn_portal": String(spawn_portal),
		"skills": skills.duplicate(), "inventory": inventory.duplicate(true),
		"equipped": equipped.duplicate(true), "quests": quests.duplicate(true),
		"keybinds": keybinds.duplicate(), "save_version": save_version,
	}


static func from_dict(raw: Dictionary) -> CharacterRecord:
	var d: Dictionary = RecordMigrations.upgrade(raw)
	var r := CharacterRecord.new()
	r.character_id = int(d.get("character_id", 0))
	r.name = String(d["name"])
	r.class_id = StringName(d.get("class_id", "novice"))
	r.level = int(d.get("level", 1))
	r.exp = int(d.get("exp", 0))
	r.stats = d.get("stats", r.stats)
	r.ap = int(d.get("ap", 0))
	r.sp = int(d.get("sp", 0))
	r.hp = int(d.get("hp", 50))
	r.mp = int(d.get("mp", 5))
	r.currency = int(d.get("currency", 0))
	r.map_id = StringName(d.get("map_id", "town_bramblewick"))
	r.spawn_portal = StringName(d.get("spawn_portal", "spawn"))
	r.skills = d.get("skills", {})
	r.inventory = d.get("inventory", r.inventory)
	r.equipped = d.get("equipped", {})
	r.quests = d.get("quests", {})
	r.keybinds = d.get("keybinds", {})
	r.save_version = int(d.get("save_version", 0))
	return r
```

`game/sim/persistence/character_storage.gd` + `local_file_storage.gd`
```gdscript
class_name CharacterStorage
extends RefCounted
## Storage interface. Callers ALWAYS `await` these (BackendStorage is async HTTP).

func load_character(_character_id: int) -> CharacterRecord:
	push_error("not implemented")
	return null


func save_character(_record: CharacterRecord) -> bool:
	push_error("not implemented")
	return false
```
```gdscript
class_name LocalFileStorage
extends CharacterStorage
## Single-player saves in user://saves/char_<id>.json. Atomic write (tmp + rename).

const DIR := "user://saves"


func load_character(character_id: int) -> CharacterRecord:
	var path: String = "%s/char_%d.json" % [DIR, character_id]
	if not FileAccess.file_exists(path):
		return null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		Log.error("save", "Corrupt save %s; keeping .bak if present" % path)
		return null
	return CharacterRecord.from_dict(parsed)


func save_character(record: CharacterRecord) -> bool:
	DirAccess.make_dir_recursive_absolute(DIR)
	record.save_version += 1
	var path: String = "%s/char_%d.json" % [DIR, record.character_id]
	var tmp: String = path + ".tmp"
	var f: FileAccess = FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		Log.error("save", "Cannot open %s: %s" % [tmp, error_string(FileAccess.get_open_error())])
		return false
	f.store_string(JSON.stringify(record.to_dict(), "\t"))
	f.close()
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(path, path + ".bak")
	return DirAccess.rename_absolute(tmp, path) == OK
```

### 9.21 Client prediction & interpolation

`game/client/prediction/predictor.gd`
```gdscript
class_name Predictor
extends RefCounted
## Client-side prediction for the local player + reconciliation against server snapshots.

var motor: MovementMotor
var pending: Array[InputFrame] = []


func _init(p_motor: MovementMotor) -> void:
	motor = p_motor


func apply_local(frame: InputFrame) -> void:
	motor.step(frame, NetConfig.TICK_DT)
	pending.append(frame)
	if pending.size() > NetConfig.MAX_PENDING_INPUTS:
		pending.pop_front()


## Rewinds to the authoritative state, replays unacknowledged inputs.
## Returns the positional correction (new - old) so the view can smooth it.
func reconcile(last_processed_seq: int, server_state: MotorState) -> Vector2:
	var before: Vector2 = motor.entity.global_position
	while not pending.is_empty() and pending[0].seq <= last_processed_seq:
		pending.pop_front()
	motor.restore(server_state)
	for f: InputFrame in pending:
		motor.step(f, NetConfig.TICK_DT)
	return motor.entity.global_position - before
```

`game/client/prediction/interpolation_buffer.gd`
```gdscript
class_name InterpolationBuffer
extends RefCounted
## Buffers timestamped positions for a remote entity and samples them in the past.

const MAX_SAMPLES: int = 32
const MAX_EXTRAPOLATE_S: float = 0.1

var _times: PackedFloat64Array = PackedFloat64Array()
var _positions: PackedVector2Array = PackedVector2Array()


func push(server_time: float, pos: Vector2) -> void:
	if not _times.is_empty() and server_time <= _times[_times.size() - 1]:
		return   # out of order / duplicate
	_times.append(server_time)
	_positions.append(pos)
	if _times.size() > MAX_SAMPLES:
		_times.remove_at(0)
		_positions.remove_at(0)


func sample(render_time: float) -> Vector2:
	var n: int = _times.size()
	if n == 0:
		return Vector2.ZERO
	if render_time <= _times[0]:
		return _positions[0]
	for i: int in range(n - 1):
		if render_time >= _times[i] and render_time <= _times[i + 1]:
			var t: float = (render_time - _times[i]) / maxf(_times[i + 1] - _times[i], 0.0001)
			return _positions[i].lerp(_positions[i + 1], t)
	if n >= 2:   # extrapolate briefly
		var dt: float = minf(render_time - _times[n - 1], MAX_EXTRAPOLATE_S)
		var vel: Vector2 = (_positions[n - 1] - _positions[n - 2]) / maxf(_times[n - 1] - _times[n - 2], 0.0001)
		return _positions[n - 1] + vel * dt
	return _positions[n - 1]
```

`game/client/input/input_sampler.gd`
```gdscript
class_name InputSampler
extends Node
## Samples keyboard/gamepad each physics tick into an InputFrame and submits it.

var authority: Authority
var predictor: Predictor
var _seq: int = 0
var _jump_was_held: bool = false


func _physics_process(_delta: float) -> void:
	if authority == null or predictor == null:
		return
	_seq += 1
	var f := InputFrame.new()
	f.seq = _seq
	f.move_x = int(Input.get_axis(&"move_left", &"move_right"))
	f.move_y = int(Input.get_axis(&"move_up", &"move_down"))
	var jump_held: bool = Input.is_action_pressed(&"jump")
	if jump_held:
		f.buttons |= InputFrame.BTN_JUMP_HELD
		if not _jump_was_held:
			f.buttons |= InputFrame.BTN_JUMP_PRESSED
	_jump_was_held = jump_held
	predictor.apply_local(f)
	authority.submit_input(f)
```
> Use `roundi()` or a deadzone on analog axes so that a gamepad maps to -1/0/1 consistently.

### 9.22 Server main loop

`game/server/server_main.gd`
```gdscript
extends Node
## Dedicated server root. Owns WorldSim, SessionManager; drives the fixed tick.

@onready var world: WorldSim = $WorldSim
@onready var sessions: SessionManager = $SessionManager

var _shutting_down: bool = false


func _ready() -> void:
	Log.json_lines = true
	Engine.max_fps = NetConfig.TICK_RATE     # don't burn a CPU core spinning _process
	world.seed_rng(Config.rng_seed)
	sessions.setup(world)
	world.event_emitted.connect(sessions.route_event)
	var err: Error = Net.host(Config.server_port, Config.max_clients)
	if err != OK:
		Log.error("server", "Failed to host on %d: %s" % [Config.server_port, error_string(err)])
		get_tree().quit(1)
		return
	Log.info("server", "Channel %d ready" % Config.channel_id, {"port": Config.server_port, "protocol": Protocol.VERSION})


func _physics_process(_delta: float) -> void:
	if _shutting_down:
		return
	world.step()
	if world.tick % NetConfig.SNAPSHOT_EVERY_TICKS == 0:
		sessions.send_snapshots()
	if world.tick % (NetConfig.TICK_RATE * 60) == 0:
		sessions.autosave_dirty()
	if world.tick % (NetConfig.TICK_RATE * 5) == 0:
		_write_heartbeat()
		if FileAccess.file_exists(Config.data_dir.path_join("shutdown")):
			shutdown()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		shutdown()


func shutdown() -> void:
	if _shutting_down:
		return
	_shutting_down = true
	Log.info("server", "Shutting down: saving all sessions")
	await sessions.save_all_and_kick(Protocol.Disconnect.SERVER_SHUTDOWN)
	get_tree().quit(0)


func _write_heartbeat() -> void:
	var f: FileAccess = FileAccess.open(Config.data_dir.path_join("heartbeat"), FileAccess.WRITE)
	if f:
		f.store_string(str(Time.get_unix_time_from_system()))
```

`game/server/session_manager.gd` (outline: Cursor fills it in during Phases 9–11)
```gdscript
class_name SessionManager
extends Node
## peer_id <-> session (account, character, eid). Handshake, routing, rate limits, saving.

class Session:
	var peer_id: int
	var account_id: int
	var character_id: int
	var eid: int = 0
	var authed: bool = false
	var violations: int = 0
	var intent_bucket: RateLimiter = RateLimiter.new(30, 1.0)
	var chat_bucket: RateLimiter = RateLimiter.new(5, 5.0)

var world: WorldSim
var storage: CharacterStorage
var _by_peer: Dictionary = {}   # int -> Session
var _by_eid: Dictionary = {}    # int -> Session


func setup(p_world: WorldSim) -> void:
	world = p_world
	storage = BackendStorage.new(Config.backend_url, Config.service_token)  # Phase 11; LocalFileStorage before
	Net.peer_joined.connect(_on_peer_joined)
	Net.peer_left.connect(_on_peer_left)
	Net.hello_received.connect(_on_hello)
	Net.inputs_received.connect(_on_inputs)
	Net.intent_received.connect(_on_intent)


func _on_peer_joined(peer_id: int) -> void:
	var s := Session.new()
	s.peer_id = peer_id
	_by_peer[peer_id] = s
	# TODO: kick if not authed within 5 s


func _on_hello(peer_id: int, version: int, ticket: String) -> void:
	var s: Session = _by_peer.get(peer_id)
	if s == null or s.authed:
		return
	if version != Protocol.VERSION:
		Net.kick(peer_id, Protocol.Disconnect.VERSION_MISMATCH)
		return
	var claims: Dictionary = JoinTicket.verify(ticket, Config.ticket_hmac_key)   # HMAC + expiry
	if claims.is_empty():
		Net.kick(peer_id, Protocol.Disconnect.BAD_TICKET)
		return
	# TODO(phase 11): redeem ticket with backend (single-use), load record via storage
	var record: CharacterRecord = await storage.load_character(int(claims["character_id"]))
	s.account_id = int(claims["account_id"])
	s.character_id = record.character_id
	s.eid = world.spawn_player(record, peer_id)
	s.authed = true
	_by_eid[s.eid] = s
	Net.s2c_welcome.rpc_id(peer_id, s.eid, String(record.map_id), world.tick)


func _on_inputs(peer_id: int, frames: Array[InputFrame]) -> void:
	var s: Session = _by_peer.get(peer_id)
	if s and s.authed:
		world.queue_input(s.eid, frames)


func _on_intent(peer_id: int, intent: Intent) -> void:
	var s: Session = _by_peer.get(peer_id)
	if s == null or not s.authed:
		return
	if not s.intent_bucket.try_consume():
		s.violations += 1
		return
	world.handle_intent(s.eid, intent)


func _on_peer_left(peer_id: int) -> void:
	var s: Session = _by_peer.get(peer_id)
	_by_peer.erase(peer_id)
	if s and s.authed:
		_by_eid.erase(s.eid)
		var record: CharacterRecord = world.despawn_player(s.eid)
		await storage.save_character(record)


func route_event(map_id: StringName, event: SimEvent) -> void:
	if event.scope == Protocol.Scope.PLAYER:
		var s: Session = _by_eid.get(event.target_eid)
		if s:
			Net.send_event(s.peer_id, event)
		return
	for s: Session in _by_eid.values():
		if world.map_of(s.eid) == map_id:
			Net.send_event(s.peer_id, event)


func send_snapshots() -> void:
	for s: Session in _by_eid.values():
		Net.send_snapshot(s.peer_id, world.build_snapshot_for(s.eid))


func autosave_dirty() -> void:
	pass  # TODO(phase 11): save sessions whose PlayerEntity.dirty == true


func save_all_and_kick(reason: int) -> void:
	for s: Session in _by_eid.values():
		await storage.save_character(world.export_record(s.eid))
		Net.kick(s.peer_id, reason)
```

`game/shared/util/rate_limiter.gd`
```gdscript
class_name RateLimiter
extends RefCounted
## Token bucket.

var capacity: float
var refill_per_s: float
var _tokens: float
var _last_ms: int


func _init(p_capacity: int, per_seconds: float) -> void:
	capacity = float(p_capacity)
	refill_per_s = capacity / per_seconds
	_tokens = capacity
	_last_ms = Time.get_ticks_msec()


func try_consume(cost: float = 1.0) -> bool:
	var now: int = Time.get_ticks_msec()
	_tokens = minf(capacity, _tokens + float(now - _last_ms) / 1000.0 * refill_per_s)
	_last_ms = now
	if _tokens < cost:
		return false
	_tokens -= cost
	return true
```

### 9.23 Backend service (Phase 11)

**Database schema (Alembic migration 0001)**
```sql
CREATE TABLE accounts (
  id            BIGSERIAL PRIMARY KEY,
  username      CITEXT UNIQUE NOT NULL,          -- requires CREATE EXTENSION citext
  email         CITEXT UNIQUE,
  password_hash TEXT NOT NULL,                   -- argon2id
  is_admin      BOOLEAN NOT NULL DEFAULT FALSE,
  banned_until  TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_login_at TIMESTAMPTZ
);

CREATE TABLE characters (
  id            BIGSERIAL PRIMARY KEY,
  account_id    BIGINT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  name          CITEXT UNIQUE NOT NULL,
  class_id      TEXT NOT NULL,
  level         INT NOT NULL DEFAULT 1,
  exp           BIGINT NOT NULL DEFAULT 0,
  stats         JSONB NOT NULL,
  ap INT NOT NULL DEFAULT 0, sp INT NOT NULL DEFAULT 0,
  hp INT NOT NULL, mp INT NOT NULL,
  currency      BIGINT NOT NULL DEFAULT 0 CHECK (currency >= 0),
  map_id        TEXT NOT NULL, spawn_portal TEXT NOT NULL DEFAULT 'spawn',
  skills        JSONB NOT NULL DEFAULT '{}',
  quests        JSONB NOT NULL DEFAULT '{}',
  keybinds      JSONB NOT NULL DEFAULT '{}',
  save_version  BIGINT NOT NULL DEFAULT 0,
  deleted_at    TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ON characters(account_id);

CREATE TABLE items (
  uid           TEXT PRIMARY KEY,                -- generated by the game server, globally unique
  character_id  BIGINT NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
  item_id       TEXT NOT NULL,
  container     TEXT NOT NULL CHECK (container IN ('equip','use','etc','equipped')),
  slot          TEXT NOT NULL,                   -- slot index or equip slot name
  qty           INT NOT NULL CHECK (qty > 0),
  upgrades      INT NOT NULL DEFAULT 0,
  rolled        JSONB NOT NULL DEFAULT '{}',
  UNIQUE (character_id, container, slot)
);

CREATE TABLE friends (
  character_id  BIGINT REFERENCES characters(id) ON DELETE CASCADE,
  friend_id     BIGINT REFERENCES characters(id) ON DELETE CASCADE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (character_id, friend_id)
);

CREATE TABLE sessions (                          -- one active game session per account
  account_id    BIGINT PRIMARY KEY REFERENCES accounts(id) ON DELETE CASCADE,
  character_id  BIGINT NOT NULL,
  channel_id    INT NOT NULL,
  ticket_nonce  TEXT,
  redeemed_at   TIMESTAMPTZ,
  heartbeat_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE audit_log (
  id BIGSERIAL PRIMARY KEY, at TIMESTAMPTZ NOT NULL DEFAULT now(),
  kind TEXT NOT NULL, actor_character_id BIGINT, data JSONB NOT NULL
);
```

**REST API**
| Method & path | Auth | Purpose |
|---|---|---|
| `POST /auth/register` | none (rate-limited, invite code during alpha) | Create an account |
| `POST /auth/login` | none (rate-limited) | → `{access_token (15 min), refresh_token (30 d)}` |
| `POST /auth/refresh` | refresh token | Rotate tokens |
| `GET /characters` | access JWT | List own characters |
| `POST /characters` | access JWT | Create (name rules, class=novice, starter kit from data) |
| `DELETE /characters/{id}` | access JWT | Soft delete |
| `POST /characters/{id}/join` | access JWT | → `{host, port, ticket}` |
| `GET /worlds` | none | Channel list + population |
| `POST /internal/tickets/redeem` | service token | Single-use check, creates/locks a session |
| `GET /internal/characters/{id}` | service token | Full CharacterRecord JSON |
| `PUT /internal/characters/{id}` | service token | Save the record (transaction; reject a stale `save_version`) |
| `POST /internal/trades/commit` | service token | Atomic item/currency swap between 2 characters |
| `POST /internal/sessions/{account_id}/end` | service token | Release the session lock |
| `GET /healthz` | none | Liveness + DB check |

`backend/app/services/tickets.py`
```python
import base64, hashlib, hmac, json, secrets, time

def _b64(b: bytes) -> str:
    return base64.urlsafe_b64encode(b).rstrip(b"=").decode()

def issue_ticket(key: bytes, account_id: int, character_id: int, channel_id: int, ttl_s: int = 30) -> tuple[str, str]:
    nonce = secrets.token_urlsafe(16)
    payload = {"a": account_id, "c": character_id, "ch": channel_id, "exp": int(time.time()) + ttl_s, "n": nonce}
    body = _b64(json.dumps(payload, separators=(",", ":")).encode())
    sig = _b64(hmac.new(key, body.encode(), hashlib.sha256).digest())
    return f"{body}.{sig}", nonce
```
The Godot side (`game/server/join_ticket.gd`) verifies it with `Crypto.new().hmac_digest(HashingContext.HASH_SHA256, key, body)`, compares in constant time, checks `exp`, and then redeems the nonce through the backend.

`backend/app/main.py`
```python
from fastapi import FastAPI
from app.routers import auth, characters, internal, health

app = FastAPI(title="Skyrope Backend", version="0.1.0")
app.include_router(health.router)
app.include_router(auth.router, prefix="/auth", tags=["auth"])
app.include_router(characters.router, prefix="/characters", tags=["characters"])
app.include_router(internal.router, prefix="/internal", tags=["internal"])
```
Security rules: argon2id (`argon2-cffi`), JWT HS256 with a 32+ byte secret from env, login rate limit (5 per minute per IP+username), internal routes require `Authorization: Bearer $SERVICE_TOKEN` **and** are bound to the Docker network only (no published port for them, or separate router guarded by a network check).

### 9.24 Docker

`docker/gameserver.Dockerfile`
```dockerfile
# ---- build stage: export the dedicated server with Godot headless ----
FROM debian:bookworm-slim AS build
ARG GODOT_VERSION=4.4.1-stable
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates wget unzip \
    && rm -rf /var/lib/apt/lists/*
RUN wget -q "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip" \
    && unzip -q "Godot_v${GODOT_VERSION}_linux.x86_64.zip" \
    && mv "Godot_v${GODOT_VERSION}_linux.x86_64" /usr/local/bin/godot \
    && wget -q "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_export_templates.tpz" \
    && TPL_DIR="/root/.local/share/godot/export_templates/$(echo ${GODOT_VERSION} | tr '-' '.')" \
    && mkdir -p "$TPL_DIR" && unzip -q "Godot_v${GODOT_VERSION}_export_templates.tpz" \
    && mv templates/* "$TPL_DIR/" && rm -rf templates *.tpz *.zip
COPY game/ /src/game/
WORKDIR /src/game
# Import resources first (creates .godot/), then export the "Linux Server" preset.
RUN godot --headless --import --path /src/game || godot --headless --editor --quit --path /src/game
RUN mkdir -p /out && godot --headless --path /src/game --export-release "Linux Server" /out/skyrope_server.x86_64

# ---- runtime stage ----
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates tini \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --uid 10001 skyrope && mkdir -p /data && chown skyrope /data
COPY --from=build /out/ /app/
COPY docker/gameserver-entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh /app/skyrope_server.x86_64
USER skyrope
WORKDIR /app
ENV SKYROPE_DATA_DIR=/data
EXPOSE 7777/udp
ENTRYPOINT ["/usr/bin/tini", "--", "/app/entrypoint.sh"]
```

`docker/gameserver-entrypoint.sh`
```sh
#!/bin/sh
# Translates SIGTERM into a file the server polls, so it can save everyone before exiting.
set -eu
rm -f /data/shutdown
/app/skyrope_server.x86_64 --headless -- --server --port="${SKYROPE_PORT:-7777}" &
PID=$!
trap 'touch /data/shutdown; wait $PID' TERM INT
wait $PID
```

`docker/backend.Dockerfile`
```dockerfile
FROM python:3.12-slim
WORKDIR /app
RUN pip install --no-cache-dir uv
COPY backend/pyproject.toml backend/uv.lock ./
RUN uv sync --frozen --no-dev
COPY backend/ ./
RUN useradd --uid 10002 api && chown -R api /app
USER api
EXPOSE 8080
CMD ["sh", "-c", "uv run alembic upgrade head && uv run uvicorn app.main:app --host 0.0.0.0 --port 8080 --proxy-headers"]
```

`docker/docker-compose.yml`
```yaml
name: skyrope

services:
  postgres:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-skyrope}
      POSTGRES_USER: ${POSTGRES_USER:-skyrope}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?set in .env}
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build:
      context: ..
      dockerfile: docker/backend.Dockerfile
    restart: unless-stopped
    env_file: .env
    environment:
      DATABASE_URL: postgresql+asyncpg://${POSTGRES_USER:-skyrope}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB:-skyrope}
    depends_on:
      postgres:
        condition: service_healthy
    ports:
      - "${BACKEND_BIND:-0.0.0.0}:8080:8080"
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8080/healthz')"]
      interval: 15s
      timeout: 5s
      retries: 5

  gameserver-ch1:
    build:
      context: ..
      dockerfile: docker/gameserver.Dockerfile
      args:
        GODOT_VERSION: ${GODOT_VERSION:-4.4.1-stable}
    restart: unless-stopped
    env_file: .env
    environment:
      SKYROPE_CHANNEL: "1"
      SKYROPE_PORT: "7777"
      SKYROPE_BACKEND_URL: http://backend:8080
    depends_on:
      backend:
        condition: service_healthy
    ports:
      - "7777:7777/udp"
    volumes:
      - gs1data:/data
    stop_grace_period: 30s
    deploy:
      resources:
        limits:
          cpus: "1.5"
          memory: 1g
    healthcheck:
      test: ["CMD-SHELL", "test $$(( $$(date +%s) - $$(cut -d. -f1 /data/heartbeat) )) -lt 30"]
      interval: 15s
      timeout: 3s
      retries: 3
    logging:
      driver: json-file
      options: { max-size: "10m", max-file: "5" }

  db-backup:
    image: prodrigestivill/postgres-backup-local:16
    restart: unless-stopped
    environment:
      POSTGRES_HOST: postgres
      POSTGRES_DB: ${POSTGRES_DB:-skyrope}
      POSTGRES_USER: ${POSTGRES_USER:-skyrope}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      SCHEDULE: "@every 6h"
      BACKUP_KEEP_DAYS: 7
      BACKUP_KEEP_WEEKS: 4
      BACKUP_KEEP_MONTHS: 3
    volumes:
      - ./backups:/backups
    depends_on:
      postgres:
        condition: service_healthy

volumes:
  pgdata:
  gs1data:
```
Add `gameserver-ch2` by copying the ch1 block with `SKYROPE_CHANNEL: "2"`, port `7778:7778/udp`, and volume `gs2data`.

`docker/.env.example`
```dotenv
GODOT_VERSION=4.4.1-stable
POSTGRES_DB=skyrope
POSTGRES_USER=skyrope
POSTGRES_PASSWORD=change-me
JWT_SECRET=generate-with-openssl-rand-hex-32
SKYROPE_SERVICE_TOKEN=generate-with-openssl-rand-hex-32
SKYROPE_TICKET_KEY=generate-with-openssl-rand-hex-32
PUBLIC_GAME_HOST=homelab.tailnet-name.ts.net   # what clients connect to (Tailscale MagicDNS)
BACKEND_BIND=0.0.0.0                           # set to the Tailscale IP to restrict exposure
ALPHA_INVITE_CODE=
```

### 9.25 GUT tests (examples)

`game/.gutconfig.json`
```json
{
  "dirs": ["res://tests/unit/", "res://tests/integration/"],
  "include_subdirs": true,
  "prefix": "test_",
  "suffix": ".gd",
  "log_level": 1,
  "should_exit": true,
  "junit_xml_file": "res://../build/test-results.xml"
}
```

`game/tests/unit/test_damage_formula.gd`
```gdscript
extends GutTest

var cfg: StatsConfig
var rng: RandomNumberGenerator


func before_each() -> void:
	cfg = StatsConfig.new()
	cfg.mastery_base = 0.15
	cfg.crit_multiplier = 1.5
	cfg.defense_factor = 0.5
	cfg.level_diff_damage_penalty_per_level = 0.02
	rng = RandomNumberGenerator.new()
	rng.seed = 1234


func _atk(primary: int, secondary: int, attack: int) -> DamageFormula.AttackInput:
	var a := DamageFormula.AttackInput.new()
	a.level = 10
	a.primary = primary
	a.secondary = secondary
	a.attack = attack
	a.crit_rate = 0.0
	return a


func _def(level: int, defense: int) -> DamageFormula.DefenseInput:
	var d := DamageFormula.DefenseInput.new()
	d.level = level
	d.defense = defense
	return d


func test_max_base_formula() -> void:
	assert_almost_eq(DamageFormula.max_base(50, 20, 40), 88.0, 0.001)


func test_damage_within_range_over_many_rolls() -> void:
	var hi: float = DamageFormula.max_base(50, 20, 40)
	for i: int in 500:
		var r: DamageFormula.Result = DamageFormula.roll(_atk(50, 20, 40), _def(10, 0), cfg, rng)
		assert_between(r.amount, int(floor(hi * 0.15)), int(ceil(hi)))


func test_damage_never_below_one() -> void:
	var r: DamageFormula.Result = DamageFormula.roll(_atk(1, 1, 1), _def(10, 9999), cfg, rng)
	assert_eq(r.amount, 1)


func test_same_seed_same_result() -> void:
	var r1: DamageFormula.Result = DamageFormula.roll(_atk(50, 20, 40), _def(10, 5), cfg, rng)
	rng.seed = 1234
	var r2: DamageFormula.Result = DamageFormula.roll(_atk(50, 20, 40), _def(10, 5), cfg, rng)
	assert_eq(r1.amount, r2.amount)


func test_higher_level_target_reduces_damage() -> void:
	var a := _atk(50, 20, 40)
	var low_total: int = 0
	var high_total: int = 0
	for i: int in 200:
		low_total += DamageFormula.roll(a, _def(10, 0), cfg, rng).amount
		high_total += DamageFormula.roll(a, _def(25, 0), cfg, rng).amount
	assert_lt(high_total, low_total)
```

`game/tests/unit/test_inventory_model.gd`
```gdscript
extends GutTest

var _uid_counter: int = 0


func _uid() -> String:
	_uid_counter += 1
	return "UID%d" % _uid_counter


func test_stacks_into_existing_slot_then_new_slot() -> void:
	var inv := InventoryModel.new(4)
	var factory: Callable = _uid
	assert_eq(inv.add(&"pot_red_small", 80, 100, Const.InvTab.USE, factory), 0)
	assert_eq(inv.add(&"pot_red_small", 50, 100, Const.InvTab.USE, factory), 0)
	assert_eq(inv.count(&"pot_red_small"), 130)
	assert_eq(inv.free_slots(Const.InvTab.USE), 2)


func test_returns_leftover_when_full() -> void:
	var inv := InventoryModel.new(1)
	var leftover: int = inv.add(&"etc_puddlet_drop", 250, 200, Const.InvTab.ETC, _uid)
	assert_eq(leftover, 50)


func test_equips_never_stack() -> void:
	var inv := InventoryModel.new(4)
	inv.add(&"wpn_rusty_sword", 2, 1, Const.InvTab.EQUIP, _uid)
	assert_eq(inv.free_slots(Const.InvTab.EQUIP), 2)
```

`game/tests/integration/test_local_authority_movement.gd` (pattern for sim tests driven by physics frames)
```gdscript
extends GutTest
## Drives a real WorldSim through physics frames: movement must be deterministic.

var sim: WorldSim


func before_each() -> void:
	sim = WorldSim.new()
	sim.seed_rng(42)
	add_child_autofree(sim)


func test_player_falls_and_lands_on_floor() -> void:
	var eid: int = sim.spawn_player(CharacterRecord.new_default("Tester"), 1)
	for i: int in 120:
		var frames: Array[InputFrame] = [InputFrame.neutral(i + 1)]
		sim.queue_input(eid, frames)
		sim.step()
		await wait_physics_frames(1)
	var rec: CharacterRecord = sim.export_record(eid)
	assert_not_null(rec)
	# TODO(phase 1): assert motor state == GROUND and y == floor height from the test map
```
> Sim tests that touch physics **must** step inside physics frames (`await wait_physics_frames(...)`) because direct space state is only safely accessible there. Pure-logic tests (formulas, inventory, leveling) need no frames.

### 9.26 CI: `.github/workflows/ci.yml`
```yaml
name: ci
on:
  push: { branches: [main] }
  pull_request:

jobs:
  data:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: "3.12" }
      - run: pip install jsonschema
      - run: python tools/build_index.py --check
      - run: python tools/validate_data.py

  godot:
    runs-on: ubuntu-latest
    needs: data
    steps:
      - uses: actions/checkout@v4
        with: { lfs: true }
      - name: Read Godot version
        run: echo "GODOT_VERSION=$(cat .godot-version)" >> "$GITHUB_ENV"
      - name: Cache Godot
        uses: actions/cache@v4
        with:
          path: ~/godot
          key: godot-${{ env.GODOT_VERSION }}
      - name: Install Godot + export templates
        run: |
          mkdir -p ~/godot && cd ~/godot
          if [ ! -f godot ]; then
            wget -q "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip"
            unzip -q "Godot_v${GODOT_VERSION}_linux.x86_64.zip" && mv "Godot_v${GODOT_VERSION}_linux.x86_64" godot
            wget -q "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_export_templates.tpz"
          fi
          TPL="$HOME/.local/share/godot/export_templates/$(echo $GODOT_VERSION | tr '-' '.')"
          mkdir -p "$TPL" && unzip -qo Godot_v${GODOT_VERSION}_export_templates.tpz -d /tmp/tpl && cp -r /tmp/tpl/templates/* "$TPL/"
          echo "$HOME/godot" >> "$GITHUB_PATH"
      - name: Import project
        run: godot --headless --import --path game || godot --headless --editor --quit --path game
      - name: Run GUT tests
        run: godot --headless --path game -s addons/gut/gut_cmdln.gd -gexit
      - name: Smoke-run server for 5 seconds
        run: timeout 10 godot --headless --path game --quit-after 300 -- --server --port=7799
      - name: Export server + clients
        run: |
          mkdir -p build/server build/client/linux build/client/windows
          godot --headless --path game --export-release "Linux Server" ../build/server/skyrope_server.x86_64
          godot --headless --path game --export-release "Linux Client" ../build/client/linux/skyrope.x86_64
          godot --headless --path game --export-release "Windows Client" ../build/client/windows/skyrope.exe
      - uses: actions/upload-artifact@v4
        with: { name: builds, path: build/ }

  backend:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16-alpine
        env: { POSTGRES_PASSWORD: test, POSTGRES_DB: skyrope_test }
        ports: ["5432:5432"]
        options: --health-cmd pg_isready --health-interval 5s --health-retries 10
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v3
      - run: cd backend && uv sync && uv run pytest -q
        env: { DATABASE_URL: "postgresql+asyncpg://postgres:test@localhost:5432/skyrope_test" }

  docker:
    runs-on: ubuntu-latest
    needs: [godot, backend]
    steps:
      - uses: actions/checkout@v4
        with: { lfs: true }
      - run: docker build -f docker/gameserver.Dockerfile --build-arg GODOT_VERSION=$(cat .godot-version) -t skyrope-gameserver .
      - run: docker build -f docker/backend.Dockerfile -t skyrope-backend .
```
> The export paths are relative to the project dir (`game/`), hence `../build/...`. `--quit-after` takes **frames/iterations**, not seconds. Pin action versions to whatever is current when Phase 0 starts.

### 9.27 `tools/validate_data.py` (skeleton)
```python
#!/usr/bin/env python3
"""Validate game/data/*.json against JSON Schemas and cross-references. Exit 1 on any error."""
import json, sys
from pathlib import Path
from jsonschema import Draft202012Validator

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

index = load(DATA / "index.json")
ids: dict[str, set[str]] = {}
for category, files in index.items():
    if category == "schema_version":
        continue
    schema_file = SCHEMAS / f"{category}.schema.json"
    validator = Draft202012Validator(load(schema_file)) if schema_file.exists() else None
    for res in (files if isinstance(files, list) else [files]):
        doc = load(res_to_path(res))
        if validator:
            for err in validator.iter_errors(doc):
                errors.append(f"{res}: {'/'.join(map(str, err.path))}: {err.message}")
        for entry in doc.get(category, []) if isinstance(doc, dict) else []:
            if isinstance(entry, dict) and "id" in entry:
                bucket = ids.setdefault(category, set())
                if entry["id"] in bucket:
                    errors.append(f"{res}: duplicate {category} id {entry['id']}")
                bucket.add(entry["id"])
                if "scene" in entry and not res_to_path(entry["scene"]).exists():
                    errors.append(f"{res}: {entry['id']} scene not found {entry['scene']}")

# Cross references (extend per phase)
for res in index.get("mobs", []):
    for mob in load(res_to_path(res)).get("mobs", []):
        if mob.get("drop_table") not in ids.get("drop_tables", set()):
            errors.append(f"mob {mob.get('id')}: unknown drop_table {mob.get('drop_table')}")

if errors:
    print("\n".join(errors))
    sys.exit(1)
print(f"OK: {sum(len(v) for v in ids.values())} definitions validated")
```

### 9.28 `Makefile`
```makefile
GODOT ?= godot
PROJ  := game

.PHONY: import test run server client2 export validate up down logs
import:   ; $(GODOT) --headless --import --path $(PROJ)
test:     ; $(GODOT) --headless --path $(PROJ) -s addons/gut/gut_cmdln.gd -gexit
run:      ; $(GODOT) --path $(PROJ)
server:   ; $(GODOT) --headless --path $(PROJ) -- --server --port=7777
client2:  ; $(GODOT) --path $(PROJ) -- --connect=127.0.0.1:7777 & $(GODOT) --path $(PROJ) -- --connect=127.0.0.1:7777
validate: ; python3 tools/build_index.py --check && python3 tools/validate_data.py
export:   ; mkdir -p build/server && $(GODOT) --headless --path $(PROJ) --export-release "Linux Server" ../build/server/skyrope_server.x86_64
up:       ; docker compose -f docker/docker-compose.yml --env-file docker/.env up -d --build
down:     ; docker compose -f docker/docker-compose.yml --env-file docker/.env down
logs:     ; docker compose -f docker/docker-compose.yml logs -f --tail=200
```

---

## 10. Phased Roadmap (Phase 0 → 17)

Each phase lists: **Goal · Depends on · Deliverables · Tasks · Acceptance criteria (Definition of Done) · Tests · Pitfalls (things that would cause rework)**.
Tasks are ordered. Each one is small enough for a single commit. A task is done only when its code runs, tests pass, and it's committed.

---

### Phase 0: Project setup, tooling, CI, skeleton architecture
**Goal:** An empty-but-correct skeleton: folder structure, autoloads, data loading, Authority pattern wired with LocalAuthority, a test suite running headless locally and in CI. Nothing playable yet, but every architectural seam exists.
**Depends on:** nothing.
**Deliverables:** repo skeleton (§5), `project.godot` configured (§9.1), autoloads (§9.4–9.9), GUT vendored, CI green, `docs/` stubs, `Makefile`.

**Tasks**
- [x] 0.1 Create the folder tree exactly as in §5 (empty dirs get a `.gitkeep`). Add `README.md`, `.gitignore`, `.gitattributes`, `.editorconfig` (tabs for `*.gd`, 2 spaces for json/yaml), `.godot-version`.
- [x] 0.2 Create the Godot project in `game/` with the pinned version. Apply all `project.godot` settings from §9.1 (resolution, stretch, nearest filter, pixel snapping, physics 60 Hz, compatibility renderer, layer names, warnings-as-errors for untyped declarations).
- [x] 0.3 Vendor GUT into `game/addons/gut/` (the release that matches the pinned Godot version). Enable the plugin. Add `.gutconfig.json` (§9.25). Add `tests/unit/test_sanity.gd` with one passing assertion.
- [x] 0.4 Implement `Log` (§9.5) and `Config` (§9.6) autoloads. Unit-test `Config._parse_args()` with `--server`, `--port=`, `--connect=host:port`, `--seed=`.
- [x] 0.5 Implement `shared/constants.gd`, `shared/net/net_config.gd`, `shared/net/protocol.gd`, `shared/util/id_allocator.gd`, `shared/util/rate_limiter.gd`, `shared/util/ring_buffer.gd`, with tests for IdAllocator, RateLimiter and RingBuffer.
- [x] 0.6 Implement `BaseDef`, `StatsConfig`, `MobDef`, `SkillDef`, and `DataRegistry` (§9.9). Create a minimal `data/index.json`, `stats.json`, `level_table.json`, and one mob + one skill. Test: registry loads, duplicate IDs error, missing files error, and `level_value` interpolation.
- [x] 0.7 Write `tools/build_index.py` (with `--check` mode that fails if index.json is stale), `tools/validate_data.py` (§9.27), and JSON Schemas for `stats`, `level_table`, `mobs`, `skills`.
- [x] 0.8 Implement `EventBus` (§9.7) and stubs for `GameState`, `AudioManager`, `SceneRouter` that early-return on the server.
- [x] 0.9 Implement `Intent`, `SimEvent`, `InputFrame`, `Codec` (inputs only for now), `MotorState` encode/decode. Round-trip tests for every wire type.
- [x] 0.10 Implement the `Authority` base and `LocalAuthority` (§9.12), plus `WorldSim` and `MapInstance` skeletons (§9.13) that can load an **empty test map** (`content/maps/map_test_flat.tscn`: a single flat `TileMapLayer` floor using a 1-tile placeholder TileSet with collision).
- [x] 0.11 Implement `boot/boot.tscn` + `boot.gd` (§9.4), `client/client_main.tscn` (creates a LocalAuthority and logs `entered_map`), and `server/server_main.tscn` (hosts ENet, logs "ready", no gameplay).
- [x] 0.12 Add `Makefile` (§9.28). Verify `make test`, `make run` (window opens on a grey screen with the test floor), and `make server` (logs ready, exits cleanly on Ctrl+C).
- [x] 0.13 Create export presets "Linux Client", "Windows Client", "Linux Server" (§9.2), with `include_filter` for JSON. Verify a local server export runs and finds its data.
- [x] 0.14 Add `.github/workflows/ci.yml` (§9.26: data + godot jobs for now). Make CI green.
- [x] 0.15 Create `docs/DECISIONS.md` with the initial decisions from §14.2, plus `docs/CHANGELOG.md`, `docs/ASSET_CREDITS.md`, `docs/CONTENT_GUIDE.md` (stub), `docs/PROTOCOL.md` (copy §15.1).

**Acceptance criteria**
- `make test` passes locally. CI is green on `main`.
- `godot --path game` opens a window (LOCAL mode) and logs that it entered `map_test_flat` with an eid.
- `godot --headless --path game -- --server` logs JSON lines including "Channel 1 ready".
- The exported Linux server binary starts and loads data (proves `include_filter` works).
- No script warnings in the Output panel on startup.

**Tests:** Config arg parsing; IdAllocator; RateLimiter; RingBuffer; DataRegistry load/duplicate/missing; level_value; wire round-trips (Intent, SimEvent, InputFrame, MotorState, input batch).

**Pitfalls**
- Forgetting the JSON `include_filter` means exported builds have no data. Test the export in this phase, not in Phase 16.
- Putting the Godot project at the repo root makes Godot import backend/tool files and slows down the editor. Keep it in `game/`.
- Using `DirAccess` to find data files works in the editor but fails in exports. Use `index.json`.
- If the pinned version complains about passing array literals to `Array[T]` parameters, build typed arrays explicitly (`var a: Array[InputFrame] = [f]`).
- Don't add `MultiplayerSpawner`/`MultiplayerSynchronizer` nodes "for later". The architecture uses custom snapshots.
- Official Godot 4.7.x Linux x86_64 binaries require SSE4.2 and abort on older lab CPUs. Wrap with `qemu-x86_64-static -cpu max` (`scripts/install-cloud-env.sh`).
- `CharacterRecord.new_default` must use `map_test_flat` until Phase 5 town maps exist (D-018).

---

### Phase 1: Core movement & physics
**Goal:** The player character moves with genre-faithful feel: run, jump, one-way platforms with drop-through, ropes and ladders, all through the shared `MovementMotor` driven by `InputFrame`s and rendered by a client view with prediction plumbing in place (zero latency in LOCAL).
**Depends on:** Phase 0.
**Deliverables:** `PlayerEntity` (sim), `MovementMotor` + `ClimbQuery` (§9.15), `PlayerView` (client), `InputSampler` + `Predictor` (§9.21), `Keybinds`, a movement test map, `FollowCamera` (basic).

**Tasks**
- [x] 1.1 Create a placeholder TileSet (16×16 tiles, generated colored squares) with two physics layers: solid (layer `world`) and one-way (layer `platform_oneway`, one-way collision enabled on the tile polygons).
- [x] 1.2 Build `content/maps/map_test_movement.tscn`: a ground `TileMapLayer` ("Ground"), a `TileMapLayer` named "Platforms" in group `oneway_platforms` with 3–4 stacked one-way platforms, 1 rope and 1 ladder (`Area2D` on layer `climbable` with a tall `CollisionShape2D`, script `climbable.gd` exporting `kind: rope|ladder`), walls at the map edges, and a `Marker2D` named `spawn` in group `portals`. Add its `maps/*.json` entry.
- [x] 1.3 Implement `Entity` and `Component` (§9.14) and `PlayerEntity` (`CharacterBody2D`, capsule ~12×28, layer `player_body`, mask `world | platform_oneway`), with `InputQueue` (jitter buffer: `push_frames`, `pop_for_tick`, `last_processed_seq`, repeat-last-input up to 6 ticks).
- [x] 1.4 Implement `MovementMotor` platformer state: accel/decel, gravity, max fall, jump with coyote time and jump buffer, facing. All tunables are `@export`s, with defaults also mirrored in `data/stats.json` → `movement` block.
- [x] 1.5 Implement drop-through: Down + Jump while standing on a node in group `oneway_platforms` disables the one-way mask for `drop_through_ticks`. Ensure solid ground can't be dropped through.
- [x] 1.6 Implement `ClimbQuery` and the climb state: Up/Down near a climbable grabs it (snap x to the climbable's x), moves vertically at `climb_speed`, Jump + Left/Right jumps off, climbing past the top steps onto the platform above, and climbing down onto ground exits. Platforms are ignored while climbing.
- [x] 1.7 Implement `MotorState` capture/restore (§9.15) including the collision-mask state. Test that capture → step N → restore → step N yields identical positions (determinism test).
- [x] 1.8 Implement `client/input/keybinds.gd` registering default actions (§15.3) via `InputMap` at startup, plus `InputSampler` producing `InputFrame`s with jump edge detection.
- [x] 1.9 Implement the client world view: `client_main` loads the same map scene for visuals + collision, spawns a **local predicted** `PlayerEntity` copy driven by `Predictor`, and a `PlayerView` (placeholder sprite: a colored rectangle with a "facing" nose and simple animation states idle/walk/jump/fall/climb via `AnimatedSprite2D` with generated frames) that follows the predicted body.
- [x] 1.10 Wire reconciliation in LOCAL mode: on each snapshot, `Predictor.reconcile(last_processed_seq, self_state)`. Add a debug counter for corrections > 1 px (should be ~0 in LOCAL).
- [x] 1.11 Add a basic `FollowCamera` (Camera2D with position smoothing, limits from the map JSON `bounds`).
- [x] 1.12 Add the F3 debug overlay (client-only): FPS, tick, motor state, position, velocity, pending inputs, correction count.
- [x] 1.13 Tune feel: walk speed, jump height (~3.5 tiles), fall speed, rope speed. Record the final values in `stats.json` and in the Decision Log ("Movement feel v1").

**Acceptance criteria**
- You can walk, jump, land on one-way platforms from below, drop through them with Down+Jump, and can't drop through solid ground.
- You can grab a rope/ladder with Up (from below) or Down (from the platform top), climb, jump off sideways, and step onto the platform at the top.
- LOCAL-mode reconciliation corrections are 0 (or < 0.01 px) over 2 minutes of play (debug overlay).
- The determinism test passes: replaying the same 600-frame input script twice from the same state gives identical final positions.
- No movement code exists in `client/` other than calling `Predictor`/`InputSampler`.

**Tests:** InputFrame edge bits; InputQueue jitter behavior (missing frames, duplicates, out-of-order); motor determinism (scripted input playback); jump height within ±2 px of target; drop-through only on one-way; climb enter/exit transitions (integration, physics frames).

**Pitfalls**
- Using `Area2D.body_entered` for ropes breaks re-simulation. Use `ClimbQuery` (direct space queries).
- Using `Timer` nodes or `delta` accumulation for coyote/jump buffer breaks determinism. Use tick counters.
- Calling `move_and_slide()` from `_process` instead of the sim tick.
- Letting the view's sprite position *be* the body position. The view must be a separate node that can be smoothed independently of corrections.
- Hard-coding the player's spawn. It must come from the map's marker.
- `CharacterBody2D.floor_snap_length` and `floor_max_angle` matter for slopes. Decide now: **no slopes in MVP** (flat platforms only; record in the Decision Log), or tune snap carefully.

---

### Phase 2: Combat & mobs
**Goal:** Fight respawning mobs with a basic attack. Server-authoritative hit resolution (in LocalAuthority), damage numbers, knockback, mob death and despawn. No loot or EXP yet (just events).
**Depends on:** Phase 1.
**Deliverables:** `HealthComponent`, `StatsComponent`, `Hurtbox`, `HitQuery`, `CombatResolver`, `DamageFormula`, `MobEntity` + `MobBrain`, `Spawner`, player action state machine, `MobView`, damage numbers, HP bars.

**Tasks**
- [ ] 2.1 Implement `StatsComponent` and `HealthComponent` (§9.14), plus `StatsConfig` fields used by the damage formula.
- [ ] 2.2 Implement `DamageFormula` (§9.18) with full unit tests (§9.25).
- [ ] 2.3 Implement `Hurtbox` and `HitQuery` (§9.14). Player hurtbox on layer `player_hurtbox`, mob hurtbox on `mob_hurtbox`.
- [ ] 2.4 Implement `TickStateMachine` + `IdleState`, `CastingState`, `HurtState`, `DeadState` (§9.16) on `PlayerEntity`. `PlayerEntity.try_cast(intent)` validates (state can act, skill known, cooldown ready, MP) and transitions to Casting, or rejects with a reason.
- [ ] 2.5 Add `novice_strike` (basic attack) to `skills/novice.json`. `CombatResolver.resolve_skill_hit()` → `HitQuery` → `DamageFormula` → `HealthComponent.apply_damage` → emit `DAMAGE` events `[attacker_eid, target_eid, amount, crit, hit_index]`.
- [ ] 2.6 Implement `MobEntity` (`CharacterBody2D`, layer `mob_body`, mask `world | platform_oneway`; mobs never collide with players physically) with `MobBrain` (§9.17): patrol edge-to-edge, idle pauses, flinch on hit, aggro → chase on the same platform, `mob_wall` respect.
- [ ] 2.7 Contact damage: each tick, mobs with `contact_damage` query overlapping player hurtboxes. On overlap, damage the player (mob attack vs player defense), apply knockback away from the mob, and grant invincibility ticks (`invincibility_after_hit_s`). The player enters `HurtState` briefly.
- [ ] 2.8 Implement mob death: `DIED` event, despawn after a 30-tick death animation window, and the `Spawner` (per `spawns[]` entry: marker group, `max_alive`, `respawn_ticks`, random marker selection via sim RNG).
- [ ] 2.9 Implement `EntityState` + full snapshot encoding/decoding (§9.10) with mob anim/facing/hp_pct. The client `WorldView` spawns/despawns `MobView`s from snapshots and interpolates them with `InterpolationBuffer` (in LOCAL too).
- [ ] 2.10 Client feedback: `PlayerView` plays the attack animation immediately when the attack key is pressed (cosmetic), and the client sends `Intent.cast`. On `INTENT_REJECTED`, cancel the cosmetic animation. Floating damage numbers (pooled, stacked upward for multi-hits, distinct crit style), mob HP bar shown for 3 s after damage, hit flash, 2–3 frame hit-stop on the attacker's view only.
- [ ] 2.11 Player death: HP 0 → `DeadState` → "Respawn" prompt → `RESPAWN` intent → respawn at the map's `return_map` spawn with 50% HP (EXP penalty comes in Phase 3).
- [ ] 2.12 Add 2 mob types to data (`puddlet`: patrol, aggro on hit; `capshroom`: patrol, aggro on sight, jumps) with placeholder views. Add them to the test map with spawners.

**Acceptance criteria**
- Pressing attack near a mob damages it. Damage numbers appear and the HP bar drops. Mobs flinch, chase, and die, then respawn after their timer.
- Touching a mob hurts the player, with knockback and blink invincibility. The player can die and respawn.
- All damage values come from `DamageFormula` + data. Changing `weapon_attack` in JSON changes damage without code changes.
- With `--codec-roundtrip`, all intents and events still work (serialization-safe).
- No hit detection happens in `client/` (grep check: no `intersect_shape` under `client/`).

**Tests:** DamageFormula (range, min 1, crit, defense, level gap, seed determinism); HealthComponent (invuln, death once, heal cap, MP spend); CastingState timing (hit fires exactly at hit_tick, returns to idle at cast_ticks); HitQuery max_targets and nearest-first ordering (integration); Spawner keeps `max_alive` and respects respawn time; snapshot encode/decode with 70 entities stays < 1,000 bytes.

**Pitfalls**
- Resolving hits with `Area2D` signals adds a frame of latency and doesn't work for instant queries. Use `HitQuery`.
- Letting mobs physically block players: the genre uses pass-through, and blocking makes prediction diverge. Keep mobs off the player's collision mask.
- Firing damage from the animation (`AnimationPlayer` method tracks). The sim decides timing via ticks, and the view just animates.
- Global `randf()` in combat makes tests and replays flaky. Use `sim.rng`.
- Forgetting to remove dead mobs from `MapInstance.entities` (memory leak, ghost hits).

---

### Phase 3: RPG systems (stats, leveling, AP/SP, classes, skills)
**Goal:** Kills give EXP. Levels raise HP/MP and grant AP/SP. Stats affect combat. One job advancement from Novice to 4 classes. Skills with levels, MP costs, cooldowns and buffs.
**Depends on:** Phase 2.
**Deliverables:** `Leveling`, `ExpDistributor`, `ClassDef`, AP/SP allocation intents, skill system (active, buff, passive, projectile), job advancement (data + intent), level table.

**Tasks**
- [ ] 3.1 `ClassDef` + `classes.json` (novice + vanguard/arcanist/ranger/shade) + schema. `StatsComponent` uses class primary/secondary stats.
- [ ] 3.2 `Leveling` (pure): `add_exp(level, exp, amount, table) -> {level, exp, levels_gained}`, with multi-level-ups and a max-level cap. HP/MP growth per level rolled from `base_hp_per_level` ranges with sim RNG. Emit `EXP_GAINED`, `LEVEL_UP`, `STATS_CHANGED`, `VITALS_CHANGED`.
- [ ] 3.3 `ExpDistributor`: on mob death, split EXP among damagers proportional to damage dealt (tracked per mob in a `damage_ledger`). Party sharing is a hook only (Phase 12).
- [ ] 3.4 AP/SP: `+ap_per_level` and `+sp_per_level` (from `stats.json`). Intents `ALLOC_AP(stat)` and `ALLOC_SP(skill_id)`, validated (has points, skill belongs to the class or ancestors, prerequisites met, below max level).
- [ ] 3.5 Death EXP penalty (`death_exp_loss_pct` of the current level's requirement, never de-levels; towns are exempt via map flag).
- [ ] 3.6 Skill types: `active_attack` (multi-hit, multi-target, `hits` with spaced damage events), `projectile` (`ProjectileEntity` moving per tick with a lifetime, resolving hits on mob hurtboxes), `buff` (adds to `StatsComponent.buff_bonus` for N ticks, via a `Buffs` component), `passive` (permanent bonus when learned).
- [ ] 3.7 `Cooldowns` component (tick counters per skill_id). Reject casts during cooldown with `Reject.COOLDOWN`.
- [ ] 3.8 HP/MP natural regen every `*_regen_interval_s` (more when standing still: genre convention).
- [ ] 3.9 Job advancement: an intent via NPC dialogue action `job_advance` (Phase 7 hooks it up; for now a debug command `/advance vanguard` in LOCAL debug builds only), validated against `advance_requirements`. Class change emits `STATS_CHANGED` and grants first-job skills at level 0 with SP.
- [ ] 3.10 Author first-job skills: 3–4 per class (one basic attack upgrade, one AoE/multi-hit or projectile, one buff, one passive) in `skills/<class>.json`, with schema validation.
- [ ] 3.11 Projectile and buff views: projectile sprite interpolated from snapshots, buff icon events.
- [ ] 3.12 `tools/gen_level_table.py`: curve-based generator. Generate levels 1–70 and commit.

**Acceptance criteria**
- Killing mobs grants EXP. The level-up event fires, HP/MP max increase, AP/SP are granted, and allocating AP changes damage measurably.
- Advancing to each class grants the correct skills. Each skill works: multi-hit shows stacked damage numbers, projectiles travel and hit, and buffs raise damage for their duration then expire.
- Cooldowns and MP costs are enforced by the sim (rejections visible in the debug log).
- Balance check: a fresh Novice can kill a Puddlet in 3–5 hits (record the tuning in `docs/DECISIONS.md`).

**Tests:** Leveling (exact thresholds, multi-level, cap); EXP split proportional with rounding that conserves the total; AP/SP validation (all reject reasons); Buff apply/expire restores stats exactly; Cooldowns; skill level interpolation; job advance requirement checks.

**Pitfalls**
- Storing derived stats in the save file. Save base stats + AP spent. Derive everything else (otherwise balance patches don't apply).
- Letting the client compute "can I cast?" for gameplay. The client may grey out buttons using `GameState`, but the sim decides.
- Skill effects as bespoke code per skill. Keep the 4 generic skill types with data parameters. Add new *types* only when a skill can't be expressed.
- Floats in EXP/currency. Always use `int`.

---

### Phase 4: Items, inventory, equipment, drops, currency
**Goal:** Mobs drop currency (Glimmer) and items that bounce out. Pick up with Z. Tabbed inventory with stacking, use items (potions), equip gear that changes stats, drop/discard items, sell/buy hooks for Phase 7.
**Depends on:** Phase 3.
**Deliverables:** `ItemDef` (+ schema), `ItemInstance`, `InventoryModel` (§9.19), `Inventory` component, `Equipment`, `LootRoller`, `DropEntity`, item intents, inventory events.

**Tasks**
- [ ] 4.1 `ItemDef` with categories equip/use/etc, `items/*.json` + schema (slot, weapon_type, reqs, stats, stack_max, prices, effect). At least 20 starter items.
- [ ] 4.2 `ItemInstance` + uid generation (`sim.rng`-based 16-char base32 in tests; `Crypto.generate_random_bytes` in production, behind an injectable factory).
- [ ] 4.3 `InventoryModel` (§9.19) + `Inventory` component: add, remove by uid/qty, move/swap slots, split stack, count, free slots. Emits `INVENTORY_CHANGED` with only the changed slots (delta, not the full inventory).
- [ ] 4.4 `Equipment`: slots (weapon, hat, top, bottom, shoes, gloves, + reserved: cape, earring, ring). `EQUIP`/`UNEQUIP` intents validate class, level and stat requirements, swap with the inventory atomically, and recompute `equip_bonus`.
- [ ] 4.5 `USE_ITEM`: potions (heal HP/MP), with a per-item cooldown. Return scroll (warp to `return_map`).
- [ ] 4.6 `DropTableDef` + `LootRoller` (pure): independent rolls per entry, currency roll, quest-only entries filtered by the looter's active quests.
- [ ] 4.7 `DropEntity`: spawned on mob death with a small pop-up arc (velocity), lands on platforms, stores `owner_eid`/`party_id` + `claim_until_tick` + `expire_tick`. Item and currency drop variants.
- [ ] 4.8 `PICKUP` intent: nearest pickable drop within 48 px (the client sends a specific drop eid when known, otherwise `0` = nearest). Validate claim window and inventory space. Emit `ITEM_GAINED`/`CURRENCY_CHANGED`, then despawn the drop.
- [ ] 4.9 `DROP_ITEM` intent (drops an item instance on the ground as a DropEntity with no claim window. Untradeable items are destroyed instead, with confirmation in the UI later). Drop currency amount.
- [ ] 4.10 Currency is an `int` on PlayerEntity with a max cap (e.g. 2,000,000,000). All changes go through `CurrencyService.add/try_spend`, which emit events.
- [ ] 4.11 Client views: `DropView` (icon bobbing, rarity glow), pickup sound hook, system chat messages ("You picked up Small Red Tonic x2").

**Acceptance criteria**
- Killing mobs scatters drops. Z picks up the nearest one and inventory and currency update via events. Full inventory rejects the pickup (with a message).
- Equipping a weapon changes damage. Requirements are enforced. Unequip with a full inventory is rejected.
- Potions heal and respect cooldowns. Drops disappear after 60 s. Other players' claimed drops can't be taken during the claim window (tested in the sim with 2 players).
- Item uids are unique across 100k generated items (test).

**Tests:** InventoryModel (stacking, splitting, move/swap, leftover, removal by uid); equip validation (each requirement); LootRoller distribution (seeded, chance ± tolerance over 10k rolls); claim window logic; currency cap and overflow; uid uniqueness.

**Pitfalls**
- Representing items as just `item_id + qty` without uids makes duplication bugs undetectable later and complicates trades and DB rows.
- Sending the full inventory on every change. Send deltas, plus a `FULL_STATE` on join/map change.
- Letting the client pick up by position. The server finds the drop and validates distance.
- Putting item stat bonuses into base stats. Keep `equip_bonus` separate so unequip restores exactly.

---

### Phase 5: Maps, portals, tilemaps, parallax, camera
**Goal:** Multiple real maps (town + fields + dungeon) connected by portals with transitions. Proper tilesets, parallax backgrounds, camera bounds. Per-map sim instances (World2D per map).
**Depends on:** Phase 4.
**Deliverables:** `MapDef` (+ schema), map authoring conventions, `PortalMarker`, `WorldSim.transfer_player`, fade transitions, parallax, the Bramblewick town + 3 fields + 1 dungeon (placeholder art OK).

**Tasks**
- [ ] 5.1 `MapDef` + schema: id, name, scene, bounds, music, return_map, spawns, portals, npcs, flags (town, pvp, allow_teleport, no_exp_loss).
- [ ] 5.2 Map authoring conventions (document in `docs/CONTENT_GUIDE.md`): node names `Ground`, `Platforms` (group `oneway_platforms`), `Decor` (no collision), `Climbables/`, `Portals/` (Marker2D + `PortalArea` on layer `portal`), `Spawns/<group>/`, `NpcMarkers/`, `MobWalls/`, `Background` (`Parallax2D` layers in 4.3+, else `ParallaxBackground`). Tile size 16 px.
- [ ] 5.3 `ENTER_PORTAL` intent (Up near a portal): validate overlap via a space query → `WorldSim.transfer_player(eid, to_map, to_portal)`, which removes the entity from the old MapInstance, spawns it in the new one (**keep the same eid** for simplicity), and emits `MAP_CHANGED` (scope PLAYER) + `FULL_STATE`.
- [ ] 5.4 Verify per-map physics isolation: two MapInstances loaded at once, with entities at the same coordinates in different maps never interacting (integration test).
- [ ] 5.5 Map lifecycle: lazy load on first entry, unload after N minutes with 0 players (server only; LOCAL unloads immediately on leave).
- [ ] 5.6 Client map transition: fade out → free old map view + entity views → load the new map scene → reset Predictor and interpolation buffers → fade in. Input is blocked during the transition.
- [ ] 5.7 `FollowCamera`: limits from `bounds`, look-ahead in the facing direction, vertical dead zone (doesn't jitter on small jumps), snaps instantly on map change.
- [ ] 5.8 Parallax background per map (2–4 layers), and a map name banner on entry.
- [ ] 5.9 Build maps: `town_bramblewick` (safe zone, NPC markers, 3 portals), `field_01..03` (increasing level ranges), `dungeon_01` (darker, mini-boss spawn marker). Spawns and portals in JSON.
- [ ] 5.10 `tools/validate_data.py`: check that every portal target map/portal exists, every map scene exists, and every spawn marker group exists in the scene (parse `.tscn` text for node names and groups).
- [ ] 5.11 Minimap (client): render a simplified map outline from TileMapLayer used cells into an `ImageTexture` once per map load, plus the player dot. Other players and NPC dots come later.

**Acceptance criteria**
- Walk from town → field_01 → field_02 → back, through portals with fades. Mobs persist per map. The camera never shows outside bounds.
- Two maps loaded simultaneously don't share physics (test passes).
- Every map passes data validation (portals bidirectional where intended, markers present).
- Adding a new map requires only a `.tscn` + JSON entry + index rebuild (documented and tested by adding `field_03`).

**Tests:** Portal transfer (entity removed from old map, present in new at the portal position, events emitted); physics isolation; map unload timer; validator catches a broken portal reference (fixture).

**Pitfalls**
- Using one physics space for all maps (e.g. offsetting maps far apart) causes cross-map queries and float precision issues. Use World2D per map.
- Baking portal destinations into scenes. Destinations live in JSON. Scenes only hold marker positions.
- Large single TileMapLayers with mixed solid and one-way tiles. Keep one-way platforms on their own layer and group (drop-through detection depends on it).
- Client and server map scenes diverging. There's one scene file. The server export strips textures automatically, so never make collision depend on textures.

---

### Phase 6: UI / HUD (→ Milestone M1 Vertical Slice)
**Goal:** A complete, original-looking HUD and windows: bottom status bar, quickslots, inventory, equipment, stats, skills, chat log, system messages, settings with key rebinding. All UI reads from `GameState` (fed by Authority events) and writes only via intents.
**Depends on:** Phase 5.
**Deliverables:** UI theme, HUD, windows framework (draggable, toggled by hotkeys, remember positions), tooltips, quickslot bar, settings menu.

**Tasks**
- [ ] 6.1 `GameState` view model: subscribes to Authority events and keeps the local player's vitals, stats, EXP, inventory slots, equipment, skills, cooldowns (approximate, for display), currency and quests. Emits fine-grained signals (`vitals_changed`, `inventory_slot_changed(tab, slot)`...).
- [ ] 6.2 UI theme (`content/ui/theme.tres`): pixel font (OFL-licensed, credited), 9-slice panels (original), color palette. All windows use the theme. No per-node style overrides except for exceptions.
- [ ] 6.3 `WindowManager` + `GameWindow` base: open/close/toggle by id, drag by title bar, z-order on click, clamp to screen, save positions to `user://settings.cfg`, Esc closes the top window.
- [ ] 6.4 HUD bottom bar: level, name, class, HP/MP/EXP bars with numbers and percentage, currency, menu buttons.
- [ ] 6.5 Quickslot bar (e.g. 2 rows × 8 or a configurable layout): drag skills/items onto slots. Key labels follow rebinds. Cooldown sweep overlay. Item counts. Keybinds persist (LOCAL: settings file; online: `SET_KEYBIND` intent → character record).
- [ ] 6.6 Inventory window: tabs Equip/Use/Etc, grid slots, drag-to-move (sends `MOVE_ITEM`), double-click to use/equip, right-click context (drop/split), currency display, tooltips.
- [ ] 6.7 Equipment window: paper-doll slots, drag to equip/unequip, total stat summary.
- [ ] 6.8 Stats window: base + bonus display, AP allocation buttons (send `ALLOC_AP`), derived stats (damage range, crit %).
- [ ] 6.9 Skills window: tabs per job tier, skill icons, levels, SP allocation (`ALLOC_SP`), drag to the quickslot, descriptions with current/next level values computed from `SkillDef`.
- [ ] 6.10 Chat/log box: system messages, EXP/item gains, scrollback, input line (local echo only for now; networked in Phase 12).
- [ ] 6.11 Tooltips: item (name, reqs coloured red/green, stats, description, price) and skill tooltips.
- [ ] 6.12 Settings: master/music/SFX volume, window mode, scale, key rebinding UI (conflict detection), and show damage numbers toggle.
- [ ] 6.13 Rejection UX: on `INTENT_REJECTED`, show a short toast ("Not enough MP", "Inventory full").
- [ ] 6.14 Accessibility basics: UI scale option, colour-blind-friendly damage number palette option. All user-facing strings go through `tr()` from now on (localization-ready).

**Acceptance criteria (M1 Vertical Slice)**
- A new player can play town → fields for 20 minutes: kill mobs, level to ~8, allocate AP/SP, equip drops, use potions from quickslots, read system messages. No debug commands needed except job advance.
- No UI code mutates sim state (grep check: no `PlayerEntity`/`sim/` imports under `client/ui/`).
- Rebinding a key updates the quickslot labels and persists across restarts.
- Windows reopen where they were left.

**Tests:** GameState applies event sequences correctly (unit, no UI); keybind conflict detection; quickslot assignment serialization; window manager z-order and close-top logic (unit with mocked windows).

**Pitfalls**
- UI reading sim nodes directly "because it's local now" breaks in Phase 9. Only `GameState`.
- Building windows with absolute positions at 640×360 without anchors. Use containers and anchors so UI scaling works.
- Per-frame polling of GameState in `_process` for every label. Use signals.
- Item tooltips that compute stats differently from the sim. Use the same `ItemDef`/`SkillDef` helpers.

---

### Phase 7: NPCs, dialogue, quests, shops
**Goal:** Towns come alive: NPCs with server-driven dialogue graphs, quests (kill/collect/talk/deliver/reach), quest log and tracker, shops (buy/sell), and job advancement through an NPC.
**Depends on:** Phase 6.
**Deliverables:** `NpcDef`, `DialogueDef`, `QuestDef`, `ShopDef` (+ schemas), `NpcEntity`, `DialogueRunner`, `QuestService`, `ShopService`, UI windows: dialogue, quest log, quest tracker, shop.

**Tasks**
- [ ] 7.1 Defs + schemas for npcs, dialogues, quests, shops (§7.2). Validator cross-checks: quest giver NPCs exist, dialogue actions reference existing quests/shops, objective items/mobs exist, reward items exist.
- [ ] 7.2 `NpcEntity` (static, layer `npc`) spawned from map JSON `npcs` + markers. `NpcView` with a name tag and a quest indicator (`!` available, `?` turn-in ready), computed client-side from `GameState` quest data + NPC def.
- [ ] 7.3 `TALK` intent (validate distance ≤ 80 px). `DialogueRunner` (server-side state per player: dialogue id + node id) emits `DIALOGUE_SHOW [npc_eid, text, choices[]]`. `DIALOGUE_CHOICE(idx)` advances and executes the node's action after validating its preconditions. Dialogue auto-closes if the player moves away or changes map.
- [ ] 7.4 Dialogue selection: talking to an NPC picks (in order) a turn-in-ready quest's `complete` dialogue, an in-progress quest's `progress` dialogue, an available quest's `offer` dialogue, or `default_dialogue`.
- [ ] 7.5 `QuestService`: states `available → active → complete_ready → completed`, requirements check, objective tracking via sim hooks (mob killed, item gained/lost, map entered, level reached, NPC talked), and `QUEST_UPDATED` events with progress.
- [ ] 7.6 Quest turn-in: atomic. Check inventory space for rewards first, consume collect items, grant EXP/currency/items, mark completed. On failure, reject with no partial state.
- [ ] 7.7 Quest-only drops (`quest_entries` in drop tables) roll only for players with the quest active and the objective incomplete.
- [ ] 7.8 `ShopService`: `SHOP_OPENED [shop_id, stock[]]` via dialogue action `open_shop`. `BUY(shop_id, item_id, qty)` and `SELL(tab, slot, qty)` intents, validated (in range of that NPC, in stock, currency, space, sellable). Buyback list is optional (later).
- [ ] 7.9 Job advancement NPC per class: dialogue with a `job_advance` action after checking requirements. Replaces the Phase 3 debug command (keep the debug command behind `OS.is_debug_build()` + LOCAL only).
- [ ] 7.10 UI: dialogue window (typewriter text, choices, NPC portrait placeholder), quest log (active/completed, objectives with progress), quest tracker on the HUD (up to 3 pinned), shop window (buy tab with quantities, sell tab via inventory drag).
- [ ] 7.11 Content: 15+ quests across town and fields (a tutorial chain: talk → kill → collect → job advance), 3 shops (general store, weapons, armor), 8+ NPCs with idle dialogue.

**Acceptance criteria**
- The tutorial quest chain is completable start to finish and ends with job advancement.
- Quest progress survives map changes. Collect quests count items already in the inventory when accepted.
- Shops buy and sell correctly. Insufficient currency or space is rejected with toasts. Currency never goes negative.
- Every NPC, quest and shop is defined in data only. Adding a quest requires no code.

**Tests:** QuestService transitions and every objective type; turn-in atomicity (full inventory → no change); dialogue selection priority; dialogue action validation (can't trigger `accept_quest` for a quest whose requirements aren't met by sending a crafted choice); shop math with buy/sell rates; quest-only drop filtering.

**Pitfalls**
- Running dialogue logic on the client (the client choosing "complete quest") is an exploit. The server owns the dialogue state.
- Embedding a scripting language in dialogue. Keep the closed set of actions and extend it deliberately.
- Quest progress stored as positional arrays without objective ids makes reordering objectives corrupt saves. Key progress by objective index **and** store a quest content hash or `objectives_version` to migrate.
- Forgetting to close dialogues on disconnect or map change leaves sessions stuck.

---

### Phase 8: Save & local persistence (→ Milestone M2 Single-player Complete)
**Goal:** Robust single-player saves using the exact `CharacterRecord` shape the backend will use. Autosave, multiple save slots, versioned migrations, corruption safety.
**Depends on:** Phase 7.
**Deliverables:** `CharacterRecord` (§9.20), `RecordMigrations`, `CharacterStorage` interface + `LocalFileStorage`, `PlayerEntity.to_record()/apply_record()`, a save slot screen (LOCAL).

**Tasks**
- [ ] 8.1 Implement `CharacterRecord` to_dict/from_dict (§9.20) + JSON Schema `character_record.schema.json` (also used by backend tests later).
- [ ] 8.2 `PlayerEntity.to_record()` and `apply_record()` covering level, EXP, base stats, AP/SP, HP/MP, currency, map + spawn portal (the nearest portal or town on load), skills, inventory (uids preserved), equipment, quests, keybinds.
- [ ] 8.3 `RecordMigrations.upgrade(dict)`: a framework for `record_version` N→N+1 with a test fixture per version (start with v1 only, but write a fake v0→v1 test to prove the mechanism).
- [ ] 8.4 `LocalFileStorage` with atomic writes and a `.bak` rollback (§9.20). Load falls back to `.bak` if the main file is corrupt.
- [ ] 8.5 Autosave triggers in LOCAL: every 60 s, on map change, on level up, on quest completion, on quit (`NOTIFICATION_WM_CLOSE_REQUEST`). The save runs off the sim tick (deferred) and never blocks gameplay noticeably.
- [ ] 8.6 Save slot screen (LOCAL mode only): 3 slots showing name, level, class, map, last played. New/Continue/Delete with confirmation. Character creation (name + simple look options placeholder).
- [ ] 8.7 Content data changes vs saves: on load, unknown item ids are moved to a "lost items" list and logged, unknown quests dropped with a log, stats clamped. Document this policy in DECISIONS.
- [ ] 8.8 A round-trip property test: random valid characters → to_record → JSON → from_dict → apply → to_record equals the original.

**Acceptance criteria (M2 Single-player Complete)**
- Play, quit (window close), relaunch, and continue with identical state (position at the map spawn/nearest portal, inventory, equipped items, quests, keybinds).
- Killing the process mid-save never produces an unloadable save (test: simulate a truncated file → `.bak` is used).
- The full single-player loop (levels 1–15, job advance, quests, shops) is playable for 1–2 hours without blockers.
- `CharacterRecord` JSON validates against the schema.

**Tests:** Round-trip property test; migration framework; corrupt file fallback; unknown item handling; autosave scheduling (unit, mocked storage).

**Pitfalls**
- Saving derived values (max HP from gear, damage) as authoritative. Save base data. Recompute on load.
- Writing saves with `FileAccess` directly to the final path (corruption on crash). Always write a tmp file and rename.
- Different serializers for local saves and the server. There must be exactly one (`CharacterRecord`).
- Saving Godot `Variant`s via `var_to_str`/`store_var` instead of JSON locks the format to Godot and the backend can't read it.

---

### Phase 9: Networking foundation
**Goal:** A headless dedicated server hosts the world. Clients connect over ENet with a dev ticket, spawn, and move with client-side prediction and reconciliation. Remote players are interpolated. Per-map interest management. Network conditions simulated.
**Depends on:** Phase 8 (all sim features exist and run in LocalAuthority).
**Deliverables:** `Net` autoload (§9.11), `RemoteAuthority` (§9.12), `ServerMain` + `SessionManager` (§9.22), snapshot builder, clock sync, `RemotePlayerView`, dev-mode tickets, netsim tooling, network debug overlay.

**Tasks**
- [ ] 9.1 Implement `Net` (§9.11) fully: host/join/close/kick with reason delivery (send the reason, then disconnect after 2 frames), ENet peer timeouts configured (`ENetPacketPeer.set_timeout`), packet stats (bytes in/out per second).
- [ ] 9.2 `ServerMain` (§9.22): fixed tick, `Engine.max_fps` cap, heartbeat file, shutdown via file/close request, JSON logs.
- [ ] 9.3 `SessionManager` handshake with **dev tickets**: in Phase 9, `JoinTicket.verify` accepts `dev:<character_name>` only when `SKYROPE_DEV_TICKETS=1`. The server loads/creates the character via `LocalFileStorage` under `/data/dev_saves`. Kick on protocol mismatch, kick if unauthenticated after 5 s.
- [ ] 9.4 `s2c_welcome` + `FULL_STATE` event (the full CharacterRecord-derived view for `GameState`) on join and map change.
- [ ] 9.5 `RemoteAuthority` (§9.12) and the client `--connect=host:port` flow (debug connect screen: host, port, name). The same `client_main` presentation works unchanged.
- [ ] 9.6 Input path: client sends `c2s_inputs` every tick with the last 3 frames. The server's `InputQueue` dedupes by seq, buffers 2–4 ticks, repeats the last input for missing frames (max 6), and drops frames too far ahead (anti speed-hack).
- [ ] 9.7 Snapshots at 20 Hz per peer: the self `MotorState` + `last_processed_seq` + nearby entities **in the same map only**. Quantized `EntityState`. Snapshot size logged; assert < 1,000 bytes with 50 entities.
- [ ] 9.8 `ClockSync` (`c2s_ping`/`s2c_pong` every 2 s, RTT EMA, server tick estimate) and an adaptive interpolation delay (66–200 ms based on jitter).
- [ ] 9.9 Reconciliation on the client with view smoothing (< 24 px: smooth over 100 ms; ≥ 24 px: snap). Metrics: corrections per minute, average correction distance.
- [ ] 9.10 `RemotePlayerView`: interpolated position, animation state + facing from `EntityState`, name tag. Spawn/despawn from snapshot diffs (an entity missing from 3 consecutive snapshots → despawn, or an explicit `ENTITY_DESPAWNED`).
- [ ] 9.11 Map changes over the network: `ENTER_PORTAL` → server transfer → `MAP_CHANGED` + `FULL_STATE` → client transition (Phase 5 code). Peers only receive snapshots for their map.
- [ ] 9.12 `tools/netsim.sh`: Linux `tc netem` wrapper to add latency/jitter/loss on loopback (`sudo tc qdisc add dev lo root netem delay 80ms 20ms loss 2%`), plus a reset command. Document it in `docs/RUNBOOK.md`.
- [ ] 9.13 Network debug overlay (F3 page 2): RTT, jitter, interp delay, snapshot rate, bytes/s in/out, corrections/min, pending inputs.
- [ ] 9.14 Integration test: a headless server + 2 headless bot clients in one test process (or separate processes launched by a test script) connect, move scripted inputs, and assert positions converge (server vs client predicted ≤ 0.5 px after the inputs stop).
- [ ] 9.15 First Docker build of the game server (§9.24) running dev tickets. Test from another machine on Tailscale.

**Acceptance criteria**
- Two clients on different machines (over Tailscale) see each other move smoothly. Local movement feels identical to LOCAL mode at 0–100 ms RTT.
- With netsim at 150 ms ± 30 ms and 3% loss: local movement stays responsive, remote players look smooth (no visible teleporting under normal motion), and corrections are < 5/min while just walking and jumping.
- A client running a modified build that sends fake fast inputs can't move faster than normal (server-side validation test).
- Protocol mismatch shows a clear message. Server restart disconnects clients gracefully.

**Tests:** InputQueue edge cases under loss/reorder/duplication; snapshot size budget; clock sync math; reconciliation convergence (integration with simulated latency in-process: queue packets with delay); interest management (peer in map A receives no entities from map B).

**Pitfalls**
- Calling `rpc` on nodes with different paths on client and server. All RPCs live on `/root/Net`.
- Sending snapshots with `reliable` mode: head-of-line blocking leads to rubber-banding. Snapshots and inputs are `unreliable_ordered`. Events are `reliable`.
- Unbounded pending input buffers on the client (memory, plus giant re-sims after a stall). Cap at `MAX_PENDING_INPUTS`, and if exceeded, hard-snap to the server state.
- Running the server tick from `_process` or with an uncapped frame rate: CPU at 100% and timing drift. Use `_physics_process` + `Engine.max_fps`.
- Interpolating the local player (adds input lag). The local player is predicted only.
- Forgetting that a Godot server binds UDP on all interfaces. In Docker, publish only the needed port.

---

### Phase 10: Networked combat, mobs, loot, EXP (→ Milestone M3 Multiplayer Prototype)
**Goal:** Everything from Phases 2–7 works online and is server-authoritative: attacks, skills, projectiles, mob AI, damage events, EXP, drops with claim windows, pickups, inventory/equipment, NPCs, quests, shops.
**Depends on:** Phase 9.
**Deliverables:** event routing (scopes), cosmetic attack prediction, remote players' attack animations, mob/projectile/drop interpolation, per-peer rate limits, intent argument validation everywhere.

**Tasks**
- [ ] 10.1 Event scopes: route `DAMAGE`, `DIED`, `SKILL_CAST`, `ENTITY_*` to the map; `EXP_GAINED`, `INVENTORY_CHANGED`, `CURRENCY_CHANGED`, `QUEST_UPDATED`, `DIALOGUE_*`, `SHOP_OPENED`, `INTENT_REJECTED` to the player only. Audit every event type.
- [ ] 10.2 `SKILL_CAST [eid, skill_id, facing]` map event so remote players see attack animations and VFX. The local player has already played it cosmetically: dedupe by eid.
- [ ] 10.3 Cosmetic prediction rules: the local attack animation and SFX play instantly. Damage numbers appear **only** from server `DAMAGE` events (typically 30–80 ms later on a LAN/Tailscale, which is acceptable).
- [ ] 10.4 Mob, projectile and drop views interpolated from snapshots. Mob hit flinch triggered by `DAMAGE` events (not by snapshot anim) for responsiveness.
- [ ] 10.5 Argument validation for every intent handler (types, ranges, ownership, distance, state). Write a table-driven test feeding malformed intents to `MapInstance.handle_intent` (none may crash or mutate state).
- [ ] 10.6 Per-session rate limits (intents 30/s, chat later) with a violation counter. Kick at threshold (configurable). Log the violations.
- [ ] 10.7 Multi-player correctness: EXP split among damagers, drop claim windows by owner, simultaneous pickup race (the first processed wins and the other gets a rejection), a mob targeting the nearest aggressor.
- [ ] 10.8 NPC dialogue, quests and shops online: verify dialogue state per session, closed on disconnect.
- [ ] 10.9 Player death/respawn online. Other players see the death animation and a "ghost"/tombstone placeholder.
- [ ] 10.10 Bandwidth review: measure per-client downstream with 20 players + 40 mobs on one map. Target < 25 KB/s. If over, add delta compression (skip unchanged fields) or reduce the rate for distant entities (Decision Log).
- [ ] 10.11 Bot client (`tools/bots/`): a headless client mode `--bot` that connects with a dev ticket, wanders randomly, attacks periodically, and picks up drops. A launcher script starts N bots.

**Acceptance criteria (M3 Multiplayer Prototype)**
- 3–5 human testers over Tailscale can play together for 30 minutes: fight, see each other's attacks and damage numbers, loot with claim rules, complete quests, buy from shops. No desyncs requiring a reconnect.
- 30 bots + 2 humans on one map: server tick time < 8 ms average (logged), no crashes, humans report a smooth experience.
- The malformed-intent fuzz test passes. Rate-limited spam doesn't affect other players.

**Tests:** Event routing scopes; intent fuzz table; pickup race; claim windows with 2 sessions; EXP split with 3 sessions; dialogue cleanup on disconnect.

**Pitfalls**
- Showing damage numbers from local hit guesses: players see numbers that "didn't happen". Server events only.
- Broadcasting player-private events to the whole map leaks info and wastes bandwidth.
- The server trusting `facing` from the intent without bounds: clamp to ±1 and check that it matches recent input direction if needed.
- Sending events for entities the client hasn't spawned yet (event before snapshot). The client must buffer or ignore events for unknown eids gracefully.

---

### Phase 11: Accounts, login, character select/creation, DB persistence
**Goal:** Real accounts via the backend service, secure join tickets, character select/creation screens, all character data persisted in PostgreSQL through the server-only internal API, with single-session enforcement.
**Depends on:** Phase 10.
**Deliverables:** `backend/` FastAPI service (§9.23), Alembic migrations, `BackendStorage` (Godot), `JoinTicket` verification, client login/char-select/create UI, Docker Compose with Postgres (§9.24).

**Tasks**
- [ ] 11.1 Backend scaffold: FastAPI app, config from env, SQLAlchemy 2 async models, Alembic migration 0001 (§9.23 schema, `citext` extension), `/healthz`, pytest with a test DB.
- [ ] 11.2 Auth: register (username rules, password ≥ 10 chars, argon2id, optional invite code), login (rate-limited), refresh-token rotation, logout. Tests for each, including brute-force rate limiting.
- [ ] 11.3 Characters API: list/create/delete (soft). Name validation (3–12 chars, letters/digits, profanity list, unique case-insensitively). Starter kit from game data (the backend reads `game/data/classes.json` + `items` for the starter kit, or the game server initializes new characters on first join. **Decision: the game server initializes new characters on first join** (`level=1, record empty → sim fills defaults`), so the backend doesn't need game rules).
- [ ] 11.4 Join flow: `POST /characters/{id}/join` checks ownership, ban status and the existing session (if active and its heartbeat is < 60 s old → `409 already online`), then issues an HMAC ticket (§9.23) with `{host, port}` from the channel config.
- [ ] 11.5 Internal API (service token): ticket redeem (single use, writes the `sessions` row), get character (record JSON assembled from tables), put character (transaction, `save_version` check, full replace of item rows by uid, reject duplicate uids across characters), end session, session heartbeat (every 30 s from the game server).
- [ ] 11.6 Godot `JoinTicket.verify` (HMAC SHA-256 via `Crypto.hmac_digest`, constant-time compare, expiry) + `BackendClient` (HTTPRequest pool, JSON, retries with backoff, timeouts) + `BackendStorage` implementing `CharacterStorage`.
- [ ] 11.7 SessionManager: real ticket flow (verify → redeem → load → spawn), autosave dirty sessions every 60 s, save on disconnect, `save_all_and_kick` on shutdown, session heartbeat. Retry failed saves, and if the backend is down, keep the dirty state in memory and alert via logs (never drop data silently).
- [ ] 11.8 Client screens: login/register (remember username), world/channel select (from `GET /worlds`), character select (3 slots, preview), character creation (name, basic appearance placeholders), connecting/loading screen with clear error messages. Store the refresh token in `user://` (encrypted with `FileAccess.open_encrypted_with_pass` using a per-install key: obfuscation only, documented as such).
- [ ] 11.9 TLS: during the Tailscale phase, HTTP inside the tailnet is acceptable (WireGuard encrypts it). Add an optional Caddy reverse proxy with HTTPS in compose (`profiles: [public]`) for later public exposure.
- [ ] 11.10 Docker Compose (§9.24) with postgres, backend, gameserver-ch1, db-backup. `make up` brings up the full stack. Document first-run steps in `docs/RUNBOOK.md`.
- [ ] 11.11 Remove the dev-ticket path from release builds (only enabled with `SKYROPE_DEV_TICKETS=1` and never in the production compose file).

**Acceptance criteria**
- Register → login → create character → join → play → quit → rejoin from another machine: the state is identical.
- Logging in with the same account twice: the second join is rejected (or, by policy, the first session is kicked; pick one in the Decision Log).
- `docker compose down && up` loses no data. Killing the game server container with `docker stop` saves everyone (graceful shutdown verified in logs).
- Tickets are single-use and expire after 30 s (tests). Internal endpoints reject requests without the service token.
- Backend test coverage ≥ 80% for auth and character persistence.

**Tests:** Backend pytest (auth flows, rate limits, ticket HMAC/expiry/single-use, save_version conflicts, uid duplication rejection, session lock); Godot unit tests for JoinTicket verify (good/bad sig/expired); integration test with the compose stack (scripted login + join + save via a headless client).

**Pitfalls**
- Letting the client talk to the internal API or pass its own character data. Only the game server writes character state.
- Storing the whole character as one JSONB blob: you lose item uniqueness constraints and trade atomicity. Items are rows.
- No optimistic concurrency: two saves racing (autosave + disconnect save) can roll back progress. Use `save_version`.
- Blocking the sim tick on HTTP. All backend calls are async (`await` in SessionManager, never in WorldSim).
- Logging tokens or passwords. Scrub the logs.

---

### Phase 12: Social: chat, parties, friends, trading (→ Milestone M4 Online Feature-Complete Core)
**Goal:** Map chat, whispers, party chat, parties with EXP sharing and HP bars, a friends list with online status, and secure player-to-player trading.
**Depends on:** Phase 11.
**Deliverables:** `ChatService`, `PartyService`, `FriendsService` (backend tables + server cache), `TradeService` with an atomic backend commit, UI windows (chat tabs, party, friends, trade).

**Tasks**
- [ ] 12.1 `CHAT` intent `[channel, text, target_name?]`: map (all players on the map), whisper (by character name, same channel; cross-channel via backend lookup later), party. Max length 120 chars, strip control characters, rate limit 5 per 5 s, mute flag, profanity filter (toggleable client-side display filter + server block list for slurs).
- [ ] 12.2 Chat UI: tabs (All/Map/Party/Whisper/System), `/w name msg`, `/p msg`, reply to last whisper, chat bubbles over players (client view).
- [ ] 12.3 `PartyService`: invite (target nearby or by name), accept/decline, leave, kick (leader), leader transfer, max 6. `PARTY_UPDATED` events with members' level, class, map and HP%. Parties persist while members are online on the channel and disband when empty.
- [ ] 12.4 Party EXP share: members on the same map within range get a share of the killer's EXP (bonus +X% per extra member, from `stats.json`). Party drop claim (the claim window applies to the whole party).
- [ ] 12.5 Party UI: member list with HP bars, invite/leave buttons, party member dots on the minimap.
- [ ] 12.6 Friends: backend `friends` table + internal endpoints. Add (by name, mutual acceptance), remove, list with online status (from the `sessions` table). Friend login/logout notifications (polled every 30 s or pushed via backend → server events; decide in DECISIONS. Polling is acceptable for alpha).
- [ ] 12.7 `TradeService`: request → accept → trade window. Both sides offer items (by uid) + currency → both **lock** → both **confirm** → the server validates (items still owned, not equipped, tradeable, space on both sides) → **atomic** `POST /internal/trades/commit` (single DB transaction moving item rows + currency, writing the audit log) → apply to both sims → events. Any change after lock resets both locks. Cancels on distance > 300 px, map change or disconnect.
- [ ] 12.8 Trade UI: two panes, lock/confirm buttons with clear state, 3-second confirm delay after any change (anti-scam), a warning on currency amounts.
- [ ] 12.9 Block list (ignore whispers/trade requests from blocked characters), stored in the character record.
- [ ] 12.10 Cross-channel readiness: when a second channel exists, whispers and friend status go through the backend (or Redis pub/sub after a Decision Log entry). Implement it via the backend for now.

**Acceptance criteria (M4)**
- Testers can chat in map/party/whisper, form parties, share EXP, see party HP, add friends, and trade items and currency safely.
- A trade in which one side's connection drops mid-commit never duplicates or loses items (fault-injection test: kill the server between DB commit and sim apply → on restart both characters have the consistent DB state).
- Chat spam is rate-limited without affecting others.

**Tests:** Chat validation and routing; party lifecycle and EXP share math; trade state machine (every reset path); trade commit atomicity (backend transaction test with concurrent conflicting trades); friend status.

**Pitfalls**
- Applying trade results in the sim before the DB commit succeeds leads to duplication on crash. The DB commit comes first, then the sim apply. On restart, the DB is truth.
- Trading by slot index instead of uid: items moved during the trade get swapped. Use uids.
- Party state stored only in one map instance: parties are channel-wide. Keep `PartyService` at the WorldSim level.
- Unbounded chat history on the server. Don't store it (or ring-buffer it for moderation, with a retention policy).

---

### Phase 13: Content pipeline & tools
**Goal:** Adding content is fast, safe and mostly data entry: validation, balancing exports, map workflow, in-editor previews, and an admin toolset.
**Depends on:** Phase 12 (could start partially earlier, but keep the order for Cursor).
**Deliverables:** validator v2, balance sheet export/import, map workflow docs (Godot-native; optional Tiled importer), editor plugin for data browsing, admin commands, content guide.

**Tasks**
- [ ] 13.1 `validate_data.py` v2: all schemas, all cross-references (items, mobs, drop tables, maps/portals/markers, quests, dialogues/actions, shops, NPCs, skills/classes), unreachable content warnings (items that never drop and aren't sold or rewarded), level-range sanity per map.
- [ ] 13.2 `tools/balance_sheet.py export|import`: JSON ↔ CSV for mobs, items and skills (edit in LibreOffice/Sheets, re-import with validation). Generate summary charts (EXP per hour per map estimates, TTK per mob per level).
- [ ] 13.3 Map workflow decision: **Godot TileMapLayer is the source of truth**. Optional `tools/tiled_import/` converts Tiled `.tmj` (tile layers + object layers for spawns/portals/ropes) into `.tscn` via a Godot `@tool` EditorScript, only if Tiled is preferred. Document both in `docs/CONTENT_GUIDE.md`.
- [ ] 13.4 Godot editor plugin `addons/skyrope_tools/` (editor-only, excluded from exports): a dock listing data entries by category with search, item icon/mob scene preview, a "validate now" button that runs the Python validator, and "open JSON at entry".
- [ ] 13.5 Map lint EditorScript: checks node naming conventions, groups, collision layers, marker presence, and bounds vs used rect.
- [ ] 13.6 Admin/GM commands (server, admin accounts only, audited): `/warp map`, `/spawn mob n`, `/item id qty`, `/level n`, `/kick name`, `/mute name minutes`, `/ban name days`, `/announce text`, `/reload data` (hot reload of balance-only fields; structural changes need a restart).
- [ ] 13.7 Content guide: step-by-step recipes "Add a mob", "Add an item", "Add a skill", "Add a map", "Add a quest", "Add an NPC/shop", each with a JSON example and a validation step.
- [ ] 13.8 Content expansion pass toward MVP scope (§2.3): 6–8 hunting maps, 10–12 mobs, ~80 items, 15–20 quests, 1 mini-boss with a simple pattern (`behavior: boss` → scripted phases in `ai/brain_states/boss_*.gd` driven by data).

**Acceptance criteria**
- A non-programmer can add a new mob + drop table + map spawn by following the content guide, and CI validates it.
- The CSV round-trip produces identical JSON when nothing changed.
- GM commands work only for admin accounts and every use is in the `audit_log`.

**Tests:** Validator fixtures (each error type detected); CSV round-trip; GM command permission checks.

**Pitfalls**
- Hot-reloading structural data while entities reference old defs leads to crashes. Limit hot reload to numeric balance fields.
- Letting the editor plugin become a dependency of runtime code. It's editor-only.
- Tiled and Godot maps both being "truth" for the same map. Choose one per map (default Godot).

---

### Phase 14: Audio, VFX, polish
**Goal:** The game feels juicy and cohesive: music per map, SFX for every action, hit effects, level-up effects, screen feedback, UI sounds, animation polish, and replacing placeholder art progressively.
**Depends on:** Phase 13.
**Deliverables:** `AudioManager` (buses, music crossfade, SFX pooling, positional SFX attenuation by distance), VFX library, polished animations, an art replacement plan in progress.

**Tasks**
- [ ] 14.1 Audio buses: Master, Music, SFX, UI, Ambience (`bus_layout.tres`). Volume settings wired to buses (dB conversion via `linear_to_db`).
- [ ] 14.2 `AudioManager`: music crossfade on map change (from `MapDef.music`), SFX pool (e.g. 16 `AudioStreamPlayer2D`), throttling of identical SFX (max N per 50 ms), random pitch variance ±5%.
- [ ] 14.3 SFX hooks driven by events (never by sim): attack swing, hit, crit, mob hurt/die, pickup, level up, quest complete, UI click/open/close, portal, error toast.
- [ ] 14.4 VFX: hit sparks, skill effects from `SkillDef.vfx`, level-up pillar, item rarity glow, damage number styles, a buff aura loop, screen shake (tiny, optional toggle) on crits/boss attacks.
- [ ] 14.5 Animation polish: walk/idle/jump/fall/climb/attack/hurt/dead for the player (layered equipment visuals are deferred; for MVP, the weapon sprite is drawn on the hand anchor), mob animation sets.
- [ ] 14.6 Art replacement pass: original pixel art for player, 4 mobs, town tileset, UI frame, item icons (or licensed asset packs, credited). Follow §13.
- [ ] 14.7 Performance pass (client): object pooling for damage numbers, VFX and drops. Profile with 30 entities on screen and keep 60 FPS on modest hardware.
- [ ] 14.8 Game feel tuning session: hit-stop length, knockback distances, attack cadence, pickup radius, camera smoothing. Record in DECISIONS.

**Acceptance criteria**
- Every gameplay action has audio-visual feedback. Volume sliders work. Music crossfades between maps.
- The client holds 60 FPS with 20 players + 40 mobs on screen on the reference machine (document its spec).
- All new assets are logged in `ASSET_CREDITS.md` with licenses.

**Tests:** AudioManager throttling (unit), SFX/VFX event mapping table coverage (every EventType that should have feedback has a mapping).

**Pitfalls**
- Triggering audio from sim code. The server has no audio, and sim must stay presentation-free.
- Unpooled particles and labels cause GC/alloc spikes in big fights.
- Mixing sprite scales or pixel densities. Follow §13 strictly.

---

### Phase 15: Security, anti-cheat, load testing
**Goal:** Harden the server and backend, detect common cheats, and prove capacity targets with bots.
**Depends on:** Phase 14.
**Deliverables:** threat model doc, validation audit, anti-cheat heuristics, optional lag compensation, load test results, profiling and optimizations.

**Tasks**
- [ ] 15.1 Write `docs/THREAT_MODEL.md`: assets (accounts, items, currency), attackers (modified client, packet injector, credential stuffing, DoS), mitigations, residual risk.
- [ ] 15.2 Validation audit: walk every RPC and intent handler and confirm type, range, ownership, distance, state and rate checks. Add missing tests.
- [ ] 15.3 Movement anti-cheat: inputs ahead of server time are dropped, an input rate cap, teleport detection (impossible with server-sim movement, but log any position corrections > N on the server side), a "stuck in wall" safety unstuck.
- [ ] 15.4 Combat anti-cheat: cast rate vs `cast_ticks`, impossible hit ranges logged, statistical outliers (damage per minute vs gear) flagged to the audit log.
- [ ] 15.5 Economy monitoring: daily currency/item creation vs sink metrics. Alerts on anomalies (a sudden spike in a rare item). Duplicate-uid DB constraint violations raise high-severity logs.
- [ ] 15.6 Backend hardening: rate limits on all public endpoints, password breach list check (optional offline list), account lockout with backoff, CORS off, request size limits, dependency audit (`pip-audit`), secrets only from env.
- [ ] 15.7 ENet hardening: max clients, per-IP connection rate limit (track in SessionManager, kick if > N connects/min), max packet size checks, an unauthenticated-peer timeout (5 s). Optional DTLS via `ENetConnection.dtls_server_setup()` for public (non-Tailscale) deployments.
- [ ] 15.8 Optional lag compensation for hit queries: keep 12 ticks (200 ms) of mob position history and resolve player attacks against mob positions at `server_tick - client_interp_ticks` (capped). Decide by play-test (Decision Log).
- [ ] 15.9 Load testing: bot swarm (`tools/bots/launch.sh N`) at 50/100/150 bots across 3 maps on the homelab. Record tick time (avg/p99), CPU, RAM, bandwidth. Targets: 100 CCU/channel, tick p99 < 12 ms, bandwidth < 2.5 MB/s/channel.
- [ ] 15.10 Optimization pass driven by profiling (Godot profiler on the server via `--debug-collisions` off, custom tick timers per stage). Typical wins: think-throttling AI, snapshot culling by distance, avoiding Dictionary allocations in hot loops, pooled shapes for queries.
- [ ] 15.11 Network chaos tests: 300 ms RTT, 10% loss, jitter 100 ms, and reconnect storms (50 bots reconnecting at once). The server must stay stable.

**Acceptance criteria**
- Load test report in `docs/LOADTEST.md` meeting targets (or documented gaps with a plan).
- Fuzz and validation tests cover every intent type. The threat model is reviewed.
- No known item duplication path. All trade/save paths are tested for crash consistency.

**Tests:** Intent fuzzing (random args ×10k per type); rate limit tests; backend security tests (rate limits, lockout); load test scripts (manual run, results committed).

**Pitfalls**
- Optimizing before measuring. Always profile first.
- Client-side anti-cheat (obfuscation, memory checks) is low value for this project. Server authority is the real defense.
- Load testing bots that don't exercise combat/loot underestimate cost. Bots must fight and loot.

---

### Phase 16: Deployment, monitoring, backups (→ Milestone M5 Closed Alpha)
**Goal:** A reliable homelab deployment with one-command updates, monitoring, alerting, tested backups, and a closed alpha with invited friends.
**Depends on:** Phase 15.
**Deliverables:** production compose file, update/rollback procedure, monitoring (logs + metrics + uptime), backup/restore drill, client distribution, an alpha feedback loop.

**Tasks**
- [ ] 16.1 `docker/docker-compose.yml` production profile: image tags pinned per release (`skyrope-gameserver:0.5.0`), restart policies, resource limits, log rotation, healthchecks (§9.24), no dev tickets.
- [ ] 16.2 Release process: `make release VERSION=x.y.z` → bump `Protocol.VERSION` if needed → CI builds the server image + client exports → tag → GitHub Release with client zips (Linux/Windows) → homelab `docker compose pull && up -d`.
- [ ] 16.3 Graceful update: announce in-game (`/announce`, a 5-minute countdown), `docker compose stop gameserver-ch1` (saves everyone via the SIGTERM → shutdown file path), update, start. Verify no data loss in a drill.
- [ ] 16.4 Rollback: keep the previous images. Alembic migrations must be backward compatible for one version (expand → migrate → contract). Document it in the RUNBOOK.
- [ ] 16.5 Backups: `db-backup` service every 6 h + daily off-box copy (rsync/rclone to another machine or cloud). **A restore drill**: restore into a fresh Postgres container and verify characters load. Document the time it takes.
- [ ] 16.6 Monitoring: Uptime Kuma (or similar) checks `/healthz` and the game server heartbeat. Optional Prometheus + Grafana: the backend exposes `/metrics` (prometheus-fastapi-instrumentator), the game server writes a metrics JSON file every 10 s (CCU, tick avg/p99, bytes/s, entities) that a tiny sidecar exposes (or log-based metrics via Loki). Alerts to Discord/ntfy (server down, tick p99 > 16 ms, backup failed, disk > 80%).
- [ ] 16.7 Network exposure: phase A, Tailscale only (testers join the tailnet or use Tailscale node sharing); phase B (later), a VPS front with WireGuard back to the homelab, or move the containers to the VPS. Firewall: only UDP 7777–7778 + HTTPS 443 public.
- [ ] 16.8 Client distribution: zipped builds on GitHub Releases (private repo → share links) or itch.io restricted page. The client checks `GET /version` and shows "update required" if `Protocol.VERSION` mismatches.
- [ ] 16.9 In-game bug report: `/bug text` → stored with character, map, position and recent client log lines (backend `bug_reports` table) + a Discord webhook notification.
- [ ] 16.10 Closed alpha: 5–15 testers, a test plan (what to test each week), a feedback form, a weekly patch cadence. Triage issues into GitHub Issues with labels (`bug`, `balance`, `ux`, `crash`, `exploit`).
- [ ] 16.11 Privacy & terms (lightweight): a data stored/retention note, a no-warranty alpha notice, a code of conduct for chat.

**Acceptance criteria (M5 Closed Alpha)**
- The stack runs for 7 days unattended with auto-restart. Monitoring alerts fire in a test.
- The backup restore drill succeeds and is documented with timings.
- 5+ external testers play multiple sessions. Crash-free session rate > 95%. No data loss incidents.
- An update with a DB migration is deployed with < 5 minutes downtime and no lost progress.

**Tests:** Deployment smoke test script (`tools/smoke.sh`: login, create char, join, move, logout via the headless bot); backup restore script tested in CI on a sample dump (optional).

**Pitfalls**
- Never-tested backups. Backups don't exist until a restore works.
- Running Postgres on a volume on a failing or SD-card disk. Use the homelab's reliable storage and monitor SMART.
- Exposing the backend's internal routes publicly. Route `/internal/*` only on the Docker network.
- Breaking DB changes deployed together with code (no rollback). Use the expand/contract pattern.

---

### Phase 17: Post-launch / later (→ Milestone M6 Open Beta and beyond)
**Goal:** Grow content and systems on the stable foundation. Each item below becomes its own mini-phase with the same template (goal, tasks, acceptance, tests, pitfalls) written into this document **before** implementation.
**Depends on:** M5.

**Backlog (prioritize after alpha feedback)**
- [ ] 17.1 Guilds: create/invite/ranks, guild chat, emblem (original icon set), guild storage (transactional like trades).
- [ ] 17.2 Bosses: multi-phase scripted bosses with telegraphed attacks (data-driven patterns), boss entry rules (daily limits), loot rules (contribution-based).
- [ ] 17.3 Party quests (instanced maps): a dynamic MapInstance per party with a stage script (kill N, collect, platform puzzle), timers, rewards. Requires instanced map ids (`pq_01#<instance_id>`), which the World2D-per-map design already supports.
- [ ] 17.4 Second job advancement (level 30), skill tree expansion, skill macros.
- [ ] 17.5 Cosmetic-only shop (no stat items, no gameplay advantage): cosmetic layers on the character sprite (requires a layered paper-doll renderer, §13.4).
- [ ] 17.6 Player marketplace / auction house (backend-driven listings, escrow with item rows, fees as a currency sink).
- [ ] 17.7 Crafting/gathering professions.
- [ ] 17.8 Pets (follow + auto-loot) and mounts (movement modifiers in MovementMotor data).
- [ ] 17.9 More channels and worlds: horizontal scale via more gameserver containers, a channel switch flow (save → new ticket → reconnect), Redis pub/sub for cross-channel chat/presence (Decision Log).
- [ ] 17.10 VPS deployment + DDoS considerations (provider protection, UDP rate limits), optional DTLS.
- [ ] 17.11 Controller support and Steam Deck verification, Steam build (Steamworks via a GDExtension: Decision Log).
- [ ] 17.12 Localization (Godot translation CSV/PO, all UI strings through `tr()`. **Start using `tr()` in Phase 6 to avoid rework.**)
- [ ] 17.13 Seasonal events (data-driven event flags, limited-time drops/quests).
- [ ] 17.14 Moderation tools: a web admin panel on the backend (search players, view audit logs, mute/ban, restore items).

**Acceptance criteria:** defined per feature mini-phase.
**Pitfalls**
- Adding systems that mutate state outside the sim/authority path "because it's just a UI feature". The same rules apply forever.
- Monetization creep. The pillars forbid pay-to-win.

---

## 11. Milestones

| Milestone | After phase | Definition | Exit criteria |
|---|---|---|---|
| **M0 Skeleton** | 0 | The architecture exists end to end with no gameplay | CI green; LOCAL + SERVER modes boot; data loads in exported builds |
| **M1 Vertical Slice** | 6 | 20 minutes of fun single-player: movement, combat, leveling, loot, gear, HUD | Phase 6 acceptance; 3 play-testers say movement and combat "feel good"; no UI → sim coupling |
| **M2 Single-player Complete** | 8 | A full offline loop with quests, shops, job advance and saves | 1–2 hours of content; saves robust; all sim code paths run through LocalAuthority |
| **M3 Multiplayer Prototype** | 10 | Everything online on a dedicated server with prediction and interpolation | 3–5 humans + 30 bots for 30 minutes with no desync; intent fuzz passes |
| **M4 Online Feature-Complete Core** | 12 | Accounts, DB persistence, chat, parties, friends, trading | Trade atomicity tests; persistence across restarts; social features usable |
| **M5 Closed Alpha** | 16 | Hosted 24/7 on the homelab for invited testers | 7-day stability, restore drill, 5+ external testers, crash-free > 95% |
| **M6 Open Beta** | 17.x | Public access (VPS or a hardened homelab edge), more content | Load targets met on the production host, moderation tools, DDoS plan |

Tag each milestone in git (`m1-vertical-slice`, …) and write a short retrospective in `docs/CHANGELOG.md`: what slipped, what to change.

---

## 12. Testing Strategy

### 12.1 Pyramid
1. **Unit tests (GUT)**, which are most tests: pure logic in `sim/` and `shared/` (formulas, leveling, inventory, loot, quests, codecs, rate limiters, state machines). Fast, no scene tree or a minimal one.
2. **Integration tests (GUT, headless)**: a real `WorldSim` + MapInstances driven through physics frames (movement determinism, combat resolution, portals, spawners), plus `LocalAuthority` end-to-end (intent → event).
3. **Network integration tests**: in-process server + client(s) over loopback ENet (`127.0.0.1`, random high port), and/or separate processes launched by `tools/test_net.sh`. Assert convergence, interest management, handshake failures.
4. **Backend tests (pytest)**: API, DB constraints, ticket security, concurrency (trades, saves).
5. **Bot/load tests**: `--bot` clients at scale (Phase 10+, Phase 15).
6. **Manual play-test scripts**: per phase, in `docs/CHANGELOG.md`.

### 12.2 Commands
```bash
# all Godot tests, headless (also in CI)
godot --headless --path game -s addons/gut/gut_cmdln.gd -gexit
# a single test script
godot --headless --path game -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_damage_formula.gd -gexit
# filter by test name
godot --headless --path game -s addons/gut/gut_cmdln.gd -gunit_test_name=crit -gexit
# headless smoke: boot LOCAL for N frames and quit (catches script errors in autoloads/scenes)
godot --headless --path game --quit-after 120
# data validation
python3 tools/build_index.py --check && python3 tools/validate_data.py
# backend
cd backend && uv run pytest -q
```

### 12.3 Rules
- Every bug fix starts with a failing test that reproduces it.
- Tests are deterministic: seeded RNG (`sim.seed_rng(42)`), no wall-clock dependence in sim (ticks only), and no real network in unit tests.
- Physics-dependent tests step inside physics frames (`await wait_physics_frames(n)`). Pure-logic tests never touch the scene tree.
- Use `add_child_autofree()` / `autofree()` in GUT so there are no orphan nodes (GUT reports orphans, so keep it at zero).
- Integration tests use dedicated test maps (`content/maps/test/*.tscn`) whose geometry is stable and documented (e.g. floor at y=320). Production maps can change freely.
- Coverage expectations: `sim/` and `shared/` logic ≥ 80% of public functions with at least one test. Every intent type has a validation test. Every event type has a routing test.

### 12.4 Network simulation
- **In-process:** a `LaggyTransport` test helper that queues outgoing packets with configurable delay, jitter, loss and duplication, used to test the Predictor/InterpolationBuffer/InputQueue without sockets.
- **OS-level:** `tools/netsim.sh` using `tc netem` on `lo` (or on the Docker bridge) for real-socket tests:
  ```bash
  sudo tc qdisc add dev lo root netem delay 80ms 20ms distribution normal loss 2% duplicate 0.5%
  sudo tc qdisc del dev lo root   # reset
  ```
- Standard profiles: `lan` (5 ms), `tailscale` (30 ms ± 5), `bad_wifi` (120 ms ± 40, 3% loss), `awful` (300 ms ± 100, 10% loss). Every networking PR is checked at least on `bad_wifi`.

### 12.5 Bot clients for load tests
- The client runs with `--bot --connect=host:port --bot-name=bot_017 [--bot-behavior=grind|wander|social]` headless (`--headless`, no rendering, presentation disabled), using the same `RemoteAuthority` and `InputSampler` interface fed by a `BotBrain` instead of the keyboard.
- `tools/bots/launch.sh N host port` launches N processes (or M processes × K bots each via multiple RemoteAuthority instances using separate `SceneMultiplayer` branches. Decide in Phase 10 based on RAM).
- Metrics: server tick avg/p99 per stage (input, AI, combat, snapshot build, send), CCU, bytes/s, memory. These are logged every 10 s as JSON and summarized by `tools/bots/report.py`.

---

## 13. Art & Audio Pipeline

### 13.1 Pixel art specs
| Asset | Size / grid | Notes |
|---|---|---|
| Base resolution | 640×360, integer-scaled (2×, 3×, 4×…) | `canvas_items` stretch + integer scale + pixel snap |
| Tiles | **16×16** | Tilesets as atlas PNGs, 1 px extrusion/padding to avoid bleeding |
| Player character | ~**24×40** visible body in a **48×48** cell | Leaves room for weapon swings |
| Small mobs | 16–32 px tall in **32×32** or **48×48** cells | |
| Large mobs / bosses | up to **128×128** cells | |
| Item icons | **24×24** (UI scales by integer) | Consistent 1 px outline style |
| UI | 9-slice panels with 4 px corners; pixel font 8 px / 16 px | OFL fonts only, credited |
| Palette | One project palette (e.g. 32–64 colours) in `content/palette.gpl` | Keeps the art coherent across contributors |
| Origins | Feet-centre pivot (bottom-centre of the cell) | Must match collision origins (entity origin = feet) |

### 13.2 Animation naming and frame counts
`<entity>_<action>[_<variant>]`: `player_idle`, `player_walk`, `player_jump`, `player_fall`, `player_climb_rope`, `player_climb_ladder`, `player_attack_swing`, `player_attack_stab`, `player_cast`, `player_hurt`, `player_dead`. Mobs: `idle`, `move`, `hurt`, `die`, `attack` (when applicable).
Suggested frames @ 10–12 fps: idle 4, walk 6–8, jump 2, fall 2, climb 4, attack 4–6 (hit frame matches `hit_frame_s`), hurt 2, die 6.

### 13.3 Aseprite workflow
- Source files: `art_src/**.aseprite` (Git LFS), one file per entity with **tags** named exactly like the animations.
- Export: `aseprite -b file.aseprite --sheet out.png --data out.json --format json-array --list-tags --sheet-type packed --trim false` (the `tools/art/export_all.sh` script runs it over all sources).
- Import: `tools/art/aseprite_to_spriteframes.gd` (`@tool` EditorScript) converts sheet + JSON to `SpriteFrames` `.tres` (one animation per tag, with frame durations preserved). Alternatively use a community Aseprite importer addon (Decision Log entry required).
- Never hand-edit generated `.tres` SpriteFrames. Re-export instead.

### 13.4 Character layering (plan now, build later)
MVP: a single body sprite + weapon sprite on a `WeaponAnchor` marker per frame (anchor positions exported as Aseprite slice data or a per-frame offset table). Later (Phase 17 cosmetics): layered paper-doll (body, face, hair, hat, top, bottom, shoes, weapon) with identical frame layouts across all layers. **Draw the base body on a fixed frame grid from day one**, so layering is possible later without redrawing.

### 13.5 Placeholder strategy
- Phases 0–13 use generated placeholders: colored rectangles/capsules with a facing indicator, mob silhouettes from simple shapes, and tile colours by type (solid = brown, one-way = tan, rope = yellow line, ladder = orange). The `tools/art/gen_placeholders.py` script generates PNGs so scenes reference real files that get swapped later **at the same paths and sizes**.
- Replacement happens by overwriting files at the same path with the same cell sizes and animation names, so no scene or data changes are needed.

### 13.6 Third-party assets & licensing
- Allowed: CC0 (best), CC-BY (credit required), or paid licenses that explicitly allow use in commercial games and modification. Many itch.io asset packs have custom licenses: **read each one** and save a copy of the license text in `content/licenses/<pack>.txt`.
- Not allowed: "free for personal use", NC (non-commercial), ripped or "fan" assets, anything from MapleStory/Nexon or other commercial games, or AI-generated assets that imitate a specific copyrighted style or character.
- Log every asset in `docs/ASSET_CREDITS.md`: file(s), author, source URL, license, date, modifications.

### 13.7 Audio pipeline
- Music: `.ogg` (Vorbis, 44.1 kHz, ~128–160 kbps), loop points set in the import settings. One track per region/map, plus login and boss tracks.
- SFX: `.wav` (16-bit, 44.1 kHz, mono for positional SFX), short and normalized to about -1 dBFS peak, consistent loudness across the set.
- Naming: `bgm_<area>`, `sfx_<category>_<name>` (`sfx_hit_blunt_01`, `sfx_ui_click`, `sfx_pickup_coin`), `amb_<area>`.
- Buses: Master → Music, SFX, UI, Ambience. Volume settings persist in `user://settings.cfg`.
- Sources: original compositions, CC0/CC-BY libraries, or licensed packs, all logged in ASSET_CREDITS.
- The server strips/ignores audio: never reference audio from `sim/` or `server/`.

---

## 14. Risks, Decision Log, Glossary

### 14.1 Risks & mitigations
| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| R1 | Scope creep (MMOs are huge) | High | High | Strict phases, MVP list (§2.3), Phase 17 backlog, milestone retros |
| R2 | Prediction mismatch between client and server movement | Medium | High | Same `MovementMotor` code, fixed 60 Hz, static-only collision for players, determinism tests in Phase 1, correction metrics |
| R3 | Rewrite when adding multiplayer | Low (by design) | Very high | LocalAuthority runs the real sim from Phase 0; codec round-trip mode; UI only via GameState |
| R4 | Godot version changes break APIs | Medium | Medium | Pin the version, upgrade only between milestones on a branch with the full test suite |
| R5 | Item duplication / economy exploits | Medium | High | Item uids, DB constraints, transactional trades, save_version, audit log, economy monitoring |
| R6 | Server performance limits CCU | Medium | Medium | Per-map interest management, AI think throttling, profiling in Phase 15, more channels |
| R7 | Data loss (homelab hardware) | Medium | Very high | 6-hourly backups + off-box copies + restore drills, healthchecks, graceful shutdown |
| R8 | Legal / IP issues | Low (if followed) | Very high | Original names/art only, asset credits, no ripped assets, §2.6 |
| R9 | Burnout / motivation | Medium | High | Playable result at every phase, M1 early, play-test with friends often |
| R10 | Cursor drifting from the architecture | Medium | High | §0 rules, one phase at a time, grep-based acceptance checks, Decision Log for changes |
| R11 | GDScript performance hot spots | Low–Medium | Medium | Typed code, avoid allocations in hot loops, profile; GDExtension only via the Decision Log |
| R12 | Security incident (credential stuffing, DoS) | Low (Tailscale) → Medium (public) | High | Tailscale-only alpha, rate limits, argon2, lockouts, DTLS/proxy before going public |

### 14.2 Decision log
Keep `docs/DECISIONS.md` as an ADR-lite list. **Template:**
```markdown
## D-0XX: <Short title>
- **Date:** YYYY-MM-DD
- **Status:** Proposed | Accepted | Superseded by D-0YY
- **Context:** What problem or force led to this decision?
- **Options considered:** A) … B) … C) …
- **Decision:** What we chose.
- **Consequences:** Trade-offs, follow-up tasks, what becomes harder/easier.
- **Revisit when:** Trigger that should make us reconsider.
```

**Initial decisions (copy into `docs/DECISIONS.md` in Phase 0, status Accepted):**
| ID | Decision |
|---|---|
| D-001 | One Godot 4.x project builds client and dedicated server (feature tags + export presets). Pinned version in `.godot-version`. |
| D-002 | Server-authoritative simulation. Single-player uses an in-process `LocalAuthority` running the same `WorldSim`. |
| D-003 | ENet over UDP via `ENetMultiplayerPeer` with all `@rpc`s on the `Net` autoload. Custom snapshot/input replication (no MultiplayerSynchronizer/Spawner). |
| D-004 | 60 Hz physics/sim tick, 20 Hz snapshots, 100 ms adaptive interpolation, client prediction + reconciliation for local movement only. |
| D-005 | Players collide only with static terrain (no player/mob body collision), which enables safe re-simulation. |
| D-006 | Ropes/ladders/hits use direct space queries, not Area2D signals. |
| D-007 | One World2D (SubViewport) per MapInstance for isolated physics. Many maps per channel process. |
| D-008 | Content as JSON + JSON Schema, loaded via `index.json` into typed defs. Never DirAccess discovery. |
| D-009 | Backend: custom FastAPI + PostgreSQL service (accounts, characters, tickets, persistence, trades), not Nakama. |
| D-010 | Join tickets: HMAC-SHA256, 30 s TTL, single-use redemption via the backend. One active session per account. |
| D-011 | Items have server-generated unique uids. Items are DB rows, and trades commit atomically in the DB before the sim applies them. |
| D-012 | `CharacterRecord` is the one save shape for local saves, the server, and the backend API, with versioned migrations. |
| D-013 | Deployment: Docker Compose on the homelab, Tailscale-only access during alpha. |
| D-014 | GUT for Godot tests, pytest for the backend, GitHub Actions CI with headless tests and exports. |
| D-015 | Flat platforms only (no slopes) in MVP. |
| D-016 | Currency name "Glimmer". Class names Novice/Vanguard/Arcanist/Ranger/Shade. All names original. |

### 14.3 Glossary
| Term | Meaning |
|---|---|
| **Authority** | The component that owns the true game state and validates intents (LocalAuthority in-process, or the dedicated server via RemoteAuthority). |
| **Intent** | A client request ("cast skill X", "pick up drop Y"). Never trusted; validated by the sim. |
| **SimEvent** | An authoritative result emitted by the sim (damage, EXP, inventory change). |
| **InputFrame** | One tick of movement input (axes + buttons), sequence-numbered. |
| **Snapshot** | Periodic (20 Hz) compact state of nearby entities + the receiving player's motor state. |
| **Client-side prediction** | The client simulates its own movement immediately instead of waiting for the server. |
| **Reconciliation** | Resetting to the server state and replaying unacknowledged inputs when a snapshot arrives. |
| **Interpolation** | Rendering remote entities slightly in the past, blending between snapshots for smoothness. |
| **Interest management** | Only sending a client the entities relevant to it (here: same map). |
| **eid** | Runtime entity id, allocated by WorldSim, not persistent. |
| **uid** | Persistent unique id of an item instance. |
| **Channel** | One game server process hosting all maps of a world. Players pick a channel. |
| **MapInstance** | A loaded map inside the sim with its own physics space. |
| **Tick** | One fixed simulation step (1/60 s). |
| **AP / SP** | Ability Points (stats) / Skill Points, granted per level. |
| **Job advancement** | Changing from Novice to a class (and later to higher tiers). |
| **Claim window** | The time during which only the killer (or their party) can pick up a drop. |
| **PQ** | Party Quest: an instanced cooperative stage challenge. |
| **CCU** | Concurrent users. |
| **Mesos-equivalent** | Our in-game currency, **Glimmer**. |
| **GUT** | Godot Unit Test framework. |
| **Headless** | Running Godot without a display/GPU (servers, CI). |

---

## 15. Appendices

### 15.1 Protocol message table (mirror in `docs/PROTOCOL.md`)
**RPCs (all on `/root/Net`)**
| RPC | Direction | Mode / channel | Payload |
|---|---|---|---|
| `c2s_hello` | C→S | reliable / 0 | `protocol_version: int, ticket: String` |
| `c2s_inputs` | C→S | unreliable_ordered / 1 | `PackedByteArray` (u8 count + up to 3 × 6-byte InputFrames) |
| `c2s_intent` | C→S | reliable / 0 | `[type, client_seq, args[]]` |
| `c2s_ping` | C→S | unreliable / 0 | `client_time_ms: int` |
| `s2c_welcome` | S→C | reliable / 0 | `self_eid: int, map_id: String, server_tick: int` |
| `s2c_snapshot` | S→C | unreliable_ordered / 2 | `PackedByteArray` (§9.10 layout) |
| `s2c_event` | S→C | reliable / 0 | `[type, tick, data[]]` |
| `s2c_pong` | S→C | unreliable / 0 | `client_time_ms: int, server_tick: int` |
| `s2c_disconnect_reason` | S→C | reliable / 0 | `reason: Protocol.Disconnect` |

**Intents** (`Protocol.IntentType`) and args
| Intent | Args | Validation highlights |
|---|---|---|
| CAST | `skill_id: String, facing: int` | Known skill, level>0, can act, cooldown, MP, facing ∈ {-1,1} |
| PICKUP | `drop_eid: int` (0 = nearest) | Distance ≤ 48 px, claim window, inventory space |
| USE_ITEM | `tab: int, slot: int` | Slot has a use item, item cooldown, not dead |
| EQUIP / UNEQUIP | `tab, slot` / `equip_slot: String` | Requirements, space for the swapped item |
| MOVE_ITEM | `tab, from_slot, to_slot, qty` | Ranges, same tab, qty ≤ stack |
| DROP_ITEM | `tab, slot, qty` or currency amount | Tradeable, not in town (optional rule), amount ≤ owned |
| ALLOC_AP / ALLOC_SP | `stat: String` / `skill_id: String` | Points available, valid targets, max levels |
| TALK / DIALOGUE_CHOICE | `npc_eid` / `choice_idx` | Distance ≤ 80 px, an active dialogue, valid index, action preconditions |
| BUY / SELL | `shop_id, item_id, qty` / `tab, slot, qty` | Shop open and NPC nearby, currency, space, sellable |
| ENTER_PORTAL | — | Overlapping a portal area, not casting/dead |
| RESPAWN | — | Dead |
| CHAT | `channel: int, text: String, target: String` | Length ≤ 120, rate limit, mute, target exists |
| SET_KEYBIND | `key: String, binding: String` | Known key, binding references an owned skill/item |
| PARTY_* / TRADE_* / FRIEND_* | see Phase 12 | State machine checks, distance (trade), limits |

**Events** (`Protocol.EventType`): see §9.10. Each event documents its `data` array layout in `docs/PROTOCOL.md` (e.g. `DAMAGE: [attacker_eid, target_eid, amount, crit:bool, hit_index]`).

### 15.2 Collision layers & masks
| # | Name | Used by | Typical mask of the user |
|---|---|---|---|
| 1 | world | Ground/walls TileMapLayer | — |
| 2 | platform_oneway | "Platforms" TileMapLayer (group `oneway_platforms`) | — |
| 3 | player_body | PlayerEntity | world, platform_oneway |
| 4 | mob_body | MobEntity | world, platform_oneway, mob_wall |
| 5 | player_hurtbox | Player Hurtbox (Area2D) | (queried by mob attacks/contact) |
| 6 | mob_hurtbox | Mob Hurtbox (Area2D) | (queried by player attacks/projectiles) |
| 7 | climbable | Rope/ladder Area2D | (queried by ClimbQuery) |
| 8 | portal | Portal Area2D | (queried on ENTER_PORTAL) |
| 9 | drop | DropEntity | world, platform_oneway |
| 10 | npc | NpcEntity | (queried on TALK) |
| 11 | projectile | ProjectileEntity (query-based movement) | world (optional), mob_hurtbox via query |
| 12 | mob_wall | Invisible StaticBody2D/Area2D limits for mobs | — |

### 15.3 Default input map (registered by `keybinds.gd`, remappable)
| Action | Default keys | Gamepad |
|---|---|---|
| move_left / move_right | ←/→, A/D | D-pad / left stick |
| move_up / move_down | ↑/↓, W/S | D-pad / left stick |
| jump | Alt, Space | A / Cross |
| attack | Ctrl, J | X / Square |
| pickup | Z | Y / Triangle |
| interact (talk/portal) | ↑ (contextual), F | B / Circle |
| skill_1 … skill_8 | Q, W*, E, R, 1–4 (*W conflicts with move_up when WASD is on; the rebind UI resolves it) | Shoulders + face buttons (later) |
| toggle_inventory | I | Select |
| toggle_equipment | E (alt: U) | — |
| toggle_stats | S (alt: T) | — |
| toggle_skills | K | — |
| toggle_quests | L | — |
| toggle_chat | Enter | — |
| toggle_minimap | M | — |
| debug_overlay | F3 | — |
| menu / close | Esc | Start |

> Arrow keys + Alt/Ctrl are the genre-classic layout and are the default profile. A WASD profile is offered in settings.

### 15.4 Ports & endpoints
| Service | Port | Protocol | Exposure |
|---|---|---|---|
| gameserver-ch1 | 7777 | UDP (ENet) | Tailscale (alpha) → public later |
| gameserver-ch2 | 7778 | UDP (ENet) | same |
| backend | 8080 | HTTP (REST) | Tailscale; behind HTTPS proxy (443) when public |
| postgres | 5432 | TCP | Docker network only (never published) |
| uptime monitor | 3001 | HTTP | Tailscale only |

### 15.5 Definition of Done (applies to every task)
- [ ] Code follows §8 (typed, under size limits, correct layer).
- [ ] Tests written and passing (`make test`). Data validated (`make validate`) if data changed.
- [ ] Headless smoke run has no errors (`godot --headless --path game --quit-after 120`).
- [ ] No new warnings. No `print()` debugging left (use `Log`).
- [ ] Checkbox ticked in this document. Commit message follows Conventional Commits.
- [ ] If an architecture assumption changed: a Decision Log entry exists.

---

*End of BUILD_SCOPE.md. Keep this document current: it's the contract between you and the coding agent.*
