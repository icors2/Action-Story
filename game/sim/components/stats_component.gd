class_name StatsComponent
extends Component
## Base stats + equipment + buffs + passives -> derived totals.

signal changed()

const PRIMARY: Array[StringName] = [&"str", &"dex", &"int", &"luk"]

var level: int = 1
var class_id: StringName = &"novice"
var base: Dictionary = {&"str": 4, &"dex": 4, &"int": 4, &"luk": 4}
var equip_bonus: Dictionary = {}
var buff_bonus: Dictionary = {}
var passive_bonus: Dictionary = {}
var totals: Dictionary = {}


func on_attached() -> void:
	recalculate()


func recalculate() -> void:
	totals.clear()
	for src: Dictionary in [base, equip_bonus, buff_bonus, passive_bonus]:
		for key: Variant in src.keys():
			var k: StringName = key as StringName if key is StringName else StringName(str(key))
			totals[k] = int(totals.get(k, 0)) + int(src[key])
	var cfg: StatsConfig = DataRegistry.stats
	if cfg:
		totals[&"weapon_attack"] = int(totals.get(&"weapon_attack", 0)) + cfg.base_weapon_attack
		totals[&"defense"] = int(totals.get(&"defense", 0)) + cfg.base_defense
		totals[&"crit_rate"] = cfg.crit_base_rate + float(totals.get(&"luk", 0)) * 0.0005
	changed.emit()


func get_total(key: StringName) -> int:
	return int(totals.get(key, 0))


func get_float(key: StringName) -> float:
	return float(totals.get(key, 0.0))


func primary_stat() -> int:
	var cdef: ClassDef = DataRegistry.classes.get(class_id)
	if cdef:
		return get_total(cdef.primary_stat)
	return get_total(&"str")


func secondary_stat() -> int:
	var cdef: ClassDef = DataRegistry.classes.get(class_id)
	if cdef:
		return get_total(cdef.secondary_stat)
	return get_total(&"dex")


func recalculate_passives(player: PlayerEntity) -> void:
	passive_bonus.clear()
	for key: Variant in player.known_skills.keys():
		var sid: StringName = StringName(str(key))
		var lv: int = int(player.known_skills[key])
		if lv < 1:
			continue
		var skill: SkillDef = DataRegistry.skills.get(sid)
		if skill == null or skill.type != &"passive":
			continue
		var stat: StringName = StringName(str(skill.buff.get("stat", "")))
		if stat == &"":
			continue
		passive_bonus[stat] = int(passive_bonus.get(stat, 0)) + int(
			BaseDef.level_value(skill.buff.get("add", 0), lv, skill.max_level)
		)
	recalculate()
