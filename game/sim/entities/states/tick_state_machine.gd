class_name TickStateMachine
extends RefCounted

signal state_changed(from: StringName, to: StringName)

var owner_entity: Entity
var current_name: StringName = &""
var current: TickState
var _states: Dictionary = {}


func add(state_name: StringName, state: TickState) -> void:
	state.machine = self
	_states[state_name] = state


func transition(to: StringName, args: Dictionary = {}) -> void:
	assert(_states.has(to), "Unknown state %s" % to)
	var from: StringName = current_name
	if current:
		current.exit()
	current_name = to
	current = _states[to]
	current.ticks_in_state = 0
	current.enter(args)
	state_changed.emit(from, to)


func tick(t: int) -> void:
	if current == null:
		return
	current.ticks_in_state += 1
	var next: StringName = current.tick(t)
	if next != &"":
		transition(next)


func can_act() -> bool:
	return current != null and current.can_act()
