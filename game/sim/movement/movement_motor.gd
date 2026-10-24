class_name MovementMotor
extends Component
## Deterministic side-scroller movement on a CharacterBody2D.

enum State { GROUND, AIR, CLIMB }

@export var walk_speed: float = 125.0
@export var accel: float = 1400.0
@export var decel: float = 1800.0
@export var air_control: float = 0.2
@export var jump_velocity: float = -330.0
@export var gravity: float = 1000.0
@export var max_fall: float = 600.0
@export var climb_speed: float = 80.0
@export var coyote_ticks: int = 5
@export var jump_buffer_ticks: int = 6
@export var drop_through_ticks: int = 12

var state: State = State.AIR
var facing: int = 1
var _coyote: int = 0
var _jump_buffer: int = 0
var _drop_through: int = 0
var _climb_x: float = 0.0
var _knockback: int = 0
var _regrab_cooldown: int = 0


func on_attached() -> void:
	if DataRegistry.stats == null:
		return
	var m: Dictionary = DataRegistry.stats.movement
	if m.is_empty():
		return
	walk_speed = float(m.get("walk_speed", walk_speed))
	accel = float(m.get("accel", accel))
	decel = float(m.get("decel", decel))
	air_control = float(m.get("air_control", air_control))
	jump_velocity = float(m.get("jump_velocity", jump_velocity))
	gravity = float(m.get("gravity", gravity))
	max_fall = float(m.get("max_fall", max_fall))
	climb_speed = float(m.get("climb_speed", climb_speed))
	coyote_ticks = int(m.get("coyote_ticks", coyote_ticks))
	jump_buffer_ticks = int(m.get("jump_buffer_ticks", jump_buffer_ticks))
	drop_through_ticks = int(m.get("drop_through_ticks", drop_through_ticks))


func step(frame: InputFrame, dt: float) -> void:
	var body: Entity = entity
	if _drop_through > 0:
		_drop_through -= 1
		if _drop_through == 0:
			body.set_collision_mask_value(Const.Layer.PLATFORM_ONEWAY, true)
	_regrab_cooldown = maxi(_regrab_cooldown - 1, 0)
	if state == State.CLIMB:
		_step_climb(frame, dt)
	else:
		_step_platformer(frame, dt)


func apply_knockback(impulse: Vector2, ticks: int) -> void:
	state = State.AIR
	entity.velocity = impulse
	_knockback = ticks


func capture() -> MotorState:
	var s := MotorState.new()
	s.position = entity.global_position
	s.velocity = entity.velocity
	s.state = int(state)
	s.facing = facing
	s.coyote = _coyote
	s.jump_buffer = _jump_buffer
	s.drop_through = _drop_through
	s.climb_x = _climb_x
	s.knockback = _knockback
	s.collision_mask = entity.collision_mask
	s.regrab = _regrab_cooldown
	return s


func restore(s: MotorState) -> void:
	entity.global_position = s.position
	entity.velocity = s.velocity
	state = s.state as State
	facing = s.facing
	_coyote = s.coyote
	_jump_buffer = s.jump_buffer
	_drop_through = s.drop_through
	_climb_x = s.climb_x
	_knockback = s.knockback
	_regrab_cooldown = s.regrab
	if s.collision_mask != 0:
		entity.collision_mask = s.collision_mask
	else:
		entity.set_collision_mask_value(Const.Layer.PLATFORM_ONEWAY, _drop_through == 0 and state != State.CLIMB)


func _step_platformer(frame: InputFrame, dt: float) -> void:
	var body: Entity = entity
	var on_floor: bool = body.is_on_floor()
	if _knockback > 0:
		_knockback -= 1
	else:
		var target: float = float(frame.move_x) * walk_speed
		var rate: float = accel if frame.move_x != 0 else decel
		if not on_floor:
			rate *= air_control
		body.velocity.x = move_toward(body.velocity.x, target, rate * dt)
		if frame.move_x != 0:
			facing = frame.move_x
	_coyote = coyote_ticks if on_floor else maxi(_coyote - 1, 0)
	if frame.pressed(InputFrame.BTN_JUMP_PRESSED):
		_jump_buffer = jump_buffer_ticks
	else:
		_jump_buffer = maxi(_jump_buffer - 1, 0)
	if _jump_buffer > 0 and on_floor and frame.move_y > 0 and _standing_on_oneway():
		body.set_collision_mask_value(Const.Layer.PLATFORM_ONEWAY, false)
		_drop_through = drop_through_ticks
		_jump_buffer = 0
	elif _jump_buffer > 0 and _coyote > 0 and _knockback == 0:
		body.velocity.y = jump_velocity
		_jump_buffer = 0
		_coyote = 0
	if frame.move_y != 0 and _regrab_cooldown == 0 and _try_grab_climbable(frame.move_y):
		return
	body.velocity.y = minf(body.velocity.y + gravity * dt, max_fall)
	body.move_and_slide()
	state = State.GROUND if body.is_on_floor() else State.AIR


func _step_climb(frame: InputFrame, dt: float) -> void:
	var body: Entity = entity
	if frame.pressed(InputFrame.BTN_JUMP_PRESSED) and frame.move_x != 0:
		state = State.AIR
		_regrab_cooldown = 15
		body.velocity = Vector2(float(frame.move_x) * walk_speed * 0.8, jump_velocity * 0.55)
		body.set_collision_mask_value(Const.Layer.PLATFORM_ONEWAY, true)
		facing = frame.move_x
		return
	body.global_position.x = _climb_x
	body.velocity = Vector2(0.0, float(frame.move_y) * climb_speed)
	body.move_and_slide()
	var still_on: bool = ClimbQuery.find(_space(), body.global_position) != null
	if still_on and not (frame.move_y > 0 and body.is_on_floor()):
		return
	body.set_collision_mask_value(Const.Layer.PLATFORM_ONEWAY, true)
	if not still_on and frame.move_y < 0:
		body.velocity = Vector2(0.0, jump_velocity * 0.2)
		state = State.AIR
	elif body.is_on_floor():
		state = State.GROUND
	else:
		state = State.AIR


func _try_grab_climbable(dir_y: int) -> bool:
	var probe: Vector2 = entity.global_position + Vector2(0.0, -8.0 if dir_y < 0 else 4.0)
	var area: Area2D = ClimbQuery.find(_space(), probe)
	if area == null:
		return false
	state = State.CLIMB
	_climb_x = area.global_position.x
	entity.velocity = Vector2.ZERO
	entity.set_collision_mask_value(Const.Layer.PLATFORM_ONEWAY, false)
	return true


func _standing_on_oneway() -> bool:
	for i: int in entity.get_slide_collision_count():
		var c: KinematicCollision2D = entity.get_slide_collision(i)
		var collider: Object = c.get_collider()
		if c.get_normal().y < -0.7 and collider is Node and (collider as Node).is_in_group(Const.GROUP_ONEWAY):
			return true
	return false


func _space() -> PhysicsDirectSpaceState2D:
	if entity.map:
		return entity.map.space_state()
	var world: World2D = entity.get_world_2d()
	return world.direct_space_state if world else null
