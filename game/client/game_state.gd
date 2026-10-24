extends Node
## Client-side view model of the local player. Read-only mirror of authority data.

var self_eid: int = 0
var hp: int = 50
var max_hp: int = 50
var mp: int = 5
var max_mp: int = 5
var dead: bool = false
var last_cast_seq: int = 0
var self_pos: Vector2 = Vector2.ZERO
var invuln_until: float = 0.0
var level: int = 1
var exp: int = 0
var ap: int = 0
var sp: int = 0
var class_id: StringName = &"novice"
var stat_str: int = 4
var stat_dex: int = 4
var stat_int: int = 4
var stat_luk: int = 4
var skills: Dictionary = {}
var buffs: Dictionary = {}
var last_reject: int = 0
var last_system: String = ""
var chat_open: bool = false


func _ready() -> void:
	if Config.is_server():
		return


func apply_record_view(d: Dictionary) -> void:
	level = int(d.get("level", 1))
	exp = int(d.get("exp", 0))
	ap = int(d.get("ap", 0))
	sp = int(d.get("sp", 0))
	class_id = StringName(d.get("class_id", "novice"))
	var st: Dictionary = d.get("stats", {})
	stat_str = int(st.get("str", 4))
	stat_dex = int(st.get("dex", 4))
	stat_int = int(st.get("int", 4))
	stat_luk = int(st.get("luk", 4))
	skills = d.get("skills", {}).duplicate()
	apply_vitals(
		int(d.get("hp", 50)),
		int(d.get("max_hp", 50)),
		int(d.get("mp", 5)),
		int(d.get("max_mp", 5))
	)


func apply_vitals(p_hp: int, p_max_hp: int, p_mp: int, p_max_mp: int) -> void:
	hp = p_hp
	max_hp = p_max_hp
	mp = p_mp
	max_mp = p_max_mp
	dead = hp <= 0


func apply_stats(
		p_level: int,
		p_class: StringName,
		p_str: int,
		p_dex: int,
		p_int: int,
		p_luk: int,
		p_ap: int,
		p_sp: int,
		p_skills: Dictionary = {}
	) -> void:
	level = p_level
	class_id = p_class
	stat_str = p_str
	stat_dex = p_dex
	stat_int = p_int
	stat_luk = p_luk
	ap = p_ap
	sp = p_sp
	if not p_skills.is_empty():
		skills = p_skills.duplicate()


func apply_exp(p_amount: int, p_level: int, p_exp: int) -> void:
	level = p_level
	exp = p_exp
	if p_amount != 0:
		last_system = ("+%d EXP" % p_amount) if p_amount > 0 else ("%d EXP" % p_amount)


func apply_buff(stat: String, amount: int, ticks: int) -> void:
	buffs[stat] = {"amount": amount, "ticks": ticks}


func clear_buff(stat: String) -> void:
	buffs.erase(stat)


func extra_cast_skill(index: int) -> StringName:
	var extras: Array[StringName] = []
	for key: Variant in skills.keys():
		var sid: StringName = key as StringName if key is StringName else StringName(str(key))
		if int(skills[key]) < 1:
			continue
		var skill: SkillDef = DataRegistry.skills.get(sid)
		if skill == null or skill.type == &"passive" or skill.id == &"novice_strike":
			continue
		extras.append(skill.id)
	if index < 0 or index >= extras.size():
		return &""
	return extras[index]


func first_sp_skill() -> StringName:
	var fallback: StringName = &""
	for key: Variant in skills.keys():
		var sid: StringName = key as StringName if key is StringName else StringName(str(key))
		var skill: SkillDef = DataRegistry.skills.get(sid)
		if skill == null or skill.class_id != class_id:
			continue
		var lv: int = int(skills[key])
		if lv >= skill.max_level:
			continue
		if lv == 0:
			return sid
		if fallback == &"":
			fallback = sid
	return fallback


func exp_to_next() -> int:
	return Leveling.exp_to_next(level, DataRegistry.level_table)


func mark_hit() -> void:
	invuln_until = Time.get_ticks_msec() / 1000.0 + DataRegistry.stats.invincibility_after_hit_s
