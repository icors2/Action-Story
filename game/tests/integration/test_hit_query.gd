extends GutTest


func _target(root: Node, pos: Vector2) -> Entity:
	var e: MobEntity = preload("res://sim/entities/mob_entity.tscn").instantiate()
	root.add_child(e)
	e.global_position = pos
	return e


func test_nearest_first_and_max_targets() -> void:
	var root := Node2D.new()
	add_child_autofree(root)
	var a: Entity = _target(root, Vector2(100, 0))
	var b: Entity = _target(root, Vector2(140, 0))
	var _c: Entity = _target(root, Vector2(240, 0))
	await wait_physics_frames(2)
	var space: PhysicsDirectSpaceState2D = root.get_world_2d().direct_space_state
	var hits: Array[Entity] = HitQuery.query_rect(
		space,
		Vector2(80, 0),
		1,
		Vector2(40, 0),
		Vector2(100, 30),
		int(Const.Layer.MOB_HURTBOX),
		2
	)
	assert_eq(hits.size(), 2)
	assert_eq(hits[0], a)
	assert_eq(hits[1], b)
