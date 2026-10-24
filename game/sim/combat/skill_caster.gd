class_name SkillCaster
## Fires one skill pulse (melee hit, projectile spawn, or buff).


static func fire(player: PlayerEntity, skill: SkillDef, skill_level: int, facing: int, hit_index: int) -> void:
	if player == null or skill == null:
		return
	match skill.type:
		&"projectile":
			_spawn_projectile(player, skill, skill_level, facing)
		&"buff":
			_apply_buff(player, skill, skill_level)
		_:
			CombatResolver.resolve_skill_hit(player, skill, skill_level, facing, hit_index)


static func _apply_buff(player: PlayerEntity, skill: SkillDef, skill_level: int) -> void:
	var buffs: Buffs = player.get_component(&"Buffs") as Buffs
	if buffs == null:
		return
	var stat: StringName = StringName(str(skill.buff.get("stat", "weapon_attack")))
	var add: int = int(BaseDef.level_value(skill.buff.get("add", 0), skill_level, skill.max_level))
	var dur: int = int(skill.value("duration_s", skill_level) * float(NetConfig.TICK_RATE))
	buffs.apply(stat, add, dur)


static func _spawn_projectile(player: PlayerEntity, skill: SkillDef, skill_level: int, facing: int) -> void:
	if player.map == null:
		return
	var proj: ProjectileEntity = preload("res://sim/entities/projectile_entity.tscn").instantiate()
	proj.eid = player.map.sim.ids.next()
	proj.map = player.map
	proj.setup(player, skill, skill_level, facing)
	player.map.add_projectile(proj)
