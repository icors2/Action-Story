extends GutTest


func test_hit_fires_at_hit_tick_then_returns_idle() -> void:
	var player := PlayerEntity.new()
	add_child_autofree(player)
	var machine := TickStateMachine.new()
	machine.owner_entity = player
	machine.add(&"idle", IdleState.new())
	machine.add(&"casting", CastingState.new())
	machine.transition(&"idle")
	var skill: SkillDef = DataRegistry.skill(&"novice_strike")
	assert_not_null(skill)
	machine.transition(&"casting", {"skill": skill, "level": 1, "facing": 1})
	var casting: CastingState = machine.current as CastingState
	var ticks: int = 0
	while machine.current_name == &"casting" and ticks < 80:
		machine.tick(ticks)
		ticks += 1
		if ticks == skill.hit_tick:
			assert_true(casting.hit_fired)
	assert_true(casting.hit_fired)
	assert_eq(ticks, skill.cast_ticks)
	assert_eq(machine.current_name, &"idle")


func test_multi_hit_pulses() -> void:
	var player := PlayerEntity.new()
	add_child_autofree(player)
	var machine := TickStateMachine.new()
	machine.owner_entity = player
	machine.add(&"idle", IdleState.new())
	machine.add(&"casting", CastingState.new())
	machine.transition(&"idle")
	var skill: SkillDef = DataRegistry.skill(&"vanguard_smash")
	assert_not_null(skill)
	assert_eq(skill.hits, 3)
	machine.transition(&"casting", {"skill": skill, "level": 1, "facing": 1})
	var casting: CastingState = machine.current as CastingState
	var ticks: int = 0
	while machine.current_name == &"casting" and ticks < 80:
		machine.tick(ticks)
		ticks += 1
	assert_eq(casting._fired_hits, 3)
	assert_eq(machine.current_name, &"idle")
