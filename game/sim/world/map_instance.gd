class_name MapInstance
extends SubViewport
## One loaded map with its own physics space (World2D). Owns all entities on that map.

var map_id: StringName
var def: MapDef
var sim: WorldSim
var entities: Dictionary = {}

var _map_root: Node2D
var _entity_root: Node2D
var _spawners: Array[Spawner] = []


func setup(p_sim: WorldSim, p_def: MapDef) -> void:
	sim = p_sim
	def = p_def
	map_id = p_def.id
	name = "Map_%s" % map_id
	world_2d = World2D.new()
	disable_3d = true
	render_target_update_mode = SubViewport.UPDATE_DISABLED
	_map_root = (load(def.scene_path) as PackedScene).instantiate()
	add_child(_map_root)
	_entity_root = Node2D.new()
	_entity_root.name = "Entities"
	add_child(_entity_root)
	_build_spawners()


func start_spawners() -> void:
	var total: int = 0
	for s: Spawner in _spawners:
		s.populate()
		total += s.alive_eids.size()
	if total > 0:
		Log.info("sim", "spawned %d mobs on %s" % [total, map_id])


func step(tick: int) -> void:
	var ents: Array = entities.values()
	for e: Entity in ents:
		if e is PlayerEntity:
			(e as PlayerEntity).step_movement(tick)
	for e: Entity in ents:
		if e is PlayerEntity:
			(e as PlayerEntity).step_actions(tick)
	for e: Entity in ents:
		if e is MobEntity:
			(e as MobEntity).step_ai(tick)
	var after_ai: Array = entities.values()
	for e: Entity in after_ai:
		if e is MobEntity:
			CombatResolver.resolve_contact(e as MobEntity)
	for s: Spawner in _spawners:
		s.step(tick)


func spawn_player(record: CharacterRecord, owner_peer: int, eid: int) -> PlayerEntity:
	var p: PlayerEntity = preload("res://sim/entities/player_entity.tscn").instantiate()
	p.eid = eid
	p.owner_peer = owner_peer
	p.map = self
	_entity_root.add_child(p)
	p.apply_record(record)
	p.global_position = spawn_point(record.spawn_portal)
	entities[eid] = p
	emit(SimEvent.make(Protocol.EventType.ENTITY_SPAWNED, sim.tick, [eid, Const.EntityKind.PLAYER]))
	return p


func spawn_mob(mob_def: MobDef, at: Vector2) -> MobEntity:
	var mob: MobEntity = preload("res://sim/entities/mob_entity.tscn").instantiate()
	mob.eid = sim.ids.next()
	mob.map = self
	_entity_root.add_child(mob)
	mob.apply_def(mob_def, DataRegistry.mob_index(mob_def.id))
	mob.global_position = at
	entities[mob.eid] = mob
	emit(SimEvent.make(Protocol.EventType.ENTITY_SPAWNED, sim.tick, [mob.eid, Const.EntityKind.MOB, String(mob_def.id)]))
	return mob


func remove_entity(eid: int) -> void:
	var e: Entity = entities.get(eid)
	if e:
		entities.erase(eid)
		e.queue_free()
		emit(SimEvent.make(Protocol.EventType.ENTITY_DESPAWNED, sim.tick, [eid]))


func handle_intent(player: PlayerEntity, intent: Intent) -> void:
	match intent.type:
		Protocol.IntentType.CAST:
			player.try_cast(intent)
		Protocol.IntentType.RESPAWN:
			player.try_respawn(intent)
		_:
			reject(player, intent, Protocol.Reject.INVALID)


func reject(player: PlayerEntity, intent: Intent, reason: int) -> void:
	emit(SimEvent.make(
		Protocol.EventType.INTENT_REJECTED,
		sim.tick,
		[intent.client_seq, reason],
		Protocol.Scope.PLAYER,
		player.eid
	))


func emit(event: SimEvent) -> void:
	sim.emit_event(map_id, event)


func space_state() -> PhysicsDirectSpaceState2D:
	return world_2d.direct_space_state


func spawn_point(portal_id: StringName) -> Vector2:
	if _map_root == null:
		return Vector2(80, 280)
	for marker: Node in _map_root.find_children("*", "Marker2D", true, false):
		if marker.is_in_group(Const.GROUP_PORTALS) and StringName(marker.name) == portal_id:
			return (marker as Marker2D).global_position
	for marker: Node in _map_root.find_children("*", "Marker2D", true, false):
		if marker.is_in_group(Const.GROUP_PORTALS):
			return (marker as Marker2D).global_position
	return Vector2(80, 280)


func markers_in_group(group: StringName) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if _map_root == null:
		return out
	var g: String = String(group)
	for marker: Node in _map_root.find_children("*", "Marker2D", true, false):
		var in_group: bool = marker.is_in_group(group) or marker.is_in_group(g)
		if not in_group:
			for existing: StringName in marker.get_groups():
				if existing == group or String(existing) == g:
					in_group = true
					break
		if in_group or String(marker.name).begins_with(g):
			out.append((marker as Marker2D).global_position)
	return out


func build_snapshot(for_player: PlayerEntity) -> PackedByteArray:
	var states: Array[EntityState] = []
	for e: Entity in entities.values():
		if e != for_player:
			states.append(e.to_entity_state())
	var motor: MotorState = for_player.motor.capture() if for_player.motor else MotorState.new()
	return Codec.encode_snapshot(sim.tick, for_player.input_queue.last_processed_seq, motor, states)


func _build_spawners() -> void:
	_spawners.clear()
	for entry: Dictionary in def.spawns:
		var s := Spawner.new()
		s.setup(self, entry)
		_spawners.append(s)
