class_name PlayerView
extends Node2D
## Placeholder body art that follows the predicted player. Not the physics body.

var target: Node2D
var _sprite: Sprite2D
var _nose: Sprite2D
var _last_state: int = -1
var _attack_left: float = 0.0
var _hitstop: int = 0


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = _block(Color(0.22, 0.55, 0.92), Vector2i(12, 26))
	add_child(_sprite)
	_nose = Sprite2D.new()
	_nose.texture = _block(Color(0.95, 0.85, 0.25), Vector2i(4, 4))
	_nose.position = Vector2(8, -4)
	add_child(_nose)


func play_attack() -> void:
	_attack_left = 0.4
	_sprite.modulate = Color(1.15, 0.75, 0.35)


func cancel_attack() -> void:
	_attack_left = 0.0
	_last_state = -1


func hit_stop(frames: int) -> void:
	_hitstop = maxi(_hitstop, frames)


func _process(delta: float) -> void:
	if _hitstop > 0:
		_hitstop -= 1
		return
	if target == null:
		return
	global_position = target.global_position
	GameState.self_pos = global_position
	var player: PlayerEntity = target as PlayerEntity
	if player and player.motor:
		var face: float = float(player.motor.facing)
		var reach: float = 14.0 if _attack_left > 0.0 else 8.0
		_nose.position.x = reach * face
		if _attack_left > 0.0:
			_attack_left -= delta
			if _attack_left <= 0.0:
				_last_state = -1
		else:
			_tint_for_state(player.motor.state)
	if GameState.invuln_until > Time.get_ticks_msec() / 1000.0:
		modulate.a = 0.45 + 0.45 * absf(sin(Time.get_ticks_msec() / 40.0))
	else:
		modulate.a = 0.35 if GameState.dead else 1.0


func _tint_for_state(motor_state: int) -> void:
	if motor_state == _last_state:
		return
	_last_state = motor_state
	match motor_state:
		MovementMotor.State.GROUND:
			_sprite.modulate = Color(1, 1, 1)
		MovementMotor.State.AIR:
			_sprite.modulate = Color(0.85, 0.95, 1.15)
		MovementMotor.State.CLIMB:
			_sprite.modulate = Color(1.1, 0.95, 0.7)
		_:
			_sprite.modulate = Color.WHITE


func _block(color: Color, size: Vector2i) -> Texture2D:
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)
