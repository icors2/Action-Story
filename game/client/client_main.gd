extends Node
## LOCAL client: visual map, predicted body, views, camera, input, combat FX.

var _authority: LocalAuthority
var _map_view: Node2D
var _predicted: PlayerEntity
var _predictor: Predictor
var _world_view: WorldView
var _respawn: RespawnPrompt
var _bounds: Rect2 = Rect2(0, 0, 1280, 720)


func _ready() -> void:
	Keybinds.register()
	_authority = LocalAuthority.new()
	_authority.name = "LocalAuthority"
	_authority.process_physics_priority = 0
	_authority.entered_map.connect(_on_entered_map)
	_authority.snapshot_received.connect(_on_snapshot)
	_authority.event_received.connect(_on_event)
	add_child(_authority)
	_authority.start({})


func _on_entered_map(map_id: StringName, self_eid: int, _record: Dictionary) -> void:
	Log.info("client", "entered_map %s eid=%s" % [String(map_id), self_eid])
	GameState.self_eid = self_eid
	GameState.apply_vitals(50, 50, 5, 5)
	var def: MapDef = DataRegistry.map_def(map_id)
	if def == null:
		Log.error("client", "unknown map %s" % map_id)
		return
	_bounds = def.bounds
	_map_view = (load(def.scene_path) as PackedScene).instantiate()
	_map_view.name = "MapView"
	add_child(_map_view)
	_predicted = preload("res://sim/entities/player_entity.tscn").instantiate()
	_predicted.name = "PredictedPlayer"
	_predicted.eid = self_eid
	_map_view.add_child(_predicted)
	_predicted.global_position = _spawn_point()
	_predictor = Predictor.new(_predicted.motor)
	var view := PlayerView.new()
	view.name = "PlayerView"
	view.target = _predicted
	add_child(view)
	_world_view = WorldView.new()
	_world_view.name = "WorldView"
	_world_view.player_view = view
	add_child(_world_view)
	var cam := FollowCamera.new()
	cam.name = "FollowCamera"
	cam.target = view
	cam.setup(_bounds)
	add_child(cam)
	var sampler := InputSampler.new()
	sampler.name = "InputSampler"
	sampler.authority = _authority
	sampler.predictor = _predictor
	sampler.predicted = _predicted
	sampler.player_view = view
	add_child(sampler)
	var overlay := DebugOverlay.new()
	overlay.name = "DebugOverlay"
	overlay.authority = _authority
	overlay.predictor = _predictor
	overlay.predicted = _predicted
	add_child(overlay)
	_respawn = RespawnPrompt.new()
	_respawn.name = "RespawnPrompt"
	_respawn.authority = _authority
	add_child(_respawn)


func _on_snapshot(snap: Snapshot) -> void:
	if _predictor and snap and snap.self_state:
		_predictor.reconcile(snap.last_processed_seq, snap.self_state)
	if _world_view and snap:
		_world_view.apply_snapshot(snap)


func _on_event(event: SimEvent) -> void:
	if _world_view:
		_world_view.apply_event(event)
	match event.type:
		Protocol.EventType.VITALS_CHANGED:
			if event.data.size() >= 5 and int(event.data[0]) == GameState.self_eid:
				GameState.apply_vitals(int(event.data[1]), int(event.data[2]), int(event.data[3]), int(event.data[4]))
				if not GameState.dead and _respawn:
					_respawn.hide_prompt()
		Protocol.EventType.DAMAGE:
			if event.data.size() >= 3 and int(event.data[1]) == GameState.self_eid:
				GameState.hp = maxi(0, GameState.hp - int(event.data[2]))
				GameState.dead = GameState.hp <= 0
				GameState.mark_hit()
		Protocol.EventType.DIED:
			if event.data.size() > 0 and int(event.data[0]) == GameState.self_eid:
				GameState.dead = true
				GameState.hp = 0
				if _respawn:
					_respawn.show_prompt()


func _spawn_point() -> Vector2:
	if _map_view == null:
		return Vector2(96, 656)
	for marker: Node in _map_view.find_children("*", "Marker2D", true, false):
		if marker.is_in_group(Const.GROUP_PORTALS) and marker.name == "spawn":
			return (marker as Marker2D).global_position
	for marker: Node in _map_view.find_children("*", "Marker2D", true, false):
		if marker.is_in_group(Const.GROUP_PORTALS):
			return (marker as Marker2D).global_position
	return Vector2(96, 656)
