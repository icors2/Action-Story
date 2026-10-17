class_name Codec
## Compact binary encoding for snapshots and input batches.

static func encode_inputs(frames: Array[InputFrame]) -> PackedByteArray:
	var buf := StreamPeerBuffer.new()
	buf.put_u8(frames.size())
	for f: InputFrame in frames:
		f.encode(buf)
	return buf.data_array


static func decode_inputs(bytes: PackedByteArray) -> Array[InputFrame]:
	var out: Array[InputFrame] = []
	if bytes.size() < 1 or bytes.size() > 64:
		return out
	var buf := StreamPeerBuffer.new()
	buf.data_array = bytes
	var n: int = mini(buf.get_u8(), NetConfig.INPUT_REDUNDANCY)
	if bytes.size() < 1 + n * 6:
		return out
	for _i: int in n:
		out.append(InputFrame.decode(buf))
	return out


static func encode_snapshot(tick: int, last_seq: int, self_state: MotorState, entities: Array[EntityState]) -> PackedByteArray:
	var buf := StreamPeerBuffer.new()
	buf.put_u32(tick)
	buf.put_u32(last_seq)
	self_state.encode(buf)
	buf.put_u16(entities.size())
	for e: EntityState in entities:
		e.encode(buf)
	return buf.data_array


static func decode_snapshot(bytes: PackedByteArray) -> Snapshot:
	var buf := StreamPeerBuffer.new()
	buf.data_array = bytes
	var s := Snapshot.new()
	s.tick = buf.get_u32()
	s.last_processed_seq = buf.get_u32()
	s.self_state = MotorState.decode(buf)
	var n: int = buf.get_u16()
	for _i: int in n:
		s.entities.append(EntityState.decode(buf))
	return s
