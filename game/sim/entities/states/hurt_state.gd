class_name HurtState
extends TickState

const LOCK_TICKS: int = 12


func tick(_t: int) -> StringName:
	var health: HealthComponent = machine.owner_entity.get_component(&"HealthComponent") as HealthComponent
	if health and health.is_dead():
		return &"dead"
	if ticks_in_state >= LOCK_TICKS:
		return &"idle"
	return &""
