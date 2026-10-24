class_name InputSampler
extends Node
## Samples keyboard/gamepad each physics tick into an InputFrame and submits it.

var authority: Authority
var predictor: Predictor
var predicted: PlayerEntity
var player_view: PlayerView
var _seq: int = 0
var _jump_was_held: bool = false
var _attack_was: bool = false


func _ready() -> void:
	process_physics_priority = -10


func _physics_process(_delta: float) -> void:
	if authority == null or predictor == null:
		return
	_seq += 1
	_maybe_attack()
	_maybe_rpg()
	var f := InputFrame.new()
	f.seq = _seq
	if GameState.dead or GameState.chat_open:
		predictor.apply_local(f)
		authority.submit_input(f)
		return
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


func _maybe_attack() -> void:
	if GameState.chat_open:
		_attack_was = Input.is_action_pressed(&"attack")
		return
	var pressed: bool = Input.is_action_pressed(&"attack")
	if pressed and not _attack_was and not GameState.dead:
		_cast(&"novice_strike")
	_attack_was = pressed


func _maybe_rpg() -> void:
	if GameState.chat_open or GameState.dead:
		return
	if Input.is_action_just_pressed(&"skill_1"):
		_cast(GameState.extra_cast_skill(0))
	if Input.is_action_just_pressed(&"skill_2"):
		_cast(GameState.extra_cast_skill(1))
	if Input.is_action_just_pressed(&"alloc_str"):
		authority.submit_intent(Intent.alloc_ap(&"str"))
	if Input.is_action_just_pressed(&"alloc_dex"):
		authority.submit_intent(Intent.alloc_ap(&"dex"))
	if Input.is_action_just_pressed(&"alloc_int"):
		authority.submit_intent(Intent.alloc_ap(&"int"))
	if Input.is_action_just_pressed(&"alloc_luk"):
		authority.submit_intent(Intent.alloc_ap(&"luk"))
	if Input.is_action_just_pressed(&"alloc_sp"):
		var sid: StringName = GameState.first_sp_skill()
		if sid != &"":
			authority.submit_intent(Intent.alloc_sp(sid))


func _cast(skill_id: StringName) -> void:
	if skill_id == &"":
		return
	var facing: int = predicted.motor.facing if predicted and predicted.motor else 1
	GameState.last_cast_seq = authority.submit_intent(Intent.cast(skill_id, facing))
	if player_view:
		player_view.play_attack()
