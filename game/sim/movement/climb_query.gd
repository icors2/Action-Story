class_name ClimbQuery
## Point query against rope/ladder areas (layer CLIMBABLE).


static func find(space: PhysicsDirectSpaceState2D, point: Vector2) -> Area2D:
	if space == null:
		return null
	var params := PhysicsPointQueryParameters2D.new()
	params.position = point
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = Const.bit(Const.Layer.CLIMBABLE)
	var hits: Array[Dictionary] = space.intersect_point(params, 1)
	if hits.is_empty():
		return null
	return hits[0]["collider"] as Area2D
