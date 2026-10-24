class_name Climbable
extends Area2D
## Rope or ladder volume. ClimbQuery finds these; no body_entered signals.

@export_enum("rope", "ladder") var kind: String = "rope"


func _ready() -> void:
	collision_layer = Const.bit(Const.Layer.CLIMBABLE)
	collision_mask = 0
	monitoring = false
	monitorable = true
