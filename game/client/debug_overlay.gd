class_name DebugOverlay
extends CanvasLayer
## F3 overlay: FPS, tick, motor, position, velocity, pending, corrections.

var authority: LocalAuthority
var predictor: Predictor
var predicted: PlayerEntity
var _label: Label
var _visible_overlay: bool = true


func _ready() -> void:
	layer = 100
	_label = Label.new()
	_label.position = Vector2(8, 8)
	_label.add_theme_font_size_override(&"font_size", 12)
	_label.add_theme_color_override(&"font_color", Color(0.95, 0.95, 0.7))
	add_child(_label)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_overlay"):
		_visible_overlay = not _visible_overlay
		_label.visible = _visible_overlay


func _process(_delta: float) -> void:
	if not _visible_overlay or predicted == null or predicted.motor == null:
		return
	var motor: MovementMotor = predicted.motor
	var tick: int = authority.sim.tick if authority and authority.sim else 0
	var pending: int = predictor.pending.size() if predictor else 0
	var corrections: int = predictor.correction_count if predictor else 0
	var last_c: float = predictor.last_correction if predictor else 0.0
	var action_name: String = ""
	if authority and authority.sim:
		var sim_player: PlayerEntity = authority.sim._players.get(authority.self_eid)
		if sim_player and sim_player.action:
			action_name = String(sim_player.action.current_name)
	_label.text = "FPS %d  tick %d  %s %s\npos (%.1f, %.1f)  vel (%.1f, %.1f)\nHP %d/%d  pending %d  corrections>1px %d  last %.3f" % [
		Engine.get_frames_per_second(),
		tick,
		MovementMotor.State.keys()[motor.state],
		action_name,
		predicted.global_position.x,
		predicted.global_position.y,
		predicted.velocity.x,
		predicted.velocity.y,
		GameState.hp,
		GameState.max_hp,
		pending,
		corrections,
		last_c,
	]
