class_name Entity
extends CharacterBody2D
## Base for all simulated entities. Contains NO visuals.

var eid: int = 0
var kind: Const.EntityKind = Const.EntityKind.MOB
var map: MapInstance
var _components: Dictionary = {}


func _ready() -> void:
	for child: Node in get_children():
		if child is Component:
			var c: Component = child
			c.entity = self
			_components[StringName(c.name)] = c
			c.on_attached()


func get_component(component_name: StringName) -> Component:
	return _components.get(component_name)


func has_component(component_name: StringName) -> bool:
	return _components.has(component_name)


func to_entity_state() -> EntityState:
	var s := EntityState.new()
	s.eid = eid
	s.kind = kind
	s.x = int(round(global_position.x * NetConfig.POS_QUANT))
	s.y = int(round(global_position.y * NetConfig.POS_QUANT))
	return s
