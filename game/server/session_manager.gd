class_name SessionManager
extends Node
## peer_id <-> session. Handshake and routing land in Phase 9–11.

var world: WorldSim


func setup(p_world: WorldSim) -> void:
	world = p_world


func route_event(_map_id: StringName, _event: SimEvent) -> void:
	pass


func send_snapshots() -> void:
	pass


func autosave_dirty() -> void:
	pass


func save_all_and_kick(_reason: int) -> void:
	await get_tree().process_frame
