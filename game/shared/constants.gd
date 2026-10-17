class_name Const
## Project-wide enums and physics layer helpers.

enum EntityKind { PLAYER, MOB, DROP, PROJECTILE, NPC, PORTAL }

enum Layer {
	WORLD = 1,
	PLATFORM_ONEWAY = 2,
	PLAYER_BODY = 3,
	MOB_BODY = 4,
	PLAYER_HURTBOX = 5,
	MOB_HURTBOX = 6,
	CLIMBABLE = 7,
	PORTAL = 8,
	DROP = 9,
	NPC = 10,
	PROJECTILE = 11,
	MOB_WALL = 12,
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
