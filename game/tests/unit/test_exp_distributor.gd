extends GutTest


func test_split_conserves_total() -> void:
	var out: Dictionary = ExpDistributor.split(10, {1: 3, 2: 3, 3: 3})
	var sum: int = 0
	for v: Variant in out.values():
		sum += int(v)
	assert_eq(sum, 10)
	assert_eq(int(out[1]), 4)
	assert_eq(int(out[2]), 3)
	assert_eq(int(out[3]), 3)


func test_proportional() -> void:
	var out: Dictionary = ExpDistributor.split(100, {10: 75, 11: 25})
	assert_eq(int(out[10]), 75)
	assert_eq(int(out[11]), 25)


func test_empty_or_zero() -> void:
	assert_true(ExpDistributor.split(10, {}).is_empty())
	assert_true(ExpDistributor.split(0, {1: 5}).is_empty())
	assert_true(ExpDistributor.split(10, {1: 0}).is_empty())


func test_tie_goes_to_lowest_eid() -> void:
	var out: Dictionary = ExpDistributor.split(5, {8: 1, 3: 1})
	assert_eq(int(out[3]) + int(out[8]), 5)
	assert_eq(int(out[3]), 3)
	assert_eq(int(out[8]), 2)
