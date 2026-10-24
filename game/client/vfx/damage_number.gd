class_name DamageNumber
extends Node2D
## Pooled floating damage text. Crits are larger and gold.

var _label: Label
var _life: float = 0.0
var _rise: float = 0.0


func _ready() -> void:
	_label = Label.new()
	_label.add_theme_font_size_override(&"font_size", 12)
	_label.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.8))
	_label.add_theme_constant_override(&"outline_size", 3)
	add_child(_label)
	visible = false
	set_process(false)


func play(amount: int, crit: bool, stack: int) -> void:
	_label.text = str(amount)
	_label.add_theme_font_size_override(&"font_size", 16 if crit else 12)
	_label.add_theme_color_override(&"font_color", Color(1.0, 0.85, 0.2) if crit else Color(1, 1, 1))
	_life = 0.7
	_rise = 0.0
	position.y -= float(stack) * 12.0
	visible = true
	set_process(true)


func _process(delta: float) -> void:
	_life -= delta
	_rise += 28.0 * delta
	position.y -= 28.0 * delta
	modulate.a = clampf(_life / 0.25, 0.0, 1.0)
	if _life <= 0.0:
		visible = false
		set_process(false)
		queue_free()
