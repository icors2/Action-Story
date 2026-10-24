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
var hit_spacing_ticks: int = 6
var required_skills: Dictionary = {}
var levels: Dictionary = {}
var knockback: Vector2 = Vector2.ZERO
var buff: Dictionary = {}
var projectile_speed: float = 220.0
var projectile_lifetime_ticks: int = 48


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
	s.hit_spacing_ticks = maxi(1, int(float(d.get("hit_spacing_s", 0.1)) * NetConfig.TICK_RATE))
	s.required_skills = d.get("required_skills", {})
	s.levels = d.get("levels", {})
	var kb: Array = d.get("knockback", [0, 0])
	s.knockback = Vector2(float(kb[0]), float(kb[1]))
	s.buff = d.get("buff", {})
	var proj: Dictionary = d.get("projectile", {})
	if not proj.is_empty():
		s.projectile_speed = float(proj.get("speed", s.projectile_speed))
		s.projectile_lifetime_ticks = int(float(proj.get("lifetime_s", 0.8)) * NetConfig.TICK_RATE)
	return s


func value(key: String, skill_level: int) -> float:
	return BaseDef.level_value(levels.get(key, 0), skill_level, max_level)
