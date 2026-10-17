class_name SkillDef
extends BaseDef

var display_name: String = ""
var class_id: StringName = &""
var type: StringName = &"active_attack"
var max_level: int = 1
var animation: StringName = &"attack_swing"
var cast_ticks: int = 24
var hit_tick: int = 9
var hitbox_offset: Vector2 = Vector2.ZERO
var hitbox_size: Vector2 = Vector2.ZERO
var max_targets: int = 1
var hits: int = 1
var levels: Dictionary = {}
var knockback: Vector2 = Vector2.ZERO
var buff: Dictionary = {}


static func from_dict(d: Dictionary) -> SkillDef:
	var s := SkillDef.new()
	s.id = StringName(d["id"])
	s.display_name = String(d["name"])
	s.class_id = StringName(d["class"])
	s.type = StringName(d["type"])
	s.max_level = int(d["max_level"])
	s.animation = StringName(d.get("animation", "attack_swing"))
	s.cast_ticks = int(float(d.get("cast_time_s", 0.4)) * NetConfig.TICK_RATE)
	s.hit_tick = int(float(d.get("hit_frame_s", 0.15)) * NetConfig.TICK_RATE)
	var hb: Dictionary = d.get("hitbox", {})
	if not hb.is_empty():
		s.hitbox_offset = Vector2(float(hb["offset"][0]), float(hb["offset"][1]))
		s.hitbox_size = Vector2(float(hb["size"][0]), float(hb["size"][1]))
	s.max_targets = int(d.get("max_targets", 1))
	s.hits = int(d.get("hits", 1))
	s.levels = d.get("levels", {})
	var kb: Array = d.get("knockback", [0, 0])
	s.knockback = Vector2(float(kb[0]), float(kb[1]))
	s.buff = d.get("buff", {})
	return s


func value(key: String, skill_level: int) -> float:
	return BaseDef.level_value(levels.get(key, 0), skill_level, max_level)
