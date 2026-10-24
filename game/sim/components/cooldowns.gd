class_name Cooldowns
extends Component
## Per-skill tick counters.

var remaining: Dictionary = {}


func start(skill_id: StringName, ticks: int) -> void:
	if ticks > 0:
		remaining[skill_id] = ticks


func ready(skill_id: StringName) -> bool:
	return int(remaining.get(skill_id, 0)) <= 0


func tick() -> void:
	var dead: Array[StringName] = []
	for key: Variant in remaining.keys():
		var id: StringName = key as StringName if key is StringName else StringName(str(key))
		var left: int = int(remaining[key]) - 1
		if left <= 0:
			dead.append(id)
		else:
			remaining[id] = left
	for id: StringName in dead:
		remaining.erase(id)
