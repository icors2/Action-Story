class_name PlayerView
extends Node2D
## Placeholder body art that follows the predicted player. Not the physics body.

var target: Node2D
var _sprite: Sprite2D
var _nose: Sprite2D
var _last_state: int = -1


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = _block(Color(0.22, 0.55, 0.92), Vector2i(12, 26))
	add_child(_sprite)
	_nose = Sprite2D.new()
	_nose.texture = _block(Color(0.95, 0.85, 0.25), Vector2i(4, 4))
	_nose.position = Vector2(8, -4)
	add_child(_nose)


func _process(_delta: float) -> void:
	if target == null:
		return
	global_position = target.global_position
	var player: PlayerEntity = target as PlayerEntity
	if player and player.motor:
		var face: float = float(player.motor.facing)
		_nose.position.x = 8.0 * face
		_tint_for_state(player.motor.state)


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
