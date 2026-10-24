class_name Predictor
extends RefCounted
## Client-side prediction for the local player + reconciliation against snapshots.

var motor: MovementMotor
var pending: Array[InputFrame] = []
var correction_count: int = 0
var last_correction: float = 0.0


func _init(p_motor: MovementMotor) -> void:
	motor = p_motor


func apply_local(frame: InputFrame) -> void:
	motor.step(frame, NetConfig.TICK_DT)
	pending.append(frame)
	if pending.size() > NetConfig.MAX_PENDING_INPUTS:
		pending.pop_front()


func reconcile(last_processed_seq: int, server_state: MotorState) -> Vector2:
	var before: Vector2 = motor.entity.global_position
	while not pending.is_empty() and pending[0].seq <= last_processed_seq:
		pending.pop_front()
	motor.restore(server_state)
	for f: InputFrame in pending:
		motor.step(f, NetConfig.TICK_DT)
	var delta: Vector2 = motor.entity.global_position - before
	last_correction = delta.length()
	if last_correction > 1.0:
		correction_count += 1
	return delta
