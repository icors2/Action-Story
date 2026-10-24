extends GutTest
## WorldSim on map_test_movement: player falls and lands.


func test_player_falls_and_lands_on_floor() -> void:
	var sim := WorldSim.new()
	sim.seed_rng(42)
	add_child_autofree(sim)
	await wait_physics_frames(1)
	var eid: int = sim.spawn_player(CharacterRecord.new_default("Tester"), 1)
	for i: int in 90:
		var frames: Array[InputFrame] = [InputFrame.neutral(i + 1)]
		sim.queue_input(eid, frames)
		sim.step()
		await wait_physics_frames(1)
	var p: PlayerEntity = sim._players[eid]
	assert_not_null(p)
	assert_eq(p.motor.state, MovementMotor.State.GROUND)
	assert_gt(p.global_position.y, 600.0)
