class_name MotorState
extends RefCounted
## Everything needed to reproduce MovementMotor exactly (for reconciliation).

var position: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var state: int = 0
var facing: int = 1
var coyote: int = 0
var jump_buffer: int = 0
var drop_through: int = 0
var climb_x: float = 0.0
var knockback: int = 0
var collision_mask: int = 0
var regrab: int = 0


func encode(buf: StreamPeerBuffer) -> void:
	buf.put_float(position.x)
	buf.put_float(position.y)
	buf.put_float(velocity.x)
	buf.put_float(velocity.y)
	buf.put_u8(state)
	buf.put_8(facing)
	buf.put_u8(coyote)
	buf.put_u8(jump_buffer)
	buf.put_u8(drop_through)
	buf.put_u8(knockback)
	buf.put_float(climb_x)
	buf.put_u32(collision_mask)
	buf.put_u8(regrab)


static func decode(buf: StreamPeerBuffer) -> MotorState:
	var s := MotorState.new()
	s.position = Vector2(buf.get_float(), buf.get_float())
	s.velocity = Vector2(buf.get_float(), buf.get_float())
	s.state = buf.get_u8()
	s.facing = buf.get_8()
	s.coyote = buf.get_u8()
	s.jump_buffer = buf.get_u8()
	s.drop_through = buf.get_u8()
	s.knockback = buf.get_u8()
	s.climb_x = buf.get_float()
	s.collision_mask = buf.get_u32()
	s.regrab = buf.get_u8()
	return s
