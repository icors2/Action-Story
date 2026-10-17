class_name MobDef
extends BaseDef

var display_name: String = ""
var level: int = 1
var hp: int = 1
var weapon_attack: int = 0
var defense: int = 0
var accuracy: int = 0
var avoid: int = 0
var exp: int = 0
var move_speed: float = 0.0
var chase_speed: float = 0.0
var can_jump: bool = false
var behavior: StringName = &""
var aggro_range: float = 0.0
var contact_damage: bool = true
var knockback_resist: float = 0.0
var drop_table: StringName = &""
var scene_path: String = ""
var body_size: Vector2 = Vector2(16, 16)
var respawn_ticks: int = 60


static func from_dict(d: Dictionary) -> MobDef:
	var m := MobDef.new()
	m.id = StringName(d["id"])
	m.display_name = String(d["name"])
	m.level = int(d["level"])
	m.hp = int(d["hp"])
	m.weapon_attack = int(d["weapon_attack"])
	m.defense = int(d["defense"])
	m.accuracy = int(d.get("accuracy", 0))
	m.avoid = int(d.get("avoid", 0))
	m.exp = int(d["exp"])
	m.move_speed = float(d["move_speed"])
	m.chase_speed = float(d.get("chase_speed", d["move_speed"]))
	m.can_jump = bool(d.get("jump", false))
	m.behavior = StringName(d["behavior"])
	m.aggro_range = float(d.get("aggro_range", 0.0))
	m.contact_damage = bool(d.get("contact_damage", true))
	m.knockback_resist = float(d.get("knockback_resist", 0.0))
	m.drop_table = StringName(d.get("drop_table", ""))
	m.scene_path = String(d.get("scene", ""))
	var size: Array = d.get("body_size", [16, 16])
	m.body_size = Vector2(float(size[0]), float(size[1]))
	m.respawn_ticks = int(float(d.get("respawn_s", 8.0)) * NetConfig.TICK_RATE)
	return m
