extends GutTest
## Physics-frame movement: determinism, jump height, drop-through, climb.


func _frame(seq: int, x: int = 0, y: int = 0, jump_pressed: bool = false) -> InputFrame:
	var f := InputFrame.new()
	f.seq = seq
	f.move_x = x
	f.move_y = y
	if jump_pressed:
		f.buttons = InputFrame.BTN_JUMP_PRESSED | InputFrame.BTN_JUMP_HELD
	return f


func _add_static(root: Node, pos: Vector2, size: Vector2, layer: int, oneway: bool) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = layer
	body.collision_mask = 0
	if oneway:
		body.add_to_group(Const.GROUP_ONEWAY)
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	cs.shape = rect
	cs.one_way_collision = oneway
	body.position = pos
	body.add_child(cs)
	root.add_child(body)
	return body


func _spawn_player(root: Node, pos: Vector2) -> PlayerEntity:
	var p: PlayerEntity = preload("res://sim/entities/player_entity.tscn").instantiate()
	root.add_child(p)
	p.global_position = pos
	return p


func _settle(p: PlayerEntity, start_seq: int, frames: int) -> int:
	var seq: int = start_seq
	for _i: int in frames:
		p.motor.step(_frame(seq), NetConfig.TICK_DT)
		seq += 1
		await wait_physics_frames(1)
	return seq


func test_jump_height_about_three_and_half_tiles() -> void:
	var root := Node2D.new()
	add_child_autofree(root)
	_add_static(root, Vector2(400, 360), Vector2(800, 32), Const.bit(Const.Layer.WORLD), false)
	var p: PlayerEntity = _spawn_player(root, Vector2(200, 300))
	await wait_physics_frames(2)
	var seq: int = await _settle(p, 1, 40)
	assert_eq(p.motor.state, MovementMotor.State.GROUND)
	var start_y: float = p.global_position.y
	p.motor.step(_frame(seq, 0, 0, true), NetConfig.TICK_DT)
	seq += 1
	await wait_physics_frames(1)
	var peak_y: float = p.global_position.y
	for _i: int in 50:
		p.motor.step(_frame(seq), NetConfig.TICK_DT)
		seq += 1
		await wait_physics_frames(1)
		peak_y = minf(peak_y, p.global_position.y)
	var height: float = start_y - peak_y
	assert_almost_eq(height, 56.0, 8.0)


func test_determinism_replay() -> void:
	var root := Node2D.new()
	add_child_autofree(root)
	_add_static(root, Vector2(400, 360), Vector2(800, 32), Const.bit(Const.Layer.WORLD), false)
	var p: PlayerEntity = _spawn_player(root, Vector2(200, 300))
	await wait_physics_frames(2)
	var seq: int = await _settle(p, 1, 40)
	var start: MotorState = p.motor.capture()
	var scripted: Array[InputFrame] = []
	for i: int in 120:
		var x: int = 1 if (i / 20) % 2 == 0 else -1
		scripted.append(_frame(seq + i, x, 0, i % 40 == 0))
	var pos_a: Vector2 = await _play(p, scripted)
	p.motor.restore(start)
	await wait_physics_frames(1)
	var pos_b: Vector2 = await _play(p, scripted)
	assert_almost_eq(pos_a.x, pos_b.x, 0.01)
	assert_almost_eq(pos_a.y, pos_b.y, 0.01)


func _play(p: PlayerEntity, frames: Array[InputFrame]) -> Vector2:
	for f: InputFrame in frames:
		p.motor.step(f, NetConfig.TICK_DT)
		await wait_physics_frames(1)
	return p.global_position


func test_drop_through_only_on_oneway() -> void:
	var root := Node2D.new()
	add_child_autofree(root)
	_add_static(root, Vector2(400, 400), Vector2(800, 32), Const.bit(Const.Layer.WORLD), false)
	_add_static(root, Vector2(400, 240), Vector2(200, 16), Const.bit(Const.Layer.PLATFORM_ONEWAY), true)
	var p: PlayerEntity = _spawn_player(root, Vector2(400, 200))
	await wait_physics_frames(2)
	var seq: int = await _settle(p, 1, 40)
	assert_eq(p.motor.state, MovementMotor.State.GROUND)
	var on_plat_y: float = p.global_position.y
	assert_lt(on_plat_y, 300.0)
	p.motor.step(_frame(seq, 0, 1, true), NetConfig.TICK_DT)
	seq += 1
	await wait_physics_frames(1)
	for _i: int in 40:
		p.motor.step(_frame(seq, 0, 1), NetConfig.TICK_DT)
		seq += 1
		await wait_physics_frames(1)
	assert_gt(p.global_position.y, on_plat_y + 20.0)
	seq = await _settle(p, seq, 30)
	var solid_y: float = p.global_position.y
	assert_eq(p.motor.state, MovementMotor.State.GROUND)
	p.motor.step(_frame(seq, 0, 1, true), NetConfig.TICK_DT)
	seq += 1
	await wait_physics_frames(1)
	for _i: int in 50:
		p.motor.step(_frame(seq, 0, 1), NetConfig.TICK_DT)
		seq += 1
		await wait_physics_frames(1)
	assert_eq(p.motor.state, MovementMotor.State.GROUND)
	assert_almost_eq(p.global_position.y, solid_y, 8.0)
	assert_lt(p.global_position.y, solid_y + 40.0)


func test_climb_enter_and_exit() -> void:
	var root := Node2D.new()
	add_child_autofree(root)
	_add_static(root, Vector2(400, 400), Vector2(800, 32), Const.bit(Const.Layer.WORLD), false)
	var climb := Area2D.new()
	climb.collision_layer = Const.bit(Const.Layer.CLIMBABLE)
	climb.collision_mask = 0
	climb.monitoring = false
	climb.monitorable = true
	climb.position = Vector2(200, 300)
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(10, 200)
	cs.shape = rect
	climb.add_child(cs)
	root.add_child(climb)
	var p: PlayerEntity = _spawn_player(root, Vector2(200, 360))
	await wait_physics_frames(2)
	var seq: int = await _settle(p, 1, 30)
	p.motor.step(_frame(seq, 0, -1), NetConfig.TICK_DT)
	seq += 1
	await wait_physics_frames(1)
	assert_eq(p.motor.state, MovementMotor.State.CLIMB)
	for _i: int in 20:
		p.motor.step(_frame(seq, 0, -1), NetConfig.TICK_DT)
		seq += 1
		await wait_physics_frames(1)
	assert_eq(p.motor.state, MovementMotor.State.CLIMB)
	p.motor.step(_frame(seq, 1, 0, true), NetConfig.TICK_DT)
	await wait_physics_frames(1)
	assert_eq(p.motor.state, MovementMotor.State.AIR)


func test_climb_steps_onto_platform_at_top() -> void:
	var root := Node2D.new()
	add_child_autofree(root)
	_add_static(root, Vector2(400, 420), Vector2(800, 32), Const.bit(Const.Layer.WORLD), false)
	_add_static(root, Vector2(200, 200), Vector2(240, 16), Const.bit(Const.Layer.PLATFORM_ONEWAY), true)
	var climb := Area2D.new()
	climb.collision_layer = Const.bit(Const.Layer.CLIMBABLE)
	climb.collision_mask = 0
	climb.monitoring = false
	climb.monitorable = true
	climb.position = Vector2(200, 300)
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(10, 220)
	cs.shape = rect
	climb.add_child(cs)
	root.add_child(climb)
	var p: PlayerEntity = _spawn_player(root, Vector2(200, 380))
	await wait_physics_frames(2)
	var seq: int = await _settle(p, 1, 40)
	p.motor.step(_frame(seq, 0, -1), NetConfig.TICK_DT)
	seq += 1
	await wait_physics_frames(1)
	assert_eq(p.motor.state, MovementMotor.State.CLIMB)
	for _i: int in 160:
		p.motor.step(_frame(seq, 0, -1), NetConfig.TICK_DT)
		seq += 1
		await wait_physics_frames(1)
		if p.motor.state == MovementMotor.State.GROUND:
			break
	assert_eq(p.motor.state, MovementMotor.State.GROUND)
	assert_lt(p.global_position.y, 220.0)
