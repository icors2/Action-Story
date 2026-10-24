class_name PlayerEntity
extends Entity
## Authoritative player body. Movement is MovementMotor + InputQueue.

var owner_peer: int = 0
var input_queue: InputQueue = InputQueue.new()
var motor: MovementMotor
var action: TickStateMachine
var display_name: String = "Adventurer"
var known_skills: Dictionary = {}
var rpg: PlayerRpg


func _ready() -> void:
	kind = Const.EntityKind.PLAYER
	collision_layer = Const.bit(int(Const.Layer.PLAYER_BODY))
	collision_mask = Const.mask([int(Const.Layer.WORLD), int(Const.Layer.PLATFORM_ONEWAY)] as Array[int])
	floor_max_angle = deg_to_rad(1.0)
	floor_snap_length = 4.0
	safe_margin = 0.08
	super._ready()
	motor = get_component(&"MovementMotor") as MovementMotor
	if motor == null:
		motor = MovementMotor.new()
		motor.name = "MovementMotor"
		add_child(motor)
		motor.entity = self
		motor.on_attached()
	_ensure_combat_components()
	rpg = get_component(&"PlayerRpg") as PlayerRpg
	_init_action()
	var health: HealthComponent = get_component(&"HealthComponent") as HealthComponent
	if health:
		health.died.connect(_on_died)


func apply_record(record: CharacterRecord) -> void:
	display_name = record.name
	known_skills = record.skills.duplicate()
	if rpg:
		rpg.apply_from_record(record)
	var stats: StatsComponent = get_component(&"StatsComponent") as StatsComponent
	if stats:
		stats.level = record.level
		stats.class_id = record.class_id
		stats.base = {}
		for key: Variant in record.stats.keys():
			stats.base[StringName(str(key))] = int(record.stats[key])
		stats.recalculate_passives(self)
	var health: HealthComponent = get_component(&"HealthComponent") as HealthComponent
	if health:
		var mh: int = record.max_hp if record.max_hp > 0 else maxi(record.hp, 50)
		var mm: int = record.max_mp if record.max_mp > 0 else maxi(record.mp, 5)
		health.fill(record.hp, mh, record.mp, mm)


func to_record() -> CharacterRecord:
	var r: CharacterRecord = CharacterRecord.new_default(display_name)
	if map:
		r.map_id = map.map_id
	var health: HealthComponent = get_component(&"HealthComponent") as HealthComponent
	if health:
		r.hp = health.hp
		r.mp = health.mp
	var stats: StatsComponent = get_component(&"StatsComponent") as StatsComponent
	if stats:
		r.level = stats.level
		r.class_id = stats.class_id
		r.stats = {}
		for key: Variant in stats.base.keys():
			r.stats[String(key)] = int(stats.base[key])
	if health:
		r.max_hp = health.max_hp
		r.max_mp = health.max_mp
	if rpg:
		rpg.write_to_record(r)
	r.skills = known_skills.duplicate()
	return r


func step_movement(tick: int) -> void:
	var frame: InputFrame = input_queue.pop_for_tick(tick)
	if motor == null:
		return
	if action and action.current_name == &"dead":
		velocity = Vector2.ZERO
		return
	if action and action.current_name == &"casting" and motor.state == MovementMotor.State.GROUND:
		var locked := InputFrame.neutral(frame.seq)
		motor.step(locked, NetConfig.TICK_DT)
		return
	motor.step(frame, NetConfig.TICK_DT)


func step_actions(tick: int) -> void:
	var health: HealthComponent = get_component(&"HealthComponent") as HealthComponent
	if health:
		health.tick()
	var cds: Cooldowns = get_component(&"Cooldowns") as Cooldowns
	if cds:
		cds.tick()
	var buffs: Buffs = get_component(&"Buffs") as Buffs
	if buffs:
		buffs.tick()
	if rpg:
		rpg.tick_regen()
	if action:
		action.tick(tick)


func try_cast(intent: Intent) -> void:
	if map == null:
		return
	if action == null or not action.can_act():
		map.reject(self, intent, Protocol.Reject.BUSY)
		return
	if intent.args.size() < 2:
		map.reject(self, intent, Protocol.Reject.INVALID)
		return
	var skill_id: StringName = StringName(str(intent.args[0]))
	var facing: int = signi(int(intent.args[1]))
	if not known_skills.has(skill_id) and not known_skills.has(String(skill_id)):
		map.reject(self, intent, Protocol.Reject.NOT_ALLOWED)
		return
	var skill: SkillDef = DataRegistry.skill(skill_id)
	if skill == null or skill.type == &"passive":
		map.reject(self, intent, Protocol.Reject.INVALID)
		return
	var level: int = skill_level(skill_id)
	if level < 1:
		map.reject(self, intent, Protocol.Reject.NOT_ALLOWED)
		return
	var cds: Cooldowns = get_component(&"Cooldowns") as Cooldowns
	if cds and not cds.ready(skill_id):
		map.reject(self, intent, Protocol.Reject.COOLDOWN)
		return
	var health: HealthComponent = get_component(&"HealthComponent") as HealthComponent
	if health and not health.spend_mp(int(skill.value("mp_cost", level))):
		map.reject(self, intent, Protocol.Reject.NO_MP)
		return
	if cds:
		cds.start(skill_id, int(skill.value("cooldown_s", level) * float(NetConfig.TICK_RATE)))
	if facing != 0 and motor:
		motor.facing = facing
	action.transition(&"casting", {
		"skill": skill,
		"level": level,
		"facing": motor.facing if motor else facing,
	})
	emit_vitals()


func try_alloc_ap(intent: Intent) -> void:
	if map == null or rpg == null or intent.args.is_empty():
		if map:
			map.reject(self, intent, Protocol.Reject.INVALID)
		return
	var reason: int = rpg.alloc_ap(StringName(str(intent.args[0])))
	if reason != Protocol.Reject.NONE:
		map.reject(self, intent, reason)


func try_alloc_sp(intent: Intent) -> void:
	if map == null or rpg == null or intent.args.is_empty():
		if map:
			map.reject(self, intent, Protocol.Reject.INVALID)
		return
	var reason: int = rpg.alloc_sp(StringName(str(intent.args[0])))
	if reason != Protocol.Reject.NONE:
		map.reject(self, intent, reason)


func apply_exp(amount: int) -> void:
	if rpg:
		rpg.apply_exp(amount)


func has_skill(skill_id: StringName) -> bool:
	return known_skills.has(skill_id) or known_skills.has(String(skill_id))


func skill_level(skill_id: StringName) -> int:
	return int(known_skills.get(skill_id, known_skills.get(String(skill_id), 0)))


func set_skill_level(skill_id: StringName, level: int) -> void:
	known_skills[skill_id] = level


func emit_stats_changed() -> void:
	if map == null:
		return
	var stats: StatsComponent = get_component(&"StatsComponent") as StatsComponent
	if stats == null:
		return
	map.emit(SimEvent.make(
		Protocol.EventType.STATS_CHANGED,
		map.sim.tick,
		[
			eid, stats.level, String(stats.class_id),
			stats.get_total(&"str"), stats.get_total(&"dex"),
			stats.get_total(&"int"), stats.get_total(&"luk"),
			rpg.ap if rpg else 0, rpg.sp if rpg else 0,
			known_skills.duplicate(),
		],
		Protocol.Scope.PLAYER,
		eid
	))


func emit_vitals() -> void:
	CombatResolver.emit_vitals(self)


func try_respawn(intent: Intent) -> void:
	if map == null:
		return
	var health: HealthComponent = get_component(&"HealthComponent") as HealthComponent
	if health == null or not health.is_dead():
		map.reject(self, intent, Protocol.Reject.INVALID)
		return
	health.hp = maxi(1, health.max_hp / 2)
	health.invuln_ticks = 0
	global_position = map.spawn_point(&"spawn")
	velocity = Vector2.ZERO
	if action:
		action.transition(&"idle")
	map.emit(SimEvent.make(
		Protocol.EventType.VITALS_CHANGED,
		map.sim.tick,
		[eid, health.hp, health.max_hp, health.mp, health.max_mp],
		Protocol.Scope.PLAYER,
		eid
	))


func enter_hurt() -> void:
	if action == null:
		return
	if action.current_name == &"dead":
		return
	if action.current_name != &"hurt":
		action.transition(&"hurt")


func to_entity_state() -> EntityState:
	var s: EntityState = super.to_entity_state()
	s.kind = int(Const.EntityKind.PLAYER)
	s.anim = _anim()
	s.flags = 0 if (motor == null or motor.facing >= 0) else Const.FLAG_FACE_LEFT
	var health: HealthComponent = get_component(&"HealthComponent") as HealthComponent
	if health and health.max_hp > 0:
		s.hp_pct = clampi(int(round(255.0 * float(health.hp) / float(health.max_hp))), 0, 255)
	return s


func _on_died(killer_eid: int) -> void:
	if action and action.current_name != &"dead":
		action.transition(&"dead")
	if rpg:
		rpg.apply_death_penalty()
	if map:
		map.emit(SimEvent.make(Protocol.EventType.DIED, map.sim.tick, [eid, killer_eid]))


func _anim() -> int:
	if action:
		match action.current_name:
			&"casting":
				return Const.Anim.ATTACK
			&"hurt":
				return Const.Anim.HURT
			&"dead":
				return Const.Anim.DEAD
	if motor == null:
		return Const.Anim.IDLE
	match motor.state:
		MovementMotor.State.CLIMB:
			return Const.Anim.CLIMB
		MovementMotor.State.AIR:
			return Const.Anim.AIR
		_:
			return Const.Anim.WALK if absf(velocity.x) > 8.0 else Const.Anim.IDLE


func _init_action() -> void:
	action = TickStateMachine.new()
	action.owner_entity = self
	action.add(&"idle", IdleState.new())
	action.add(&"casting", CastingState.new())
	action.add(&"hurt", HurtState.new())
	action.add(&"dead", DeadState.new())
	action.transition(&"idle")


func _ensure_combat_components() -> void:
	if get_component(&"StatsComponent") == null:
		var stats := StatsComponent.new()
		stats.name = "StatsComponent"
		add_child(stats)
		stats.entity = self
		_components[&"StatsComponent"] = stats
		stats.on_attached()
	if get_component(&"HealthComponent") == null:
		var health := HealthComponent.new()
		health.name = "HealthComponent"
		add_child(health)
		health.entity = self
		_components[&"HealthComponent"] = health
		health.on_attached()
		health.fill(50, 50, 5, 5)
	_ensure_named(&"PlayerRpg", PlayerRpg.new())
	_ensure_named(&"Cooldowns", Cooldowns.new())
	_ensure_named(&"Buffs", Buffs.new())


func _ensure_named(comp_name: StringName, node: Component) -> void:
	if get_component(comp_name) != null:
		return
	node.name = String(comp_name)
	add_child(node)
	node.entity = self
	_components[comp_name] = node
	node.on_attached()
