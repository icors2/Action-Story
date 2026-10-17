class_name EntityState
extends RefCounted
## Quantized nearby-entity state inside a snapshot (~13 bytes).

var eid: int = 0
var kind: int = 0
var def_index: int = 0
var x: int = 0
var y: int = 0
var anim: int = 0
var flags: int = 0
var hp_pct: int = 255


func encode(buf: StreamPeerBuffer) -> void:
	buf.put_u32(eid)
	buf.put_u8(kind)
	buf.put_u16(def_index)
	buf.put_16(x)
	buf.put_16(y)
	buf.put_u8(anim)
	buf.put_u8(flags)
	buf.put_u8(hp_pct)


static func decode(buf: StreamPeerBuffer) -> EntityState:
	var s := EntityState.new()
	s.eid = buf.get_u32()
	s.kind = buf.get_u8()
	s.def_index = buf.get_u16()
	s.x = buf.get_16()
	s.y = buf.get_16()
	s.anim = buf.get_u8()
	s.flags = buf.get_u8()
	s.hp_pct = buf.get_u8()
	return s
