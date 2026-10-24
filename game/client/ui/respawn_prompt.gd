class_name RespawnPrompt
extends CanvasLayer
## Shown after the local player dies. Sends RESPAWN through Authority.

var authority: Authority
var _panel: Control
var _shown: bool = false


func _ready() -> void:
	layer = 80
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.visible = false
	add_child(_panel)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.45)
	_panel.add_child(dim)
	var box := VBoxContainer.new()
	box.position = Vector2(220, 140)
	box.custom_minimum_size = Vector2(200, 80)
	_panel.add_child(box)
	var title := Label.new()
	title.text = "You fell..."
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var btn := Button.new()
	btn.text = "Respawn"
	btn.pressed.connect(_request)
	box.add_child(btn)


func show_prompt() -> void:
	_shown = true
	_panel.visible = true


func hide_prompt() -> void:
	_shown = false
	_panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not _shown:
		return
	if event.is_action_pressed(&"respawn") or event.is_action_pressed(&"attack"):
		_request()
		get_viewport().set_input_as_handled()


func _request() -> void:
	if authority == null or not GameState.dead:
		return
	authority.submit_intent(Intent.respawn())
