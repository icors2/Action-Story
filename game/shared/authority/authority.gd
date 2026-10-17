class_name Authority
extends Node
## Abstract gateway between presentation and the authoritative simulation.

signal entered_map(map_id: StringName, self_eid: int, record: Dictionary)
signal snapshot_received(snapshot: Snapshot)
signal event_received(event: SimEvent)
signal disconnected(reason: int)

var self_eid: int = 0
var _next_intent_seq: int = 1


func start(_params: Dictionary) -> void:
	push_error("Authority.start() not implemented")


func stop() -> void:
	pass


func submit_input(_frame: InputFrame) -> void:
	push_error("Authority.submit_input() not implemented")


func submit_intent(intent: Intent) -> int:
	intent.client_seq = _next_intent_seq
	_next_intent_seq += 1
	_send_intent(intent)
	return intent.client_seq


func _send_intent(_intent: Intent) -> void:
	push_error("Authority._send_intent() not implemented")
