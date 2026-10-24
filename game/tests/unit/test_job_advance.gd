extends GutTest


func _player() -> PlayerEntity:
	var p := PlayerEntity.new()
	add_child_autofree(p)
	return p


func test_unknown_class() -> void:
	var p: PlayerEntity = _player()
	assert_eq(JobAdvance.validate(p, &"wizard", false), Protocol.Reject.INVALID)


func test_parent_mismatch() -> void:
	var p: PlayerEntity = _player()
	var stats: StatsComponent = p.get_component(&"StatsComponent") as StatsComponent
	stats.class_id = &"vanguard"
	assert_eq(JobAdvance.validate(p, &"arcanist", false), Protocol.Reject.NOT_ALLOWED)


func test_level_and_stat_reqs() -> void:
	var p: PlayerEntity = _player()
	var stats: StatsComponent = p.get_component(&"StatsComponent") as StatsComponent
	stats.class_id = &"novice"
	stats.level = 1
	assert_eq(JobAdvance.validate(p, &"vanguard", false), Protocol.Reject.NOT_ALLOWED)
	assert_eq(JobAdvance.validate(p, &"vanguard", true), Protocol.Reject.NONE)
	stats.level = 10
	assert_eq(JobAdvance.validate(p, &"vanguard", false), Protocol.Reject.NOT_ALLOWED)
	stats.base[&"str"] = 35
	stats.recalculate()
	assert_eq(JobAdvance.validate(p, &"vanguard", false), Protocol.Reject.NONE)


func test_apply_grants_class_skills_at_zero() -> void:
	var p: PlayerEntity = _player()
	p.apply_record(CharacterRecord.new_default("T"))
	JobAdvance.apply(p, &"vanguard")
	var stats: StatsComponent = p.get_component(&"StatsComponent") as StatsComponent
	assert_eq(stats.class_id, &"vanguard")
	assert_true(p.has_skill(&"vanguard_cleave"))
	assert_eq(p.skill_level(&"vanguard_cleave"), 0)
	assert_true(p.has_skill(&"vanguard_iron_hide"))
	assert_eq(p.skill_level(&"novice_strike"), 1)
