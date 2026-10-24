extends GutTest


func _mob_count(map: MapInstance) -> int:
	var n: int = 0
	for e: Entity in map.entities.values():
		if e is MobEntity:
			n += 1
	return n


func test_spawner_max_alive_and_respawn() -> void:
	var sim := WorldSim.new()
	sim.seed_rng(7)
	add_child_autofree(sim)
	await wait_physics_frames(1)
	var map: MapInstance = sim.get_or_create_map(&"map_test_flat")
	var a := Marker2D.new()
	a.position = Vector2(80, 300)
	a.add_to_group("spawn_test")
	map._map_root.add_child(a)
	var b := Marker2D.new()
	b.position = Vector2(180, 300)
	b.add_to_group("spawn_test")
	map._map_root.add_child(b)
	var s := Spawner.new()
	s.setup(map, {"mob": "puddlet", "marker_group": "spawn_test", "max_alive": 2, "respawn_ticks": 8})
	map._spawners.append(s)
	s.populate()
	await wait_physics_frames(2)
	assert_eq(s.alive_eids.size(), 2)
	assert_eq(_mob_count(map), 2)
	var victim: MobEntity = map.entities[s.alive_eids[0]]
	var health: HealthComponent = victim.get_component(&"HealthComponent") as HealthComponent
	assert_eq(health.apply_damage(999, 1, false), health.max_hp)
	for _i: int in 45:
		sim.step()
		await wait_physics_frames(1)
	assert_eq(_mob_count(map), 2)
	assert_eq(s.alive_eids.size(), 2)
