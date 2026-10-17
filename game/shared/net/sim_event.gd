class_name SimEvent
extends RefCounted
## An authoritative result emitted by the simulation.

var type: int
var tick: int
var scope: int = Protocol.Scope.MAP
var target_eid: int = 0
var data: Array = []


static func make(t: int, p_tick: int, p_data: Array, p_scope: int = Protocol.Scope.MAP, p_target: int = 0) -> SimEvent:
	var e := SimEvent.new()
	e.type = t
	e.tick = p_tick
	e.data = p_data
	e.scope = p_scope
	e.target_eid = p_target
	return e


func to_wire() -> Array:
	return [type, tick, data]


static func from_wire(w: Array) -> SimEvent:
	if w.size() < 3:
		return SimEvent.make(0, 0, [])
	return SimEvent.make(int(w[0]), int(w[1]), w[2])
