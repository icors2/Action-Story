class_name RingBuffer
extends RefCounted
## Fixed-capacity ring. Push overwrites the oldest entry when full.

var _buf: Array = []
var _cap: int = 1
var _head: int = 0
var _count: int = 0


func _init(cap: int = 16) -> void:
	_cap = maxi(cap, 1)
	_buf.resize(_cap)


func push(item: Variant) -> void:
	var idx: int = (_head + _count) % _cap
	if _count == _cap:
		_buf[_head] = item
		_head = (_head + 1) % _cap
	else:
		_buf[idx] = item
		_count += 1


func pop() -> Variant:
	if _count == 0:
		return null
	var item: Variant = _buf[_head]
	_buf[_head] = null
	_head = (_head + 1) % _cap
	_count -= 1
	return item


func peek(offset: int = 0) -> Variant:
	if offset < 0 or offset >= _count:
		return null
	return _buf[(_head + offset) % _cap]


func size() -> int:
	return _count


func is_empty() -> bool:
	return _count == 0


func clear() -> void:
	_buf.clear()
	_buf.resize(_cap)
	_head = 0
	_count = 0
