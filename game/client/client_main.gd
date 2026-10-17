extends Node
## LOCAL / client world root. Phase 0: LocalAuthority + visual copy of the test map.

var _authority: LocalAuthority


func _ready() -> void:
	var view: Node = load("res://content/maps/map_test_flat.tscn").instantiate()
	view.name = "MapView"
	add_child(view)
	_authority = LocalAuthority.new()
	_authority.name = "LocalAuthority"
	_authority.entered_map.connect(_on_entered_map)
	add_child(_authority)
	_authority.start({})


func _on_entered_map(map_id: StringName, self_eid: int, _record: Dictionary) -> void:
	Log.info("client", "entered_map %s eid=%s" % [String(map_id), self_eid])
