extends GutTest


func test_seventy_entities_about_one_kib() -> void:
	var ents: Array[EntityState] = []
	for i: int in 70:
		var e := EntityState.new()
		e.eid = i + 1
		e.kind = int(Const.EntityKind.MOB)
		e.def_index = 0
		e.x = i * 3
		e.y = 20
		e.anim = 1
		e.flags = 0
		e.hp_pct = 200
		ents.append(e)
	var bytes: PackedByteArray = Codec.encode_snapshot(1, 0, MotorState.new(), ents)
	var again: Snapshot = Codec.decode_snapshot(bytes)
	assert_eq(again.entities.size(), 70)
	assert_eq(again.entities[69].eid, 70)
	assert_lt(bytes.size(), 1100)


func test_entity_state_roundtrip_anim_facing_hp() -> void:
	var e := EntityState.new()
	e.eid = 4
	e.kind = int(Const.EntityKind.MOB)
	e.def_index = 1
	e.x = -12
	e.y = 40
	e.anim = Const.Anim.HURT
	e.flags = Const.FLAG_FACE_LEFT
	e.hp_pct = 64
	var ents: Array[EntityState] = [e]
	var snap: Snapshot = Codec.decode_snapshot(Codec.encode_snapshot(3, 1, MotorState.new(), ents))
	assert_eq(snap.entities[0].anim, Const.Anim.HURT)
	assert_eq(snap.entities[0].flags, Const.FLAG_FACE_LEFT)
	assert_eq(snap.entities[0].hp_pct, 64)
	assert_eq(snap.entities[0].def_index, 1)
