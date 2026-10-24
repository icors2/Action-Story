class_name DebugConsole
extends CanvasLayer
## LOCAL debug line. Enter to type; `/advance vanguard` job-changes with reqs skipped.

var authority: Authority
var _line: LineEdit
var _open: bool = false


func _ready() -> void:
	layer = 110
	_line = LineEdit.new()
	_line.placeholder_text = "/advance vanguard"
	_line.visible = false
	_line.position = Vector2(8, 330)
	_line.size = Vector2(400, 22)
	_line.text_submitted.connect(_on_submit)
	add_child(_line)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"toggle_chat"):
		return
	_toggle()
	get_viewport().set_input_as_handled()


func _toggle() -> void:
	_open = not _open
	_line.visible = _open
	GameState.chat_open = _open
	if _open:
		_line.grab_focus()
	else:
		_line.release_focus()
		_line.text = ""


func _on_submit(text: String) -> void:
	var msg: String = text.strip_edges()
	if msg != "" and authority:
		authority.submit_intent(Intent.chat(msg))
	_line.text = ""
	if _open:
		_toggle()
