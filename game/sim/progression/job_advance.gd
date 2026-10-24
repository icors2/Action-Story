class_name JobAdvance
## Validates and applies a class change.


static func validate(player: PlayerEntity, to_id: StringName, skip_reqs: bool) -> int:
	if player == null:
		return Protocol.Reject.INVALID
	var dest: ClassDef = DataRegistry.classes.get(to_id)
	if dest == null:
		return Protocol.Reject.INVALID
	var stats: StatsComponent = player.get_component(&"StatsComponent") as StatsComponent
	if stats == null:
		return Protocol.Reject.INVALID
	if dest.parent_id != stats.class_id:
		return Protocol.Reject.NOT_ALLOWED
	if skip_reqs:
		return Protocol.Reject.NONE
	var req: Dictionary = dest.advance_requirements
	var need_lv: int = int(req.get("level", dest.advance_level))
	if stats.level < need_lv:
		return Protocol.Reject.NOT_ALLOWED
	var need_stats: Dictionary = req.get("stats", {})
	for key: Variant in need_stats.keys():
		if stats.get_total(StringName(str(key))) < int(need_stats[key]):
			return Protocol.Reject.NOT_ALLOWED
	return Protocol.Reject.NONE


static func apply(player: PlayerEntity, to_id: StringName) -> void:
	var dest: ClassDef = DataRegistry.classes.get(to_id)
	var stats: StatsComponent = player.get_component(&"StatsComponent") as StatsComponent
	if dest == null or stats == null:
		return
	stats.class_id = dest.id
	stats.recalculate()
	for skill: SkillDef in DataRegistry.skills.values():
		if skill.class_id == dest.id and not player.has_skill(skill.id):
			player.set_skill_level(skill.id, 0)
	stats.recalculate_passives(player)
	player.emit_stats_changed()
