class_name MobEntity
extends Entity
## Authoritative mob body. AI via MobBrain. No player-body collision.

const DEATH_WINDOW_TICKS: int = 30

var def: MobDef
var def_index: int = 0
var brain: MobBrain
var damage_ledger: Dictionary = {}
var _death_ticks: int = 0
var _died_emitted: bool = false


func _ready() -> void:
	kind = Const.EntityKind.MOB
	collision_layer = Const.bit(int(Const.Layer.MOB_BODY))
	collision_mask = Const.mask([int(Const.Layer.WORLD), int(Const.Layer.PLATFORM_ONEWAY)] as Array[int])
	floor_max_angle = deg_to_rad(1.0)
	floor_snap_length = 4.0
	super._ready()
	brain = get_component(&"MobBrain") as MobBrain
	var health: HealthComponent = get_component(&"HealthComponent") as HealthComponent
	if health:
		health.died.connect(_on_died)


func apply_def(p_def: MobDef, p_index: int) -> void:
	def = p_def
	def_index = p_index
	if brain:
		brain.def = p_def
	var health: HealthComponent = get_component(&"HealthComponent") as HealthComponent
	if health:
		health.fill(p_def.hp, p_def.hp, 0, p_def.hp)
	damage_ledger.clear()
	_died_emitted = false
	_death_ticks = 0
	_resize_shapes(p_def.body_size)


func record_damage(eid: int, amount: int) -> void:
	if amount <= 0:
		return
	damage_ledger[eid] = int(damage_ledger.get(eid, 0)) + amount


func step_ai(tick: int) -> void:
	var health: HealthComponent = get_component(&"HealthComponent") as HealthComponent
	if health:
		health.tick()
	if brain:
		brain.step(tick, NetConfig.TICK_DT)
	if is_dead():
		_death_ticks += 1
		if _death_ticks >= DEATH_WINDOW_TICKS and map:
			map.remove_entity(eid)


func is_dead() -> bool:
	var health: HealthComponent = get_component(&"HealthComponent") as HealthComponent
	return health != null and health.is_dead()


func apply_knockback(impulse: Vector2) -> void:
	if brain:
		brain.apply_flinch_velocity(impulse)
	else:
		velocity = impulse


func to_entity_state() -> EntityState:
	var s: EntityState = super.to_entity_state()
	s.kind = int(Const.EntityKind.MOB)
	s.def_index = def_index
	s.anim = _anim()
	s.flags = 0 if (brain == null or brain.dir >= 0) else Const.FLAG_FACE_LEFT
	var health: HealthComponent = get_component(&"HealthComponent") as HealthComponent
	if health and health.max_hp > 0:
		s.hp_pct = clampi(int(round(255.0 * float(health.hp) / float(health.max_hp))), 0, 255)
	else:
		s.hp_pct = 0
	return s


func _on_died(killer_eid: int) -> void:
	if _died_emitted or map == null:
		return
	_died_emitted = true
	map.emit(SimEvent.make(Protocol.EventType.DIED, map.sim.tick, [eid, killer_eid]))
	_award_exp()


func _award_exp() -> void:
	if def == null or map == null:
		return
	var shares: Dictionary = ExpDistributor.split(def.exp, damage_ledger)
	for key: Variant in shares.keys():
		var p: PlayerEntity = map.entities.get(int(key)) as PlayerEntity
		if p:
			p.apply_exp(int(shares[key]))


func _anim() -> int:
	if is_dead():
		return Const.Anim.DEAD
	if brain == null:
		return Const.Anim.IDLE
	match brain.state:
		MobBrain.S.HURT:
			return Const.Anim.HURT
		MobBrain.S.DEAD:
			return Const.Anim.DEAD
		MobBrain.S.IDLE:
			return Const.Anim.IDLE
		_:
			return Const.Anim.WALK if absf(velocity.x) > 4.0 else Const.Anim.IDLE


func _resize_shapes(size: Vector2) -> void:
	_set_rect("CollisionShape2D", size)
	_set_rect("Hurtbox/CollisionShape2D", size)


func _set_rect(path: String, size: Vector2) -> void:
	var node: CollisionShape2D = get_node_or_null(path) as CollisionShape2D
	if node == null:
		return
	var rect := RectangleShape2D.new()
	rect.size = size
	node.shape = rect
