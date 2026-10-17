class_name IdAllocator
extends RefCounted
## Monotonic runtime entity IDs. Never reused within a process lifetime.

var _next: int = 1


func next() -> int:
	var id: int = _next
	_next += 1
	return id
