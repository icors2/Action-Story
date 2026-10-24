extends GutTest


func _make(hp: int = 10, mp: int = 5) -> HealthComponent:
	var h := HealthComponent.new()
	add_child_autofree(h)
	h.fill(hp, hp, mp, mp)
	return h


func test_invuln_blocks_then_expires() -> void:
	var h: HealthComponent = _make()
	assert_eq(h.apply_damage(3, 1, false, 4), 3)
	assert_eq(h.hp, 7)
	assert_eq(h.apply_damage(3, 1, false), 0)
	for _i: int in 4:
		h.tick()
	assert_eq(h.apply_damage(2, 1, false), 2)
	assert_eq(h.hp, 5)


func test_death_emits_once() -> void:
	var h: HealthComponent = _make(4)
	var deaths: Array[int] = []
	h.died.connect(func(k: int) -> void: deaths.append(k))
	assert_eq(h.apply_damage(4, 9, true), 4)
	assert_true(h.is_dead())
	assert_eq(h.apply_damage(1, 9, false), 0)
	assert_eq(deaths.size(), 1)
	assert_eq(deaths[0], 9)


func test_heal_caps_at_max() -> void:
	var h: HealthComponent = _make(10)
	h.hp = 8
	assert_eq(h.heal(5), 2)
	assert_eq(h.hp, 10)
	assert_eq(h.heal(3), 0)


func test_heal_dead_does_nothing() -> void:
	var h: HealthComponent = _make(2)
	h.apply_damage(2, 1, false)
	assert_eq(h.heal(10), 0)
	assert_true(h.is_dead())


func test_restore_mp_caps() -> void:
	var h: HealthComponent = _make(10, 5)
	h.mp = 3
	assert_eq(h.restore_mp(4), 2)
	assert_eq(h.mp, 5)
	assert_eq(h.restore_mp(1), 0)


func test_spend_mp() -> void:
	var h: HealthComponent = _make(10, 5)
	assert_true(h.spend_mp(3))
	assert_eq(h.mp, 2)
	assert_false(h.spend_mp(4))
	assert_eq(h.mp, 2)
	assert_true(h.spend_mp(0))
