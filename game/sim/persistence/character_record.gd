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
var max_hp: int = 50
var mp: int = 5
var max_mp: int = 5
var currency: int = 0
var map_id: StringName = &"map_test_movement"
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
	r.map_id = &"map_test_movement"
	return r


func to_dict() -> Dictionary:
	return {
		"record_version": RECORD_VERSION,
		"character_id": character_id,
		"name": name,
		"class_id": String(class_id),
		"level": level,
		"exp": exp,
		"stats": stats.duplicate(),
		"ap": ap,
		"sp": sp,
		"hp": hp,
		"max_hp": max_hp,
		"mp": mp,
		"max_mp": max_mp,
		"currency": currency,
		"map_id": String(map_id),
		"spawn_portal": String(spawn_portal),
		"skills": skills.duplicate(),
		"inventory": inventory.duplicate(true),
		"equipped": equipped.duplicate(true),
		"quests": quests.duplicate(true),
		"keybinds": keybinds.duplicate(),
		"save_version": save_version,
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
	r.max_hp = int(d.get("max_hp", maxi(r.hp, 50)))
	r.mp = int(d.get("mp", 5))
	r.max_mp = int(d.get("max_mp", maxi(r.mp, 5)))
	r.currency = int(d.get("currency", 0))
	r.map_id = StringName(d.get("map_id", "map_test_movement"))
	r.spawn_portal = StringName(d.get("spawn_portal", "spawn"))
	r.skills = d.get("skills", {})
	r.inventory = d.get("inventory", r.inventory)
	r.equipped = d.get("equipped", {})
	r.quests = d.get("quests", {})
	r.keybinds = d.get("keybinds", {})
	r.save_version = int(d.get("save_version", 0))
	return r
