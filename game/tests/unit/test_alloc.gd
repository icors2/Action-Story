extends GutTest


func _player() -> PlayerEntity:
	var p := PlayerEntity.new()
	add_child_autofree(p)
	return p


func test_alloc_ap_success_and_empty() -> void:
	var p: PlayerEntity = _player()
	p.rpg.ap = 1
	assert_eq(p.rpg.alloc_ap(&"str"), Protocol.Reject.NONE)
	var stats: StatsComponent = p.get_component(&"StatsComponent") as StatsComponent
	assert_eq(stats.get_total(&"str"), 5)
	assert_eq(p.rpg.ap, 0)
	assert_eq(p.rpg.alloc_ap(&"str"), Protocol.Reject.NOT_ALLOWED)


func test_alloc_ap_invalid_stat() -> void:
	var p: PlayerEntity = _player()
	p.rpg.ap = 2
	assert_eq(p.rpg.alloc_ap(&"hp"), Protocol.Reject.INVALID)
	assert_eq(p.rpg.ap, 2)


func test_alloc_sp_unknown_and_wrong_class() -> void:
	var p: PlayerEntity = _player()
	p.rpg.sp = 2
	assert_eq(p.rpg.alloc_sp(&"nope"), Protocol.Reject.INVALID)
	assert_eq(p.rpg.alloc_sp(&"vanguard_cleave"), Protocol.Reject.NOT_ALLOWED)


func test_alloc_sp_prereq_and_max() -> void:
	var p: PlayerEntity = _player()
	var stats: StatsComponent = p.get_component(&"StatsComponent") as StatsComponent
	stats.class_id = &"vanguard"
	p.set_skill_level(&"vanguard_cleave", 0)
	p.set_skill_level(&"vanguard_smash", 0)
	p.rpg.sp = 2
	assert_eq(p.rpg.alloc_sp(&"vanguard_smash"), Protocol.Reject.NOT_ALLOWED)
	assert_eq(p.rpg.alloc_sp(&"vanguard_cleave"), Protocol.Reject.NONE)
	assert_eq(p.skill_level(&"vanguard_cleave"), 1)
	assert_eq(p.rpg.alloc_sp(&"vanguard_smash"), Protocol.Reject.NONE)
	p.rpg.sp = 20
	for _i: int in 9:
		assert_eq(p.rpg.alloc_sp(&"vanguard_cleave"), Protocol.Reject.NONE)
	assert_eq(p.rpg.alloc_sp(&"vanguard_cleave"), Protocol.Reject.NOT_ALLOWED)


func test_alloc_sp_no_points() -> void:
	var p: PlayerEntity = _player()
	var stats: StatsComponent = p.get_component(&"StatsComponent") as StatsComponent
	stats.class_id = &"vanguard"
	p.set_skill_level(&"vanguard_cleave", 0)
	p.rpg.sp = 0
	assert_eq(p.rpg.alloc_sp(&"vanguard_cleave"), Protocol.Reject.NOT_ALLOWED)
