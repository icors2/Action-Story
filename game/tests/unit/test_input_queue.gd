extends GutTest


func _frame(seq: int, x: int = 0) -> InputFrame:
	var f := InputFrame.new()
	f.seq = seq
	f.move_x = x
	return f


func test_missing_frame_repeats_last() -> void:
	var q := InputQueue.new()
	var first: Array[InputFrame] = [_frame(1, 1)]
	q.push_frames(first)
	assert_eq(q.pop_for_tick(1).move_x, 1)
	var repeated: InputFrame = q.pop_for_tick(2)
	assert_eq(repeated.seq, 2)
	assert_eq(repeated.move_x, 1)


func test_stale_and_duplicate_ignored() -> void:
	var q := InputQueue.new()
	var batch: Array[InputFrame] = [_frame(1, 1), _frame(1, -1), _frame(2, 1)]
	q.push_frames(batch)
	assert_eq(q.pop_for_tick(1).move_x, 1)
	assert_eq(q.pop_for_tick(2).move_x, 1)


func test_out_of_order_sorted_by_seq() -> void:
	var q := InputQueue.new()
	var late: Array[InputFrame] = [_frame(2, 1)]
	var early: Array[InputFrame] = [_frame(1, -1)]
	q.push_frames(late)
	q.push_frames(early)
	assert_eq(q.pop_for_tick(1).move_x, -1)
	assert_eq(q.pop_for_tick(2).move_x, 1)


func test_repeat_then_neutral_after_max() -> void:
	var q := InputQueue.new()
	var first: Array[InputFrame] = [_frame(1, 1)]
	q.push_frames(first)
	q.pop_for_tick(1)
	for i: int in InputQueue.MAX_REPEAT:
		assert_eq(q.pop_for_tick(i + 2).move_x, 1)
	assert_eq(q.pop_for_tick(20).move_x, 0)
