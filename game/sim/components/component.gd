class_name Component
extends Node
## Base for entity components. Override on_attached() instead of _ready() for sibling lookups.

var entity: Entity


func on_attached() -> void:
	pass
