class_name InputQueue
extends RefCounted
## Jitter buffer: reorder, drop stale, repeat last input up to 6 ticks.

const MAX_REPEAT: int = 6

var last_processed_seq: int = 0
var _by_seq: Dictionary = {}
var _last: InputFrame = InputFrame.neutral(0)
var _repeats: int = 0


func push_frames(frames: Array[InputFrame]) -> void:
	for f: InputFrame in frames:
		if f.seq <= last_processed_seq or _by_seq.has(f.seq):
			continue
		_by_seq[f.seq] = f


func pop_for_tick(_tick: int) -> InputFrame:
	var want: int = last_processed_seq + 1
	if _by_seq.has(want):
		var f: InputFrame = _by_seq[want]
		_by_seq.erase(want)
		last_processed_seq = want
		_last = f
		_repeats = 0
		return f
	if _repeats < MAX_REPEAT and last_processed_seq > 0:
		_repeats += 1
		last_processed_seq = want
		return _copy_seq(_last, want)
	last_processed_seq = want
	return InputFrame.neutral(want)


func pending_count() -> int:
	return _by_seq.size()


func _copy_seq(src: InputFrame, seq: int) -> InputFrame:
	var f := InputFrame.new()
	f.seq = seq
	f.move_x = src.move_x
	f.move_y = src.move_y
	f.buttons = src.buttons & InputFrame.BTN_JUMP_HELD
	return f
