class_name WorldSim
extends Node
## The authoritative world. Runs in LocalAuthority and on the dedicated server.
## Never references client/, Input, UI, audio, or Net.

signal event_emitted(map_id: StringName, event: SimEvent)

const MAP_INSTANCE_SCENE: PackedScene = preload("res://sim/world/map_instance.tscn")

var tick: int = 0
var rng := RandomNumberGenerator.new()
var ids := IdAllocator.new()

var _maps: Dictionary = {}
var _player_map: Dictionary = {}
var _players: Dictionary = {}


func seed_rng(seed_value: int) -> void:
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value


func step() -> void:
	tick += 1
	for m: MapInstance in _maps.values():
		m.step(tick)


func spawn_player(record: CharacterRecord, owner_peer: int) -> int:
	var eid: int = ids.next()
	var map: MapInstance = get_or_create_map(record.map_id)
	var player: PlayerEntity = map.spawn_player(record, owner_peer, eid)
	_players[player.eid] = player
	_player_map[player.eid] = map.map_id
	return player.eid


func despawn_player(eid: int) -> CharacterRecord:
	var record: CharacterRecord = export_record(eid)
	var map: MapInstance = _maps.get(_player_map.get(eid, &""))
	if map:
		map.remove_entity(eid)
	_players.erase(eid)
	_player_map.erase(eid)
	return record


func export_record(eid: int) -> CharacterRecord:
	var p: PlayerEntity = _players.get(eid)
	return p.to_record() if p else null


func queue_input(eid: int, frames: Array[InputFrame]) -> void:
	var p: PlayerEntity = _players.get(eid)
	if p:
		p.input_queue.push_frames(frames)


func handle_intent(eid: int, intent: Intent) -> void:
	var p: PlayerEntity = _players.get(eid)
	if p == null:
		return
	var map: MapInstance = _maps[_player_map[eid]]
	map.handle_intent(p, intent)


func map_of(eid: int) -> StringName:
	return _player_map.get(eid, &"")


func build_snapshot_for(eid: int) -> PackedByteArray:
	var p: PlayerEntity = _players[eid]
	return _maps[_player_map[eid]].build_snapshot(p)


func get_or_create_map(map_id: StringName) -> MapInstance:
	if _maps.has(map_id):
		return _maps[map_id]
	var def: MapDef = DataRegistry.map_def(map_id)
	if def == null:
		push_error("WorldSim: unknown map %s" % map_id)
		return null
	var inst: MapInstance = MAP_INSTANCE_SCENE.instantiate()
	inst.setup(self, def)
	add_child(inst)
	inst.start_spawners()
	_maps[map_id] = inst
	return inst


func emit_event(map_id: StringName, event: SimEvent) -> void:
	event_emitted.emit(map_id, event)


func transfer_player(_eid: int, _to_map: StringName, _to_portal: StringName) -> void:
	pass
