class_name InputSampler
extends Node
## Samples keyboard/gamepad each physics tick into an InputFrame and submits it.

var authority: Authority
var predictor: Predictor
var _seq: int = 0
var _jump_was_held: bool = false


func _ready() -> void:
	process_physics_priority = -10


func _physics_process(_delta: float) -> void:
	if authority == null or predictor == null:
		return
	_seq += 1
	var f := InputFrame.new()
	f.seq = _seq
	f.move_x = clampi(roundi(Input.get_axis(&"move_left", &"move_right")), -1, 1)
	f.move_y = clampi(roundi(Input.get_axis(&"move_up", &"move_down")), -1, 1)
	var jump_held: bool = Input.is_action_pressed(&"jump")
	if jump_held:
		f.buttons |= InputFrame.BTN_JUMP_HELD
		if not _jump_was_held:
			f.buttons |= InputFrame.BTN_JUMP_PRESSED
	_jump_was_held = jump_held
	predictor.apply_local(f)
	authority.submit_input(f)
