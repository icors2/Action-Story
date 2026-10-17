class_name RemoteAuthority
extends Authority
## Online play (Phase 9): forwards inputs/intents over Net.

var _input_history: Array[InputFrame] = []


func start(params: Dictionary) -> void:
	Net.welcome_received.connect(_on_welcome)
	Net.snapshot_received.connect(func(s: Snapshot) -> void: snapshot_received.emit(s))
	Net.event_received.connect(func(e: SimEvent) -> void: event_received.emit(e))
	Net.disconnected.connect(func(r: int) -> void: disconnected.emit(r))
	Net.connected.connect(func() -> void: Net.c2s_hello.rpc_id(1, Protocol.VERSION, String(params.get("ticket", ""))), CONNECT_ONE_SHOT)
	var err: Error = Net.join(String(params.get("host", "127.0.0.1")), int(params.get("port", 7777)))
	if err != OK:
		disconnected.emit(Protocol.Disconnect.NONE)


func stop() -> void:
	Net.close()


func submit_input(frame: InputFrame) -> void:
	_input_history.append(frame)
	if _input_history.size() > NetConfig.INPUT_REDUNDANCY:
		_input_history.pop_front()
	Net.c2s_inputs.rpc_id(1, Codec.encode_inputs(_input_history))


func _send_intent(intent: Intent) -> void:
	Net.c2s_intent.rpc_id(1, intent.to_wire())


func _on_welcome(eid: int, map_id: StringName, _server_tick: int) -> void:
	self_eid = eid
	entered_map.emit(map_id, eid, {})
