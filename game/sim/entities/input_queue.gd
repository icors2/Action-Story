class_name InputQueue
extends RefCounted
## Jitter buffer for input frames. Phase 1 fills missing-frame / reorder behavior.

var last_processed_seq: int = 0
var _pending: Array[InputFrame] = []


func push_frames(frames: Array[InputFrame]) -> void:
	for f: InputFrame in frames:
		_pending.append(f)


func pop_for_tick(_tick: int) -> InputFrame:
	if _pending.is_empty():
		last_processed_seq += 1
		return InputFrame.neutral(last_processed_seq)
	var f: InputFrame = _pending.pop_front()
	last_processed_seq = f.seq
	return f
