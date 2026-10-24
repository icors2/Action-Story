extends GutTest


func test_ready_after_ticks() -> void:
	var cd := Cooldowns.new()
	add_child_autofree(cd)
	assert_true(cd.ready(&"novice_strike"))
	cd.start(&"novice_strike", 3)
	assert_false(cd.ready(&"novice_strike"))
	cd.tick()
	cd.tick()
	assert_false(cd.ready(&"novice_strike"))
	cd.tick()
	assert_true(cd.ready(&"novice_strike"))


func test_zero_ticks_does_not_block() -> void:
	var cd := Cooldowns.new()
	add_child_autofree(cd)
	cd.start(&"x", 0)
	assert_true(cd.ready(&"x"))
