class_name Intent
extends RefCounted
## A request from a player to the authority. Never trusted; always validated by the sim.

var type: int = 0
var client_seq: int = 0
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


static func respawn() -> Intent:
	return make(Protocol.IntentType.RESPAWN, [])


func to_wire() -> Array:
	return [type, client_seq, args]


static func from_wire(w: Variant) -> Intent:
	if typeof(w) != TYPE_ARRAY:
		return null
	var a: Array = w
	if a.size() != 3 or typeof(a[0]) != TYPE_INT or typeof(a[1]) != TYPE_INT or typeof(a[2]) != TYPE_ARRAY:
		return null
	if (a[2] as Array).size() > 8:
		return null
	var i := Intent.new()
	i.type = int(a[0])
	i.client_seq = int(a[1])
	i.args = a[2]
	return i
