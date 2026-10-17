extends Node
## Screen transitions (login → char select → world). No-op on the dedicated server.


func _ready() -> void:
	if Config.is_server():
		return
