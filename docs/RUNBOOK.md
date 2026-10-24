# Runbook

Ops notes. Expand in Phase 9 (netsim) and Phase 16 (deploy).

## Local

First-time (or after a ZIP download): import the Godot project **before** Play. A grey window with `SCRIPT ERROR: Could not find type "StatsConfig"` is a failed first launch, not a pass.

```powershell
# Windows PowerShell, from the repo root
$godot = "C:\path\to\Godot_v4.7.2-stable_win64_console.exe"
& $godot --headless --import --path game
& $godot --path game
```

Or: `.\scripts\run-local.ps1 -Godot $godot`

Or open the `game/` folder in the Godot editor (Import), wait until import finishes, then press Play.

- Client (LOCAL): `make run` (Linux/macOS) or `.\scripts\run-local.ps1 -Godot $godot`
- Dedicated server: `make server` (UDP 7777)
- Tests: `make test`
- Data: `make validate`

Pass looks like: grey floor **and** `[INFO] client: entered_map map_test_flat eid=1` with no `SCRIPT ERROR`.

## Env names

`SKYROPE_DEV_TICKETS`, `SKYROPE_BACKEND_URL` / `BACKEND_URL`, `DATABASE_URL`, `SERVICE_TOKEN`, `TICKET_HMAC_SECRET`, `SKYROPE_PORT`, `SKYROPE_CHANNEL`, `SKYROPE_DATA_DIR`

## Netsim (Phase 9)

`tools/netsim.sh` — `tc netem` on loopback. Not implemented until Phase 9.

## Deploy (Phase 16)

`make up` / `make down` once `docker/docker-compose.yml` exists.
