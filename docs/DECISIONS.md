# Decision log

ADR-lite. Status: Proposed | Accepted | Superseded.

## D-019: Canonical GitHub repo is icors2/Action-Story

- **Date:** 2026-10-17
- **Status:** Accepted
- **Context:** The local tree started as a Cursor_Forge clone. The product needs its own remote.
- **Options considered:** A) Keep Cursor_Forge B) https://github.com/icors2/Action-Story C) New private repo
- **Decision:** B. `origin` is Action-Story. Issues/PRs/CI/releases go there.
- **Consequences:** Cursor_Forge stays a template only. Product clone URL is Action-Story.
- **Revisit when:** Public brand/name changes.

## D-017: Pin Godot 4.7.2-stable; typed Dictionary allowed

- **Date:** 2026-10-17
- **Status:** Accepted
- **Context:** BUILD_SCOPE requires one pinned 4.x stable in `.godot-version`. §8.2 forbids typed `Dictionary[K, V]` unless the pin supports it.
- **Options considered:** A) 4.3 minimum B) 4.4.1 example in spec C) 4.7.2-stable D) 4.8-beta1
- **Decision:** C. Typed dictionaries are allowed.
- **Consequences:** GUT must be 9.7.x (vendored 9.7.1). Upgrade only between milestones.
- **Revisit when:** Next Godot minor after a milestone.

## D-016: Original names

- **Date:** 2026-10-17
- **Status:** Accepted
- **Context:** Legal: no MapleStory/Nexon expression.
- **Decision:** Currency **Glimmer**. Classes Novice / Vanguard / Arcanist / Ranger / Shade. Towns e.g. Bramblewick.
- **Revisit when:** Rename pass before public branding.

## D-015: Flat platforms only in MVP

- **Date:** 2026-10-17
- **Status:** Accepted
- **Context:** Slope snap vs prediction determinism.
- **Decision:** No slopes in MVP.
- **Revisit when:** Art needs ramps.

## D-014: GUT + pytest + GitHub Actions

- **Date:** 2026-10-17
- **Status:** Accepted
- **Decision:** GUT 9.7.1 vendored for Godot tests. pytest for backend (Phase 11). CI: data + godot jobs in Phase 0; backend/docker jobs when those trees exist.

## D-013: Homelab Docker + Tailscale alpha

- **Date:** 2026-10-17
- **Status:** Accepted
- **Decision:** Compose on Linux homelab. Tailscale-only until Phase 16 public profile.

## D-012: One CharacterRecord shape

- **Date:** 2026-10-17
- **Status:** Accepted
- **Decision:** Local saves, server, and backend share `CharacterRecord` JSON with versioned migrations.

## D-011: Item uids and transactional trades

- **Date:** 2026-10-17
- **Status:** Accepted
- **Decision:** Server-generated item uids. Items are DB rows. Trades commit in the DB before the sim applies them.

## D-010: HMAC join tickets

- **Date:** 2026-10-17
- **Status:** Accepted
- **Decision:** HMAC-SHA256 tickets, 30 s TTL, single-use redemption. One active session per account.

## D-009: Custom FastAPI + Postgres, not Nakama

- **Date:** 2026-10-17
- **Status:** Accepted
- **Decision:** Accounts, characters, tickets, persistence, trades in one schema we own.

## D-008: JSON + Schema via index.json

- **Date:** 2026-10-17
- **Status:** Accepted
- **Decision:** Content is JSON. Never DirAccess discovery. Export `include_filter` must list JSON.

## D-007: World2D per MapInstance

- **Date:** 2026-10-17
- **Status:** Accepted
- **Decision:** Isolated physics per map. Many maps per channel process.

## D-006: Space queries for ropes and hits

- **Date:** 2026-10-17
- **Status:** Accepted
- **Decision:** Direct space queries, not Area2D signals (re-simulation).

## D-005: Players collide only with static terrain

- **Date:** 2026-10-17
- **Status:** Accepted
- **Decision:** No player-player or player-mob body collision. Enables safe movement re-sim.

## D-004: Tick and snapshot rates

- **Date:** 2026-10-17
- **Status:** Accepted
- **Decision:** 60 Hz physics/sim, 20 Hz snapshots, 100 ms adaptive interpolation, predict local movement only.

## D-003: ENet + custom snapshots

- **Date:** 2026-10-17
- **Status:** Accepted
- **Decision:** `ENetMultiplayerPeer` + `@rpc` on `Net` only. No MultiplayerSynchronizer/Spawner.

## D-002: Server-authoritative LocalAuthority

- **Date:** 2026-10-17
- **Status:** Accepted
- **Decision:** Single-player runs the same `WorldSim` in-process via `LocalAuthority`.

## D-001: One Godot project for client and server

- **Date:** 2026-10-17
- **Status:** Accepted
- **Decision:** `game/` builds both via export presets and feature tags. Pinned in `.godot-version`.

## D-021: Movement feel v1

- **Date:** 2026-10-24
- **Status:** Accepted
- **Context:** Phase 1 acceptance: jump ~3.5 tiles, snappy run, usable ropes.
- **Decision:** `stats.json` movement: walk 125, accel 1400, decel 1800, air_control 0.2, jump_velocity -330, gravity 1000, max_fall 600, climb_speed 80, coyote 5, jump buffer 6, drop-through 12 ticks.
- **Revisit when:** Play-test says jump/run feels wrong.

## D-020: Phase 1 default map is map_test_movement

- **Date:** 2026-10-24
- **Status:** Accepted
- **Context:** LOCAL play-test must boot the movement yard.
- **Decision:** `CharacterRecord.new_default` map_id is `map_test_movement`. `map_test_flat` remains for regression.
- **Revisit when:** Phase 5 town maps ship.

## D-018: Phase 0 default map is map_test_flat

- **Date:** 2026-10-17
- **Status:** Superseded by D-020
- **Context:** `CharacterRecord.new_default` in the spec used `town_bramblewick`, which does not exist until Phase 5.
- **Decision:** Default `map_id` is `map_test_flat` until town content exists.
- **Revisit when:** Phase 5 maps ship.
