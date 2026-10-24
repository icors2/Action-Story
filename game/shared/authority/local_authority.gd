class_name LocalAuthority
extends Authority
## Single-player: hosts an in-process WorldSim and talks to it directly.

const LOCAL_PEER_ID: int = 1

var sim: WorldSim
var storage: CharacterStorage
var _last_seq: int = 0


func start(params: Dictionary) -> void:
	storage = params.get("storage", LocalFileStorage.new())
	sim = WorldSim.new()
	sim.name = "WorldSim"
	sim.seed_rng(Config.rng_seed)
	add_child(sim)
	sim.event_emitted.connect(_on_sim_event)
	var record: CharacterRecord = await storage.load_character(int(params.get("character_id", 1)))
	if record == null:
		record = CharacterRecord.new_default(String(params.get("name", "Adventurer")))
	self_eid = sim.spawn_player(record, LOCAL_PEER_ID)
	entered_map.emit(record.map_id, self_eid, record.to_dict())


func stop() -> void:
	if sim and self_eid != 0:
		await storage.save_character(sim.export_record(self_eid))


func submit_input(frame: InputFrame) -> void:
	_last_seq = frame.seq
	var frames: Array[InputFrame] = [frame]
	sim.queue_input(self_eid, frames)


func _send_intent(intent: Intent) -> void:
	if Config.local_codec_roundtrip:
		intent = Intent.from_wire(intent.to_wire())
	sim.handle_intent(self_eid, intent)


func _physics_process(_delta: float) -> void:
	if sim == null or self_eid == 0:
		return
	sim.step()
	if sim.tick % NetConfig.SNAPSHOT_EVERY_TICKS == 0:
		var bytes: PackedByteArray = sim.build_snapshot_for(self_eid)
		snapshot_received.emit(Codec.decode_snapshot(bytes))


func _on_sim_event(map_id: StringName, event: SimEvent) -> void:
	if map_id != sim.map_of(self_eid):
		return
	if event.scope == Protocol.Scope.PLAYER and event.target_eid != self_eid:
		return
	if Config.local_codec_roundtrip:
		event = SimEvent.from_wire(event.to_wire())
	event_received.emit(event)
