class_name PlayerRpg
extends Component
## EXP, AP/SP, regen, and death penalty. Skills stay on PlayerEntity.

var exp: int = 0
var ap: int = 0
var sp: int = 0
var _hp_regen: int = 0
var _mp_regen: int = 0


func apply_from_record(record: CharacterRecord) -> void:
	exp = record.exp
	ap = record.ap
	sp = record.sp


func write_to_record(record: CharacterRecord) -> void:
	record.exp = exp
	record.ap = ap
	record.sp = sp


## Awards EXP, levels up, rolls HP/MP, grants AP/SP.
func apply_exp(amount: int) -> void:
	if amount <= 0:
		return
	var stats: StatsComponent = entity.get_component(&"StatsComponent") as StatsComponent
	if stats == null:
		return
	var result: Leveling.Result = Leveling.add_exp(stats.level, exp, amount, DataRegistry.level_table)
	exp = result.exp
	_emit_exp(amount, result.level)
	if result.levels_gained > 0:
		_apply_level_ups(stats, result)
	var player: PlayerEntity = entity as PlayerEntity
	if player:
		player.emit_stats_changed()


func alloc_ap(stat: StringName) -> int:
	if not StatsComponent.PRIMARY.has(stat):
		return Protocol.Reject.INVALID
	if ap <= 0:
		return Protocol.Reject.NOT_ALLOWED
	var stats: StatsComponent = entity.get_component(&"StatsComponent") as StatsComponent
	if stats == null:
		return Protocol.Reject.INVALID
	ap -= 1
	stats.base[stat] = int(stats.base.get(stat, 0)) + 1
	stats.recalculate()
	var player: PlayerEntity = entity as PlayerEntity
	if player:
		player.emit_stats_changed()
	return Protocol.Reject.NONE


func alloc_sp(skill_id: StringName) -> int:
	var player: PlayerEntity = entity as PlayerEntity
	var stats: StatsComponent = entity.get_component(&"StatsComponent") as StatsComponent
	if player == null or stats == null:
		return Protocol.Reject.INVALID
	var skill: SkillDef = DataRegistry.skills.get(skill_id)
	if skill == null:
		return Protocol.Reject.INVALID
	if not _class_owns(stats.class_id, skill.class_id):
		return Protocol.Reject.NOT_ALLOWED
	if not _prereqs_met(player, skill):
		return Protocol.Reject.NOT_ALLOWED
	var lv: int = player.skill_level(skill_id)
	if lv >= skill.max_level:
		return Protocol.Reject.NOT_ALLOWED
	if sp <= 0:
		return Protocol.Reject.NOT_ALLOWED
	sp -= 1
	player.set_skill_level(skill_id, lv + 1)
	stats.recalculate_passives(player)
	player.emit_stats_changed()
	return Protocol.Reject.NONE


func apply_death_penalty() -> void:
	var player: PlayerEntity = entity as PlayerEntity
	if player == null or player.map == null or player.map.def == null:
		return
	if bool(player.map.def.flags.get("town", false)):
		return
	if bool(player.map.def.flags.get("no_exp_loss", false)):
		return
	var stats: StatsComponent = entity.get_component(&"StatsComponent") as StatsComponent
	if stats == null:
		return
	var next_exp: int = Leveling.apply_death_penalty(
		stats.level, exp, DataRegistry.stats.death_exp_loss_pct, DataRegistry.level_table
	)
	var lost: int = exp - next_exp
	exp = next_exp
	_emit_exp(-lost, stats.level)
	if lost > 0:
		player.map.emit(SimEvent.make(
			Protocol.EventType.SYSTEM_MESSAGE,
			player.map.sim.tick,
			["Lost %d EXP." % lost],
			Protocol.Scope.PLAYER,
			player.eid
		))


func tick_regen() -> void:
	var health: HealthComponent = entity.get_component(&"HealthComponent") as HealthComponent
	if health == null or health.is_dead():
		return
	var still: bool = _is_still()
	var hp_every: int = maxi(1, int(DataRegistry.stats.hp_regen_interval_s * float(NetConfig.TICK_RATE)))
	var mp_every: int = maxi(1, int(DataRegistry.stats.mp_regen_interval_s * float(NetConfig.TICK_RATE)))
	_hp_regen += 1
	_mp_regen += 1
	var changed: bool = false
	if _hp_regen >= hp_every:
		_hp_regen = 0
		if health.heal(2 if still else 1) > 0:
			changed = true
	if _mp_regen >= mp_every:
		_mp_regen = 0
		if health.restore_mp(2 if still else 1) > 0:
			changed = true
	if changed:
		var player: PlayerEntity = entity as PlayerEntity
		if player:
			player.emit_vitals()


func _apply_level_ups(stats: StatsComponent, result: Leveling.Result) -> void:
	var cfg: StatsConfig = DataRegistry.stats
	var cdef: ClassDef = DataRegistry.class_def(stats.class_id)
	var health: HealthComponent = entity.get_component(&"HealthComponent") as HealthComponent
	var gained: int = result.levels_gained
	var from: int = stats.level
	stats.level = result.level
	for i: int in gained:
		ap += cfg.ap_per_level
		sp += cfg.sp_per_level
		if health and cdef:
			health.max_hp += _roll_range(cdef.hp_per_level)
			health.max_mp += _roll_range(cdef.mp_per_level)
			health.hp = health.max_hp
			health.mp = health.max_mp
		var player: PlayerEntity = entity as PlayerEntity
		if player and player.map:
			player.map.emit(SimEvent.make(
				Protocol.EventType.LEVEL_UP,
				player.map.sim.tick,
				[player.eid, from + i + 1],
				Protocol.Scope.PLAYER,
				player.eid
			))
	stats.recalculate()
	var p: PlayerEntity = entity as PlayerEntity
	if p:
		p.emit_vitals()


func _emit_exp(amount: int, level: int) -> void:
	var player: PlayerEntity = entity as PlayerEntity
	if player == null or player.map == null:
		return
	player.map.emit(SimEvent.make(
		Protocol.EventType.EXP_GAINED,
		player.map.sim.tick,
		[player.eid, amount, level, exp],
		Protocol.Scope.PLAYER,
		player.eid
	))


func _class_owns(class_id: StringName, skill_class: StringName) -> bool:
	var cid: StringName = class_id
	while cid != &"":
		if cid == skill_class:
			return true
		var cdef: ClassDef = DataRegistry.classes.get(cid)
		if cdef == null:
			break
		cid = cdef.parent_id
	return false


func _prereqs_met(player: PlayerEntity, skill: SkillDef) -> bool:
	for key: Variant in skill.required_skills.keys():
		if player.skill_level(StringName(str(key))) < int(skill.required_skills[key]):
			return false
	return true


func _roll_range(r: Vector2i) -> int:
	var lo: int = mini(r.x, r.y)
	var hi: int = maxi(r.x, r.y)
	if entity and entity.map and entity.map.sim:
		return entity.map.sim.rng.randi_range(lo, hi)
	return lo


func _is_still() -> bool:
	var player: PlayerEntity = entity as PlayerEntity
	if player == null or player.motor == null:
		return false
	return player.motor.state == MovementMotor.State.GROUND and absf(player.velocity.x) < 8.0
