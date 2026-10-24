extends GutTest


func test_registry_loaded() -> void:
	assert_true(DataRegistry.is_loaded())
	assert_not_null(DataRegistry.stats)
	assert_true(DataRegistry.mobs.has(&"puddlet"))
	assert_true(DataRegistry.skills.has(&"novice_strike"))
	assert_true(DataRegistry.maps.has(&"map_test_flat"))
	assert_true(DataRegistry.maps.has(&"map_test_movement"))


func test_level_value_pair_interpolates() -> void:
	assert_eq(BaseDef.level_value([10, 20], 1, 11), 10.0)
	assert_eq(BaseDef.level_value([10, 20], 11, 11), 20.0)
	assert_eq(BaseDef.level_value([10, 20], 6, 11), 15.0)


func test_level_value_explicit_array() -> void:
	assert_eq(BaseDef.level_value([1, 2, 3], 2, 3), 2.0)


func test_missing_file_records_error() -> void:
	var before: int = DataRegistry.errors().size()
	var empty: Dictionary = DataRegistry._read_json("res://data/does_not_exist.json")
	assert_true(empty.is_empty())
	assert_gt(DataRegistry.errors().size(), before)


func test_duplicate_id_records_error() -> void:
	var target: Dictionary = {}
	var index: Dictionary = {"mobs": ["res://data/mobs/field_mobs.json"]}
	DataRegistry._load_category(index, "mobs", "mobs", target, func(d: Dictionary) -> BaseDef: return MobDef.from_dict(d))
	var err_before: int = DataRegistry.errors().size()
	DataRegistry._load_category(index, "mobs", "mobs", target, func(d: Dictionary) -> BaseDef: return MobDef.from_dict(d))
	assert_gt(DataRegistry.errors().size(), err_before)
