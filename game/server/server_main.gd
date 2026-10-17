extends Node
## Dedicated server root. Owns WorldSim, SessionManager; drives the fixed tick.

@onready var world: WorldSim = $WorldSim
@onready var sessions: SessionManager = $SessionManager

var _shutting_down: bool = false


func _ready() -> void:
	Log.json_lines = true
	Engine.max_fps = NetConfig.TICK_RATE
	world.seed_rng(Config.rng_seed)
	sessions.setup(world)
	world.event_emitted.connect(sessions.route_event)
	var err: Error = Net.host(Config.server_port, Config.max_clients)
	if err != OK:
		Log.error("server", "Failed to host on %d: %s" % [Config.server_port, error_string(err)])
		get_tree().quit(1)
		return
	Log.info("server", "Channel %d ready" % Config.channel_id, {"port": Config.server_port, "protocol": Protocol.VERSION})


func _physics_process(_delta: float) -> void:
	if _shutting_down:
		return
	world.step()
	if world.tick % NetConfig.SNAPSHOT_EVERY_TICKS == 0:
		sessions.send_snapshots()
	if world.tick % (NetConfig.TICK_RATE * 60) == 0:
		sessions.autosave_dirty()
	if world.tick % (NetConfig.TICK_RATE * 5) == 0:
		_write_heartbeat()
		if FileAccess.file_exists(Config.data_dir.path_join("shutdown")):
			shutdown()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		shutdown()


func shutdown() -> void:
	if _shutting_down:
		return
	_shutting_down = true
	Log.info("server", "Shutting down: saving all sessions")
	await sessions.save_all_and_kick(Protocol.Disconnect.SERVER_SHUTDOWN)
	get_tree().quit(0)


func _write_heartbeat() -> void:
	if not DirAccess.dir_exists_absolute(Config.data_dir):
		return
	var f: FileAccess = FileAccess.open(Config.data_dir.path_join("heartbeat"), FileAccess.WRITE)
	if f:
		f.store_string(str(Time.get_unix_time_from_system()))
