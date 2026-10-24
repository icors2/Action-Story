class_name TickState
extends RefCounted
## Base for tick-driven states. Return a state name from tick() to transition, or &"" to stay.

var machine: TickStateMachine
var ticks_in_state: int = 0


func enter(_args: Dictionary) -> void:
	pass


func exit() -> void:
	pass


func tick(_t: int) -> StringName:
	return &""


func can_act() -> bool:
	return false
