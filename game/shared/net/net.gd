extends Node
## Transport + RPC endpoints. Same script on client and server (RPC checksums must match).
## Gameplay never calls multiplayer directly; it goes through Authority/SessionManager.

signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)
signal hello_received(peer_id: int, protocol_version: int, ticket: String)
signal inputs_received(peer_id: int, frames: Array[InputFrame])
signal intent_received(peer_id: int, intent: Intent)
signal welcome_received(self_eid: int, map_id: StringName, server_tick: int)
signal snapshot_received(snapshot: Snapshot)
signal event_received(event: SimEvent)
signal connected()
signal connection_failed()
signal disconnected(reason: int)

var _peer: ENetMultiplayerPeer


func host(port: int, max_clients: int) -> Error:
	_peer = ENetMultiplayerPeer.new()
	var err: Error = _peer.create_server(port, max_clients)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = _peer
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	Log.info("net", "ENet server listening on UDP %d" % port)
	return OK


func join(address: String, port: int) -> Error:
	_peer = ENetMultiplayerPeer.new()
	var err: Error = _peer.create_client(address, port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = _peer
	multiplayer.connected_to_server.connect(func() -> void: connected.emit(), CONNECT_ONE_SHOT)
	multiplayer.connection_failed.connect(func() -> void: connection_failed.emit(), CONNECT_ONE_SHOT)
	multiplayer.server_disconnected.connect(func() -> void: disconnected.emit(Protocol.Disconnect.NONE), CONNECT_ONE_SHOT)
	return OK


func close() -> void:
	if _peer:
		_peer.close()
	multiplayer.multiplayer_peer = null


func kick(peer_id: int, reason: int) -> void:
	s2c_disconnect_reason.rpc_id(peer_id, reason)
	_peer.disconnect_peer(peer_id)


func _on_peer_connected(id: int) -> void:
	peer_joined.emit(id)


func _on_peer_disconnected(id: int) -> void:
	peer_left.emit(id)


@rpc("any_peer", "call_remote", "reliable", 0)
func c2s_hello(protocol_version: int, ticket: String) -> void:
	if not multiplayer.is_server():
		return
	hello_received.emit(multiplayer.get_remote_sender_id(), protocol_version, ticket.left(1024))


@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func c2s_inputs(bytes: PackedByteArray) -> void:
	if not multiplayer.is_server():
		return
	inputs_received.emit(multiplayer.get_remote_sender_id(), Codec.decode_inputs(bytes))


@rpc("any_peer", "call_remote", "reliable", 0)
func c2s_intent(wire: Array) -> void:
	if not multiplayer.is_server():
		return
	var intent: Intent = Intent.from_wire(wire)
	if intent != null:
		intent_received.emit(multiplayer.get_remote_sender_id(), intent)


@rpc("authority", "call_remote", "reliable", 0)
func s2c_welcome(self_eid: int, map_id: String, server_tick: int) -> void:
	welcome_received.emit(self_eid, StringName(map_id), server_tick)


@rpc("authority", "call_remote", "unreliable_ordered", 2)
func s2c_snapshot(bytes: PackedByteArray) -> void:
	snapshot_received.emit(Codec.decode_snapshot(bytes))


@rpc("authority", "call_remote", "reliable", 0)
func s2c_event(wire: Array) -> void:
	event_received.emit(SimEvent.from_wire(wire))


@rpc("authority", "call_remote", "reliable", 0)
func s2c_disconnect_reason(reason: int) -> void:
	disconnected.emit(reason)


func send_snapshot(peer_id: int, bytes: PackedByteArray) -> void:
	s2c_snapshot.rpc_id(peer_id, bytes)


func send_event(peer_id: int, event: SimEvent) -> void:
	s2c_event.rpc_id(peer_id, event.to_wire())
