class_name HitQuery
## Resolves "which hurtboxes does this attack box touch" with a direct space query.


static func query_rect(
		space: PhysicsDirectSpaceState2D,
		origin: Vector2,
		facing: int,
		offset: Vector2,
		size: Vector2,
		target_layer: int,
		max_targets: int
	) -> Array[Entity]:
	var found: Array[Entity] = []
	if space == null or max_targets <= 0:
		return found
	var shape := RectangleShape2D.new()
	shape.size = size
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, origin + Vector2(offset.x * signf(float(facing)), offset.y))
	params.collision_mask = Const.bit(target_layer)
	params.collide_with_areas = true
	params.collide_with_bodies = false
	var results: Array[Dictionary] = space.intersect_shape(params, 32)
	for r: Dictionary in results:
		var hb: Hurtbox = r["collider"] as Hurtbox
		if hb == null:
			continue
		var e: Entity = hb.owner_entity()
		if e and not found.has(e):
			found.append(e)
	found.sort_custom(
		func(a: Entity, b: Entity) -> bool:
			return absf(a.global_position.x - origin.x) < absf(b.global_position.x - origin.x)
	)
	if found.size() > max_targets:
		return found.slice(0, max_targets)
	return found
