class_name MobBrain
extends Component
## Simple tick-based AI: patrol edge-to-edge, aggro, chase on same platform, flinch, die.

enum S { IDLE, PATROL, CHASE, HURT, DEAD }

const THINK_EVERY: int = 6
const HURT_TICKS: int = 18
const JUMP_VELOCITY: float = -280.0

var def: MobDef
var state: S = S.PATROL
var dir: int = 1
var target_eid: int = 0
var _think_in: int = 0
var _state_ticks: int = 0
var _gravity: float = 1000.0


func on_attached() -> void:
	var health: HealthComponent = entity.get_component(&"HealthComponent") as HealthComponent
	if health:
		health.damaged.connect(_on_damaged)
		health.died.connect(func(_k: int) -> void: _set_state(S.DEAD))


func step(_tick: int, dt: float) -> void:
	var body: Entity = entity
	_state_ticks += 1
	_think_in -= 1
	if _think_in <= 0:
		_think_in = THINK_EVERY
		_think()
	match state:
		S.IDLE:
			body.velocity.x = 0.0
		S.PATROL:
			if _wall_or_edge_ahead():
				dir = -dir
			body.velocity.x = dir * def.move_speed
		S.CHASE:
			_step_chase(dt)
		S.HURT:
			body.velocity.x = move_toward(body.velocity.x, 0.0, 600.0 * dt)
			if _state_ticks > HURT_TICKS:
				_set_state(S.CHASE if target_eid != 0 else S.PATROL)
		S.DEAD:
			body.velocity.x = 0.0
			body.velocity.y = minf(body.velocity.y + _gravity * dt, 600.0)
			body.move_and_slide()
			return
	body.velocity.y = minf(body.velocity.y + _gravity * dt, 600.0)
	body.move_and_slide()


func apply_flinch_velocity(impulse: Vector2) -> void:
	entity.velocity = impulse
	_set_state(S.HURT)


func _step_chase(_dt: float) -> void:
	var body: Entity = entity
	var target: Entity = body.map.entities.get(target_eid) if body.map else null
	if target == null:
		target_eid = 0
		_set_state(S.PATROL)
		return
	var dx: float = target.global_position.x - body.global_position.x
	if absf(dx) > 4.0:
		dir = signi(int(dx))
	body.velocity.x = 0.0 if _wall_or_edge_ahead() else float(dir) * def.chase_speed
	if def.can_jump and body.is_on_floor() and target.global_position.y < body.global_position.y - 20.0:
		body.velocity.y = JUMP_VELOCITY


func _think() -> void:
	if state == S.DEAD or state == S.HURT:
		return
	if state == S.PATROL and entity.map and entity.map.sim.rng.randf() < 0.05:
		_set_state(S.IDLE)
	elif state == S.IDLE and _state_ticks > 60:
		dir = 1 if entity.map.sim.rng.randf() < 0.5 else -1
		_set_state(S.PATROL)
	if def.aggro_range > 0.0 and (state == S.PATROL or state == S.IDLE):
		var seen: Entity = _nearest_player()
		if seen:
			target_eid = seen.eid
			_set_state(S.CHASE)


func _nearest_player() -> Entity:
	if entity.map == null:
		return null
	var best: Entity = null
	var best_d: float = def.aggro_range
	for e: Entity in entity.map.entities.values():
		if e.kind != Const.EntityKind.PLAYER:
			continue
		var health: HealthComponent = e.get_component(&"HealthComponent") as HealthComponent
		if health and health.is_dead():
			continue
		var d: float = entity.global_position.distance_to(e.global_position)
		if d <= best_d:
			best_d = d
			best = e
	return best


func _on_damaged(_amount: int, source_eid: int, _crit: bool) -> void:
	if state == S.DEAD:
		return
	if def.behavior != &"patrol" and source_eid != 0:
		target_eid = source_eid
	_set_state(S.HURT)


func _set_state(s: S) -> void:
	state = s
	_state_ticks = 0


func _wall_or_edge_ahead() -> bool:
	var body: Entity = entity
	if body.is_on_wall():
		return true
	if body.map == null:
		return false
	var space: PhysicsDirectSpaceState2D = body.map.space_state()
	if space == null:
		return false
	var from: Vector2 = body.global_position + Vector2(float(dir) * (def.body_size.x * 0.5 + 2.0), 0.0)
	var floor_q := PhysicsRayQueryParameters2D.create(
		from,
		from + Vector2(0.0, 24.0),
		Const.mask([int(Const.Layer.WORLD), int(Const.Layer.PLATFORM_ONEWAY)] as Array[int])
	)
	var wall_q := PhysicsRayQueryParameters2D.create(body.global_position, from, Const.bit(int(Const.Layer.MOB_WALL)))
	wall_q.collide_with_areas = true
	return space.intersect_ray(floor_q).is_empty() or not space.intersect_ray(wall_q).is_empty()
