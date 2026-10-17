# Protocol

Mirror of BUILD_SCOPE §15.1. Bump `Protocol.VERSION` on any breaking change.

All RPCs live on `/root/Net`. Gameplay never calls `multiplayer` directly.

## RPCs

| RPC | Direction | Mode / channel | Payload |
| --- | --- | --- | --- |
| `c2s_hello` | C→S | reliable / 0 | `protocol_version: int, ticket: String` |
| `c2s_inputs` | C→S | unreliable_ordered / 1 | `PackedByteArray` (u8 count + up to 3 × 6-byte InputFrames) |
| `c2s_intent` | C→S | reliable / 0 | `[type, client_seq, args[]]` |
| `c2s_ping` | C→S | unreliable / 0 | `client_time_ms: int` |
| `s2c_welcome` | S→C | reliable / 0 | `self_eid: int, map_id: String, server_tick: int` |
| `s2c_snapshot` | S→C | unreliable_ordered / 2 | `PackedByteArray` (§9.10 layout) |
| `s2c_event` | S→C | reliable / 0 | `[type, tick, data[]]` |
| `s2c_pong` | S→C | unreliable / 0 | `client_time_ms: int, server_tick: int` |
| `s2c_disconnect_reason` | S→C | reliable / 0 | `reason: Protocol.Disconnect` |

## Intents (`Protocol.IntentType`)

| Intent | Args |
| --- | --- |
| CAST | `skill_id: String, facing: int` |
| PICKUP | `drop_eid: int` (0 = nearest) |
| USE_ITEM | `tab: int, slot: int` |
| EQUIP / UNEQUIP | `tab, slot` / `equip_slot: String` |
| MOVE_ITEM | `tab, from_slot, to_slot, qty` |
| DROP_ITEM | `tab, slot, qty` or currency amount |
| ALLOC_AP / ALLOC_SP | `stat: String` / `skill_id: String` |
| TALK / DIALOGUE_CHOICE | `npc_eid` / `choice_idx` |
| BUY / SELL | `shop_id, item_id, qty` / `tab, slot, qty` |
| ENTER_PORTAL | — |
| RESPAWN | — |
| CHAT | `channel: int, text: String, target: String` |
| SET_KEYBIND | `key: String, binding: String` |
| PARTY_* / TRADE_* / FRIEND_* | Phase 12 |

## Events (`Protocol.EventType`)

`DAMAGE` data: `[attacker_eid, target_eid, amount, crit:bool, hit_index]`

See `game/shared/net/protocol.gd` for the full enum. Do not renumber.
