class_name InputFrame
extends RefCounted
## One tick of player input. 6 bytes on the wire.

const BTN_JUMP_HELD: int = 1 << 0
const BTN_JUMP_PRESSED: int = 1 << 1

var seq: int = 0
var move_x: int = 0
var move_y: int = 0
var buttons: int = 0


func pressed(btn: int) -> bool:
	return (buttons & btn) != 0


func encode(buf: StreamPeerBuffer) -> void:
	buf.put_u32(seq)
	buf.put_u8((move_x + 1) | ((move_y + 1) << 2))
	buf.put_u8(buttons)


static func decode(buf: StreamPeerBuffer) -> InputFrame:
	var f := InputFrame.new()
	f.seq = buf.get_u32()
	var axes: int = buf.get_u8()
	f.move_x = clampi((axes & 0b11) - 1, -1, 1)
	f.move_y = clampi(((axes >> 2) & 0b11) - 1, -1, 1)
	f.buttons = buf.get_u8() & (BTN_JUMP_HELD | BTN_JUMP_PRESSED)
	return f


static func neutral(p_seq: int) -> InputFrame:
	var f := InputFrame.new()
	f.seq = p_seq
	return f
