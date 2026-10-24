class_name CastingState
extends TickState
## Locks the player while a skill plays; fires each hit on its tick.

var skill: SkillDef
var skill_level: int
var facing: int
var hit_fired: bool
var _fired_hits: int


func enter(args: Dictionary) -> void:
	skill = args["skill"]
	skill_level = int(args["level"])
	facing = int(args["facing"])
	hit_fired = false
	_fired_hits = 0


func tick(_t: int) -> StringName:
	var player: PlayerEntity = machine.owner_entity as PlayerEntity
	var pulses: int = skill.hits if skill.type == &"active_attack" else 1
	while _fired_hits < pulses:
		var when: int = skill.hit_tick + _fired_hits * skill.hit_spacing_ticks
		if ticks_in_state < when:
			break
		SkillCaster.fire(player, skill, skill_level, facing, _fired_hits)
		_fired_hits += 1
		hit_fired = true
	if ticks_in_state >= skill.cast_ticks:
		return &"idle"
	return &""
