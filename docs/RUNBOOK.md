# Runbook

Ops notes. Expand in Phase 9 (netsim) and Phase 16 (deploy).

## Local

- Client (LOCAL): `make run` — Phase 1 map is `map_test_movement` (arrows/WASD, Space jump)
- Dedicated server: `make server` (UDP 7777)
- Tests: `make test`
- Data: `make validate`

Windows: `& "C:\path\to\Godot_v4.7.2-stable_win64.exe" --path game` from the repo root. Import `game/` once first.

## Env names

`SKYROPE_DEV_TICKETS`, `SKYROPE_BACKEND_URL` / `BACKEND_URL`, `DATABASE_URL`, `SERVICE_TOKEN`, `TICKET_HMAC_SECRET`, `SKYROPE_PORT`, `SKYROPE_CHANNEL`, `SKYROPE_DATA_DIR`

## Netsim (Phase 9)

`tools/netsim.sh` — `tc netem` on loopback. Not implemented until Phase 9.

## Deploy (Phase 16)

`make up` / `make down` once `docker/docker-compose.yml` exists.
