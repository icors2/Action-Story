class_name RateLimiter
extends RefCounted
## Token-bucket / sliding-window limiter. Tests pass `now` to stay deterministic.

var _max: int
var _window_s: float
var _times: Array[float] = []


func _init(p_max: int = 30, p_window_s: float = 1.0) -> void:
	_max = p_max
	_window_s = p_window_s


func allow(now: float = -1.0) -> bool:
	var t: float = now
	if t < 0.0:
		t = float(Time.get_ticks_msec()) / 1000.0
	var cutoff: float = t - _window_s
	var kept: Array[float] = []
	for prev: float in _times:
		if prev >= cutoff:
			kept.append(prev)
	_times = kept
	if _times.size() >= _max:
		return false
	_times.append(t)
	return true


func remaining(now: float = -1.0) -> int:
	var t: float = now
	if t < 0.0:
		t = float(Time.get_ticks_msec()) / 1000.0
	var cutoff: float = t - _window_s
	var n: int = 0
	for prev: float in _times:
		if prev >= cutoff:
			n += 1
	return maxi(_max - n, 0)
