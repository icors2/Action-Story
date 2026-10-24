class_name InterpolationBuffer
extends RefCounted
## Buffers timestamped positions for a remote entity and samples them in the past.

const MAX_SAMPLES: int = 32
const MAX_EXTRAPOLATE_S: float = 0.1

var _times: PackedFloat64Array = PackedFloat64Array()
var _positions: PackedVector2Array = PackedVector2Array()


func push(server_time: float, pos: Vector2) -> void:
	if not _times.is_empty() and server_time <= _times[_times.size() - 1]:
		return
	_times.append(server_time)
	_positions.append(pos)
	if _times.size() > MAX_SAMPLES:
		_times.remove_at(0)
		_positions.remove_at(0)


func sample(render_time: float) -> Vector2:
	var n: int = _times.size()
	if n == 0:
		return Vector2.ZERO
	if render_time <= _times[0]:
		return _positions[0]
	for i: int in range(n - 1):
		if render_time >= _times[i] and render_time <= _times[i + 1]:
			var t: float = (render_time - _times[i]) / maxf(_times[i + 1] - _times[i], 0.0001)
			return _positions[i].lerp(_positions[i + 1], t)
	if n >= 2:
		var dt: float = minf(render_time - _times[n - 1], MAX_EXTRAPOLATE_S)
		var vel: Vector2 = (_positions[n - 1] - _positions[n - 2]) / maxf(_times[n - 1] - _times[n - 2], 0.0001)
		return _positions[n - 1] + vel * dt
	return _positions[n - 1]


func latest() -> Vector2:
	if _positions.is_empty():
		return Vector2.ZERO
	return _positions[_positions.size() - 1]
