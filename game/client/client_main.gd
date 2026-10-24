extends Node
## LOCAL client: visual map, predicted body, view, camera, input.

var _authority: LocalAuthority
var _map_view: Node2D
var _predicted: PlayerEntity
var _predictor: Predictor
var _bounds: Rect2 = Rect2(0, 0, 1280, 720)


func _ready() -> void:
	Keybinds.register()
	_authority = LocalAuthority.new()
	_authority.name = "LocalAuthority"
	_authority.process_physics_priority = 0
	_authority.entered_map.connect(_on_entered_map)
	_authority.snapshot_received.connect(_on_snapshot)
	add_child(_authority)
	_authority.start({})


func _on_entered_map(map_id: StringName, self_eid: int, _record: Dictionary) -> void:
	Log.info("client", "entered_map %s eid=%s" % [String(map_id), self_eid])
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
	var cam := FollowCamera.new()
	cam.name = "FollowCamera"
	cam.target = view
	cam.setup(_bounds)
	add_child(cam)
	var sampler := InputSampler.new()
	sampler.name = "InputSampler"
	sampler.authority = _authority
	sampler.predictor = _predictor
	add_child(sampler)
	var overlay := DebugOverlay.new()
	overlay.name = "DebugOverlay"
	overlay.authority = _authority
	overlay.predictor = _predictor
	overlay.predicted = _predicted
	add_child(overlay)


func _on_snapshot(snap: Snapshot) -> void:
	if _predictor == null or snap == null or snap.self_state == null:
		return
	_predictor.reconcile(snap.last_processed_seq, snap.self_state)


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
