extends GutTest


func _table() -> PackedInt64Array:
	return PackedInt64Array([10, 20, 40])


func test_exact_threshold_levels_once() -> void:
	var r: Leveling.Result = Leveling.add_exp(1, 0, 10, _table())
	assert_eq(r.level, 2)
	assert_eq(r.exp, 0)
	assert_eq(r.levels_gained, 1)


func test_remainder_kept() -> void:
	var r: Leveling.Result = Leveling.add_exp(1, 3, 10, _table())
	assert_eq(r.level, 2)
	assert_eq(r.exp, 3)
	assert_eq(r.levels_gained, 1)


func test_multi_level() -> void:
	var r: Leveling.Result = Leveling.add_exp(1, 0, 10 + 20 + 5, _table())
	assert_eq(r.level, 3)
	assert_eq(r.exp, 5)
	assert_eq(r.levels_gained, 2)


func test_cap_clears_exp() -> void:
	var r: Leveling.Result = Leveling.add_exp(1, 0, 9999, _table())
	assert_eq(r.level, 4)
	assert_eq(r.exp, 0)
	assert_eq(r.levels_gained, 3)
	assert_eq(Leveling.max_level(_table()), 4)


func test_zero_and_negative_amount() -> void:
	var r: Leveling.Result = Leveling.add_exp(2, 5, -20, _table())
	assert_eq(r.level, 2)
	assert_eq(r.exp, 5)
	assert_eq(r.levels_gained, 0)


func test_death_penalty_never_delevels() -> void:
	assert_eq(Leveling.apply_death_penalty(2, 3, 0.5, _table()), 0)
	assert_eq(Leveling.apply_death_penalty(2, 0, 0.5, _table()), 0)
	assert_eq(Leveling.exp_to_next(2, _table()), 20)
