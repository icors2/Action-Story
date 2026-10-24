class_name Hurtbox
extends Area2D
## Damageable region. Hit detection is done by shape QUERIES (HitQuery), not area signals.

@export var team_layer: Const.Layer = Const.Layer.MOB_HURTBOX


func _ready() -> void:
	collision_layer = Const.bit(int(team_layer))
	collision_mask = 0
	monitoring = false
	monitorable = true


func owner_entity() -> Entity:
	return get_parent() as Entity
