extends GutTest


func test_monotonic_never_reuses() -> void:
	var ids := IdAllocator.new()
	assert_eq(ids.next(), 1)
	assert_eq(ids.next(), 2)
	assert_eq(ids.next(), 3)
