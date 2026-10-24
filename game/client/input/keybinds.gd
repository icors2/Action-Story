class_name Keybinds
## Registers default InputMap actions (§15.3). Remappable later.


static func register() -> void:
	_axis(&"move_left", [KEY_LEFT, KEY_A])
	_axis(&"move_right", [KEY_RIGHT, KEY_D])
	_axis(&"move_up", [KEY_UP, KEY_W])
	_axis(&"move_down", [KEY_DOWN, KEY_S])
	_axis(&"jump", [KEY_SPACE, KEY_ALT])
	_axis(&"attack", [KEY_J, KEY_X])
	_clear_key(&"attack", KEY_CTRL)
	_mouse(&"attack", MOUSE_BUTTON_LEFT)
	_axis(&"respawn", [KEY_R])
	_axis(&"pickup", [KEY_Z])
	_axis(&"interact", [KEY_F])
	_axis(&"toggle_inventory", [KEY_I])
	_axis(&"toggle_equipment", [KEY_U])
	_axis(&"toggle_stats", [KEY_T])
	_axis(&"toggle_skills", [KEY_K])
	_axis(&"toggle_quests", [KEY_L])
	_axis(&"toggle_chat", [KEY_ENTER])
	_axis(&"toggle_minimap", [KEY_M])
	_axis(&"debug_overlay", [KEY_F3])
	_axis(&"skill_1", [KEY_Q])
	_axis(&"skill_2", [KEY_E])
	_axis(&"alloc_str", [KEY_F5])
	_axis(&"alloc_dex", [KEY_F6])
	_axis(&"alloc_int", [KEY_F7])
	_axis(&"alloc_luk", [KEY_F8])
	_axis(&"alloc_sp", [KEY_F9])
	_axis(&"menu", [KEY_ESCAPE])
	_joy(&"move_left", JOY_BUTTON_DPAD_LEFT)
	_joy(&"move_right", JOY_BUTTON_DPAD_RIGHT)
	_joy(&"move_up", JOY_BUTTON_DPAD_UP)
	_joy(&"move_down", JOY_BUTTON_DPAD_DOWN)
	_joy(&"jump", JOY_BUTTON_A)
	_joy(&"attack", JOY_BUTTON_X)
	_joy(&"pickup", JOY_BUTTON_Y)
	_joy(&"interact", JOY_BUTTON_B)
	_joy(&"menu", JOY_BUTTON_START)


static func _axis(action: StringName, keys: Array[int]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k: int in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k as Key
		if not InputMap.action_has_event(action, ev):
			InputMap.action_add_event(action, ev)


static func _clear_key(action: StringName, key: Key) -> void:
	if not InputMap.has_action(action):
		return
	for ev: InputEvent in InputMap.action_get_events(action):
		var k: InputEventKey = ev as InputEventKey
		if k and k.physical_keycode == key:
			InputMap.action_erase_event(action, ev)


static func _mouse(action: StringName, button: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	if not InputMap.action_has_event(action, ev):
		InputMap.action_add_event(action, ev)


static func _joy(action: StringName, button: JoyButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	if not InputMap.action_has_event(action, ev):
		InputMap.action_add_event(action, ev)
