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


func _ready() -> void:
	if Config.is_server():
		return


func apply_vitals(p_hp: int, p_max_hp: int, p_mp: int, p_max_mp: int) -> void:
	hp = p_hp
	max_hp = p_max_hp
	mp = p_mp
	max_mp = p_max_mp
	dead = hp <= 0


func mark_hit() -> void:
	invuln_until = Time.get_ticks_msec() / 1000.0 + DataRegistry.stats.invincibility_after_hit_s
