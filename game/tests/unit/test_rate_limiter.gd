extends GutTest


func test_allows_up_to_max_then_blocks() -> void:
	var lim := RateLimiter.new(2, 1.0)
	assert_true(lim.allow(0.0))
	assert_true(lim.allow(0.1))
	assert_false(lim.allow(0.2))


func test_window_expires() -> void:
	var lim := RateLimiter.new(1, 1.0)
	assert_true(lim.allow(0.0))
	assert_false(lim.allow(0.5))
	assert_true(lim.allow(1.1))
