class_name CastingState
extends TickState
## Locks the player while a skill animation plays; fires the hit on hit_tick.

var skill: SkillDef
var skill_level: int
var facing: int
var hit_fired: bool


func enter(args: Dictionary) -> void:
	skill = args["skill"]
	skill_level = int(args["level"])
	facing = int(args["facing"])
	hit_fired = false


func tick(_t: int) -> StringName:
	if not hit_fired and ticks_in_state >= skill.hit_tick:
		hit_fired = true
		var player: PlayerEntity = machine.owner_entity as PlayerEntity
		CombatResolver.resolve_skill_hit(player, skill, skill_level, facing)
	if ticks_in_state >= skill.cast_ticks:
		return &"idle"
	return &""
