extends GutTest


func _setup() -> Array:
	var e := Entity.new()
	add_child_autofree(e)
	var stats := StatsComponent.new()
	stats.name = "StatsComponent"
	e.add_child(stats)
	stats.entity = e
	e._components[&"StatsComponent"] = stats
	stats.on_attached()
	var buffs := Buffs.new()
	buffs.name = "Buffs"
	e.add_child(buffs)
	buffs.entity = e
	e._components[&"Buffs"] = buffs
	buffs.on_attached()
	return [e, stats, buffs]


func test_apply_then_expire_restores() -> void:
	var bits: Array = _setup()
	var stats: StatsComponent = bits[1]
	var buffs: Buffs = bits[2]
	var before_wa: int = stats.get_total(&"weapon_attack")
	buffs.apply(&"weapon_attack", 8, 3)
	assert_eq(stats.get_total(&"weapon_attack"), before_wa + 8)
	buffs.tick()
	buffs.tick()
	assert_eq(stats.get_total(&"weapon_attack"), before_wa + 8)
	buffs.tick()
	assert_eq(stats.get_total(&"weapon_attack"), before_wa)


func test_stacking_same_stat() -> void:
	var bits: Array = _setup()
	var stats: StatsComponent = bits[1]
	var buffs: Buffs = bits[2]
	var before: int = stats.get_total(&"str")
	buffs.apply(&"str", 2, 10)
	buffs.apply(&"str", 3, 10)
	assert_eq(stats.get_total(&"str"), before + 5)
