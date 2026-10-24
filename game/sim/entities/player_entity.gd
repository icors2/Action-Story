class_name PlayerEntity
extends Entity
## Authoritative player body. Movement is MovementMotor + InputQueue.

var owner_peer: int = 0
var input_queue: InputQueue = InputQueue.new()
var motor: MovementMotor
var display_name: String = "Adventurer"


func _ready() -> void:
	kind = Const.EntityKind.PLAYER
	collision_layer = Const.bit(Const.Layer.PLAYER_BODY)
	collision_mask = Const.mask([Const.Layer.WORLD, Const.Layer.PLATFORM_ONEWAY] as Array[int])
	floor_max_angle = deg_to_rad(1.0)
	floor_snap_length = 4.0
	safe_margin = 0.08
	super._ready()
	motor = get_component(&"MovementMotor") as MovementMotor
	if motor == null:
		motor = MovementMotor.new()
		motor.name = "MovementMotor"
		add_child(motor)
		motor.entity = self
		motor.on_attached()


func apply_record(record: CharacterRecord) -> void:
	display_name = record.name


func to_record() -> CharacterRecord:
	var r: CharacterRecord = CharacterRecord.new_default(display_name)
	if map:
		r.map_id = map.map_id
	return r


func step_movement(tick: int) -> void:
	var frame: InputFrame = input_queue.pop_for_tick(tick)
	if motor:
		motor.step(frame, NetConfig.TICK_DT)


func step_actions(_tick: int) -> void:
	pass


func try_cast(_intent: Intent) -> void:
	pass
