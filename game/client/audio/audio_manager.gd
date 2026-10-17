extends Node
## Music crossfade and SFX pooling. No-op on the dedicated server.


func _ready() -> void:
	if Config.is_server():
		return
