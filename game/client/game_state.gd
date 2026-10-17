extends Node
## Client-side view model of the local player. Read-only mirror of authority data.


func _ready() -> void:
	if Config.is_server():
		return
