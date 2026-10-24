extends GutTest


func test_apply_exp_levels_and_grants_points() -> void:
	var p := PlayerEntity.new()
	add_child_autofree(p)
	var stats: StatsComponent = p.get_component(&"StatsComponent") as StatsComponent
	var health: HealthComponent = p.get_component(&"HealthComponent") as HealthComponent
	var need: int = Leveling.exp_to_next(1, DataRegistry.level_table)
	assert_gt(need, 0)
	var hp_before: int = health.max_hp
	p.rpg.apply_exp(need)
	assert_eq(stats.level, 2)
	assert_eq(p.rpg.exp, 0)
	assert_eq(p.rpg.ap, DataRegistry.stats.ap_per_level)
	assert_eq(p.rpg.sp, DataRegistry.stats.sp_per_level)
	assert_gt(health.max_hp, hp_before)


func test_multi_level_from_table() -> void:
	var p := PlayerEntity.new()
	add_child_autofree(p)
	var stats: StatsComponent = p.get_component(&"StatsComponent") as StatsComponent
	var a: int = Leveling.exp_to_next(1, DataRegistry.level_table)
	var b: int = Leveling.exp_to_next(2, DataRegistry.level_table)
	p.rpg.apply_exp(a + b + 4)
	assert_eq(stats.level, 3)
	assert_eq(p.rpg.exp, 4)
	assert_eq(p.rpg.ap, DataRegistry.stats.ap_per_level * 2)


func test_death_penalty_on_non_town() -> void:
	var p := PlayerEntity.new()
	add_child_autofree(p)
	p.rpg.exp = 8
	p.rpg.apply_death_penalty()
	assert_eq(p.rpg.exp, 8)
