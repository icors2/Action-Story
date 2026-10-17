extends Node
## Client-side presentation signals ONLY. The simulation must never use this.
## Naming: noun_verbed, past tense, typed args.

signal window_toggled(window_id: StringName, is_open: bool)
signal hotkey_pressed(slot: StringName)
signal chat_line_added(channel: int, sender: String, text: String)
signal system_message_posted(text: String)
signal tooltip_requested(item_id: StringName, screen_pos: Vector2)
signal tooltip_dismissed()
signal map_transition_started(map_id: StringName)
signal map_transition_finished(map_id: StringName)


func _ready() -> void:
	if Config.is_server():
		return
