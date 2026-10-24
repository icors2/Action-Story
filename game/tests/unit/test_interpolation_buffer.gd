extends GutTest


func test_samples_between_points() -> void:
	var buf := InterpolationBuffer.new()
	buf.push(1.0, Vector2(0, 0))
	buf.push(2.0, Vector2(10, 0))
	var mid: Vector2 = buf.sample(1.5)
	assert_almost_eq(mid.x, 5.0, 0.001)


func test_ignores_out_of_order() -> void:
	var buf := InterpolationBuffer.new()
	buf.push(2.0, Vector2(10, 0))
	buf.push(1.0, Vector2(0, 0))
	assert_eq(buf.latest(), Vector2(10, 0))
