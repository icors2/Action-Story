extends GutTest


func test_push_pop_order() -> void:
	var buf := RingBuffer.new(3)
	buf.push("a")
	buf.push("b")
	assert_eq(buf.size(), 2)
	assert_eq(buf.pop(), "a")
	assert_eq(buf.pop(), "b")
	assert_true(buf.is_empty())


func test_overwrite_when_full() -> void:
	var buf := RingBuffer.new(2)
	buf.push(1)
	buf.push(2)
	buf.push(3)
	assert_eq(buf.size(), 2)
	assert_eq(buf.pop(), 2)
	assert_eq(buf.pop(), 3)
