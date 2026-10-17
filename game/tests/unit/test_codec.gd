extends GutTest


func test_input_frame_roundtrip() -> void:
	var f := InputFrame.new()
	f.seq = 42
	f.move_x = -1
	f.move_y = 1
	f.buttons = InputFrame.BTN_JUMP_PRESSED
	var frames: Array[InputFrame] = [f]
	var decoded: Array[InputFrame] = Codec.decode_inputs(Codec.encode_inputs(frames))
	assert_eq(decoded.size(), 1)
	assert_eq(decoded[0].seq, 42)
	assert_eq(decoded[0].move_x, -1)
	assert_eq(decoded[0].move_y, 1)
	assert_true(decoded[0].pressed(InputFrame.BTN_JUMP_PRESSED))


func test_intent_roundtrip() -> void:
	var i: Intent = Intent.cast(&"novice_strike", 1)
	i.client_seq = 7
	var again: Intent = Intent.from_wire(i.to_wire())
	assert_not_null(again)
	assert_eq(again.type, Protocol.IntentType.CAST)
	assert_eq(again.client_seq, 7)
	assert_eq(again.args[0], "novice_strike")


func test_sim_event_roundtrip() -> void:
	var e: SimEvent = SimEvent.make(Protocol.EventType.DAMAGE, 12, [1, 2, 9, false, 0])
	var again: SimEvent = SimEvent.from_wire(e.to_wire())
	assert_eq(again.type, Protocol.EventType.DAMAGE)
	assert_eq(again.tick, 12)
	assert_eq(again.data[2], 9)


func test_motor_state_roundtrip() -> void:
	var s := MotorState.new()
	s.position = Vector2(10.5, -3.25)
	s.velocity = Vector2(1, 2)
	s.state = 1
	s.facing = -1
	s.coyote = 3
	var buf := StreamPeerBuffer.new()
	s.encode(buf)
	buf.seek(0)
	var d: MotorState = MotorState.decode(buf)
	assert_almost_eq(d.position.x, 10.5, 0.0001)
	assert_eq(d.facing, -1)
	assert_eq(d.coyote, 3)


func test_snapshot_roundtrip() -> void:
	var self_state := MotorState.new()
	self_state.position = Vector2(8, 16)
	var ent := EntityState.new()
	ent.eid = 9
	ent.kind = Const.EntityKind.MOB
	ent.x = 20
	ent.y = -4
	var ents: Array[EntityState] = [ent]
	var snap: Snapshot = Codec.decode_snapshot(Codec.encode_snapshot(100, 5, self_state, ents))
	assert_eq(snap.tick, 100)
	assert_eq(snap.last_processed_seq, 5)
	assert_eq(snap.entities.size(), 1)
	assert_eq(snap.entities[0].eid, 9)
