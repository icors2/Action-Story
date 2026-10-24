class_name DeadState
extends TickState


func enter(_args: Dictionary) -> void:
	var body: Entity = machine.owner_entity
	body.velocity = Vector2.ZERO
