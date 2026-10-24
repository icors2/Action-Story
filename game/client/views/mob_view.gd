class_name MobView
extends Node2D
## Placeholder mob art driven by snapshots. No hit queries.

var eid: int = 0
var def_index: int = 0
var interp := InterpolationBuffer.new()
var _art: Node
var _flash: float = 0.0
var _hp_bar: ColorRect
var _hp_fill: ColorRect
var _hp_until: float = 0.0
var _hp_pct: float = 1.0
var _face: int = 1


func setup(state: EntityState) -> void:
	eid = state.eid
	def_index = state.def_index
	name = "MobView_%d" % eid
	_build_art()
	_build_hp_bar()


func apply_state(state: EntityState, server_time: float) -> void:
	var pos := Vector2(float(state.x) / NetConfig.POS_QUANT, float(state.y) / NetConfig.POS_QUANT)
	interp.push(server_time, pos)
	_face = -1 if (state.flags & Const.FLAG_FACE_LEFT) != 0 else 1
	scale.x = float(_face)
	_hp_pct = float(state.hp_pct) / 255.0
	if _hp_fill:
		_hp_fill.scale.x = maxf(_hp_pct, 0.02)
	if state.anim == Const.Anim.HURT or state.anim == Const.Anim.DEAD:
		flash()
	if state.anim == Const.Anim.DEAD:
		modulate.a = 0.55


func flash() -> void:
	_flash = 0.12
	_hp_until = Time.get_ticks_msec() / 1000.0 + 3.0


func show_hp() -> void:
	_hp_until = Time.get_ticks_msec() / 1000.0 + 3.0


func _process(delta: float) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	global_position = interp.sample(now - NetConfig.INTERP_DELAY_S)
	if _hp_bar:
		_hp_bar.scale.x = float(_face)
	if _flash > 0.0:
		_flash -= delta
		modulate = Color(1.6, 1.6, 1.6) if int(_flash * 30.0) % 2 == 0 else Color.WHITE
	elif modulate != Color(1, 1, 1, modulate.a):
		modulate = Color(1, 1, 1, modulate.a)
	if _hp_bar:
		_hp_bar.visible = now < _hp_until


func _build_art() -> void:
	var mob_id: StringName = DataRegistry.mob_id_from_index(def_index)
	var def: MobDef = DataRegistry.mobs.get(mob_id)
	if def and not def.scene_path.is_empty() and ResourceLoader.exists(def.scene_path):
		_art = (load(def.scene_path) as PackedScene).instantiate()
		add_child(_art)
		return
	var body := ColorRect.new()
	body.size = Vector2(24, 18)
	body.position = Vector2(-12, -18)
	body.color = Color(0.45, 0.7, 0.85)
	add_child(body)
	_art = body


func _build_hp_bar() -> void:
	_hp_bar = ColorRect.new()
	_hp_bar.size = Vector2(24, 3)
	_hp_bar.position = Vector2(-12, -30)
	_hp_bar.color = Color(0.15, 0.15, 0.15, 0.8)
	_hp_bar.visible = false
	add_child(_hp_bar)
	_hp_fill = ColorRect.new()
	_hp_fill.size = Vector2(24, 3)
	_hp_fill.color = Color(0.85, 0.2, 0.2)
	_hp_bar.add_child(_hp_fill)
