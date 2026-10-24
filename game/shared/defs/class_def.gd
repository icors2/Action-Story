class_name ClassDef
extends BaseDef
## Job / class definition from classes.json.

var display_name: String = ""
var tier: int = 0
var parent_id: StringName = &""
var primary_stat: StringName = &"str"
var secondary_stat: StringName = &"dex"
var advance_level: int = 0
var advance_quest: StringName = &""
var hp_per_level: Vector2i = Vector2i(12, 16)
var mp_per_level: Vector2i = Vector2i(4, 8)
var starting_skills: Array[StringName] = []
var allowed_weapon_types: Array[StringName] = []
var advance_requirements: Dictionary = {}


static func from_dict(d: Dictionary) -> ClassDef:
	var c := ClassDef.new()
	c.id = StringName(d["id"])
	c.display_name = String(d.get("name", d["id"]))
	c.tier = int(d.get("tier", 0))
	var parent: Variant = d.get("parent", "")
	c.parent_id = StringName(str(parent)) if parent != null and str(parent) != "" else &""
	c.primary_stat = StringName(d.get("primary_stat", "str"))
	c.secondary_stat = StringName(d.get("secondary_stat", "dex"))
	c.advance_level = int(d.get("advance_level", 0))
	c.advance_quest = StringName(d.get("advance_quest", ""))
	var hp: Array = d.get("base_hp_per_level", [12, 16])
	c.hp_per_level = Vector2i(int(hp[0]), int(hp[1] if hp.size() > 1 else hp[0]))
	var mp: Array = d.get("base_mp_per_level", [4, 8])
	c.mp_per_level = Vector2i(int(mp[0]), int(mp[1] if mp.size() > 1 else mp[0]))
	for s: Variant in d.get("starting_skills", []):
		c.starting_skills.append(StringName(str(s)))
	for w: Variant in d.get("allowed_weapon_types", []):
		c.allowed_weapon_types.append(StringName(str(w)))
	c.advance_requirements = d.get("advance_requirements", {})
	return c
