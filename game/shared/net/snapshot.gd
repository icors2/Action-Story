class_name Snapshot
extends RefCounted
## Decoded snapshot: tick, last processed input seq, self motor, nearby entities.

var tick: int = 0
var last_processed_seq: int = 0
var self_state: MotorState
var entities: Array[EntityState] = []
