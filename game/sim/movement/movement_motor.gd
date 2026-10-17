class_name MovementMotor
extends Component
## Phase 0 stub: capture/restore only. Phase 1 fills platformer step().

enum State { GROUND, AIR, CLIMB }

var state: State = State.AIR
var facing: int = 1


func capture() -> MotorState:
	var s := MotorState.new()
	s.state = int(state)
	s.facing = facing
	if entity:
		s.position = entity.global_position
		s.velocity = entity.velocity
	return s


func restore(s: MotorState) -> void:
	state = s.state as State
	facing = s.facing
	if entity:
		entity.global_position = s.position
		entity.velocity = s.velocity


func step(_frame: InputFrame, _dt: float) -> void:
	pass
