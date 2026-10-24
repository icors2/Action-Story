class_name ProjectileView
extends Node2D
## Interpolated placeholder bolt.

var eid: int = 0
var interp := InterpolationBuffer.new()
var _body: ColorRect


func setup(state: EntityState) -> void:
	eid = state.eid
	name = "Proj_%d" % eid
	_body = ColorRect.new()
	_body.size = Vector2(10, 6)
	_body.position = Vector2(-5, -3)
	_body.color = Color(0.95, 0.85, 0.35)
	add_child(_body)
	apply_state(state, Time.get_ticks_msec() / 1000.0)


func apply_state(state: EntityState, server_time: float) -> void:
	var pos := Vector2(float(state.x) / NetConfig.POS_QUANT, float(state.y) / NetConfig.POS_QUANT)
	interp.push(server_time, pos)
	scale.x = -1.0 if (state.flags & Const.FLAG_FACE_LEFT) != 0 else 1.0


func _process(_delta: float) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	global_position = interp.sample(now - NetConfig.INTERP_DELAY_S)
