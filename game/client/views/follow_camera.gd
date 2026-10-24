class_name FollowCamera
extends Camera2D
## Basic follow camera. Limits come from the map JSON bounds.

var target: Node2D


func setup(bounds: Rect2) -> void:
	enabled = true
	position_smoothing_enabled = true
	position_smoothing_speed = 8.0
	limit_left = int(bounds.position.x)
	limit_top = int(bounds.position.y)
	limit_right = int(bounds.end.x)
	limit_bottom = int(bounds.end.y)
	limit_smoothed = true


func _process(_delta: float) -> void:
	if target:
		global_position = target.global_position
