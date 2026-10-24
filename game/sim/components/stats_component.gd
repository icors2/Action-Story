class_name StatsComponent
extends Component
## Base stats + equipment + buffs -> derived totals. Recalculate on any change.

signal changed()

const PRIMARY: Array[StringName] = [&"str", &"dex", &"int", &"luk"]

var level: int = 1
var class_id: StringName = &"novice"
var base: Dictionary = {&"str": 4, &"dex": 4, &"int": 4, &"luk": 4}
var equip_bonus: Dictionary = {}
var buff_bonus: Dictionary = {}
var totals: Dictionary = {}


func on_attached() -> void:
	recalculate()


func recalculate() -> void:
	totals.clear()
	for src: Dictionary in [base, equip_bonus, buff_bonus]:
		for key: Variant in src.keys():
			var k: StringName = key as StringName if key is StringName else StringName(str(key))
			totals[k] = int(totals.get(k, 0)) + int(src[key])
	var cfg: StatsConfig = DataRegistry.stats
	if cfg:
		if not totals.has(&"weapon_attack"):
			totals[&"weapon_attack"] = cfg.base_weapon_attack
		if not totals.has(&"defense"):
			totals[&"defense"] = cfg.base_defense
		totals[&"crit_rate"] = cfg.crit_base_rate + float(totals.get(&"luk", 0)) * 0.0005
	changed.emit()


func get_total(key: StringName) -> int:
	return int(totals.get(key, 0))


func get_float(key: StringName) -> float:
	return float(totals.get(key, 0.0))


func primary_stat() -> int:
	return get_total(&"str")


func secondary_stat() -> int:
	return get_total(&"dex")
