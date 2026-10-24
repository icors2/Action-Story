class_name CombatResolver
## Authoritative hit resolution. Sim-only. Never called from client/.


static func resolve_skill_hit(
		player: PlayerEntity,
		skill: SkillDef,
		skill_level: int,
		facing: int,
		hit_index: int = 0
	) -> void:
	if player == null or player.map == null or skill == null:
		return
	var space: PhysicsDirectSpaceState2D = player.map.space_state()
	var targets: Array[Entity] = HitQuery.query_rect(
		space,
		player.global_position,
		facing,
		skill.hitbox_offset,
		skill.hitbox_size,
		int(Const.Layer.MOB_HURTBOX),
		skill.max_targets
	)
	var atk: DamageFormula.AttackInput = _player_attack(player, skill, skill_level)
	for target: Entity in targets:
		_apply_hit(player, target, atk, skill.knockback, facing, hit_index, 0)


static func resolve_direct_hit(
		player: PlayerEntity,
		target: Entity,
		skill: SkillDef,
		skill_level: int,
		facing: int,
		hit_index: int
	) -> void:
	if player == null or target == null or skill == null:
		return
	var atk: DamageFormula.AttackInput = _player_attack(player, skill, skill_level)
	_apply_hit(player, target, atk, skill.knockback, facing, hit_index, 0)


static func resolve_contact(mob: MobEntity) -> void:
	if mob == null or mob.map == null or mob.def == null or not mob.def.contact_damage:
		return
	if mob.is_dead():
		return
	var space: PhysicsDirectSpaceState2D = mob.map.space_state()
	var targets: Array[Entity] = HitQuery.query_rect(
		space,
		mob.global_position,
		1,
		Vector2.ZERO,
		mob.def.body_size,
		int(Const.Layer.PLAYER_HURTBOX),
		8
	)
	var atk: DamageFormula.AttackInput = _mob_attack(mob)
	var invuln: int = int(DataRegistry.stats.invincibility_after_hit_s * float(NetConfig.TICK_RATE))
	for target: Entity in targets:
		var player: PlayerEntity = target as PlayerEntity
		if player == null:
			continue
		var away: int = signi(int(player.global_position.x - mob.global_position.x))
		if away == 0:
			away = -mob.brain.dir if mob.brain else -1
		var kb := Vector2(float(away) * 160.0, -90.0)
		_apply_hit(mob, player, atk, kb, away, 0, invuln)
		player.enter_hurt()


static func _apply_hit(
		attacker: Entity,
		target: Entity,
		atk: DamageFormula.AttackInput,
		knockback: Vector2,
		facing: int,
		hit_index: int,
		invuln_after: int
	) -> void:
	var health: HealthComponent = target.get_component(&"HealthComponent") as HealthComponent
	if health == null or health.is_dead():
		return
	var def_in := DamageFormula.DefenseInput.new()
	def_in.level = _level_of(target)
	def_in.defense = _defense_of(target)
	var rolled: DamageFormula.Result = DamageFormula.roll(atk, def_in, DataRegistry.stats, attacker.map.sim.rng)
	var dealt: int = health.apply_damage(rolled.amount, attacker.eid, rolled.crit, invuln_after)
	if dealt <= 0:
		return
	attacker.map.emit(SimEvent.make(
		Protocol.EventType.DAMAGE,
		attacker.map.sim.tick,
		[attacker.eid, target.eid, dealt, rolled.crit, hit_index]
	))
	if attacker is PlayerEntity and target is MobEntity:
		(target as MobEntity).record_damage(attacker.eid, dealt)
	_knockback_target(target, knockback, facing)
	if target is PlayerEntity:
		emit_vitals(target as PlayerEntity)


static func _player_attack(player: PlayerEntity, skill: SkillDef, skill_level: int) -> DamageFormula.AttackInput:
	var stats: StatsComponent = player.get_component(&"StatsComponent") as StatsComponent
	var atk := DamageFormula.AttackInput.new()
	atk.level = stats.level if stats else 1
	atk.primary = stats.primary_stat() if stats else 4
	atk.secondary = stats.secondary_stat() if stats else 4
	atk.attack = stats.get_total(&"weapon_attack") if stats else DataRegistry.stats.base_weapon_attack
	atk.crit_rate = stats.get_float(&"crit_rate") if stats else DataRegistry.stats.crit_base_rate
	atk.skill_pct = skill.value("damage_pct", skill_level)
	return atk


static func _mob_attack(mob: MobEntity) -> DamageFormula.AttackInput:
	var atk := DamageFormula.AttackInput.new()
	atk.level = mob.def.level
	atk.primary = mob.def.weapon_attack
	atk.secondary = mob.def.accuracy
	atk.attack = DataRegistry.stats.mob_skill_attack
	atk.crit_rate = DataRegistry.stats.crit_base_rate
	atk.skill_pct = 100.0
	return atk


static func _level_of(e: Entity) -> int:
	if e is MobEntity and (e as MobEntity).def:
		return (e as MobEntity).def.level
	var stats: StatsComponent = e.get_component(&"StatsComponent") as StatsComponent
	return stats.level if stats else 1


static func _defense_of(e: Entity) -> int:
	if e is MobEntity and (e as MobEntity).def:
		return (e as MobEntity).def.defense
	var stats: StatsComponent = e.get_component(&"StatsComponent") as StatsComponent
	return stats.get_total(&"defense") if stats else 0


static func _knockback_target(target: Entity, knockback: Vector2, facing: int) -> void:
	if knockback == Vector2.ZERO:
		return
	var resist: float = 0.0
	if target is MobEntity and (target as MobEntity).def:
		resist = (target as MobEntity).def.knockback_resist
	var impulse := Vector2(knockback.x * signf(float(facing)), knockback.y) * (1.0 - clampf(resist, 0.0, 1.0))
	if target is PlayerEntity and (target as PlayerEntity).motor:
		(target as PlayerEntity).motor.apply_knockback(impulse, 12)
	elif target is MobEntity:
		(target as MobEntity).apply_knockback(impulse)


static func emit_vitals(player: PlayerEntity) -> void:
	if player == null or player.map == null:
		return
	var health: HealthComponent = player.get_component(&"HealthComponent") as HealthComponent
	if health == null:
		return
	player.map.emit(SimEvent.make(
		Protocol.EventType.VITALS_CHANGED,
		player.map.sim.tick,
		[player.eid, health.hp, health.max_hp, health.mp, health.max_mp],
		Protocol.Scope.PLAYER,
		player.eid
	))
