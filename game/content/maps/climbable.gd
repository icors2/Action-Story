class_name Climbable
extends Area2D
## Rope or ladder volume. ClimbQuery finds these; no body_entered signals.

@export_enum("rope", "ladder") var kind: String = "rope"


func _ready() -> void:
	collision_layer = Const.bit(Const.Layer.CLIMBABLE)
	collision_mask = 0
	monitoring = false
	monitorable = true
	_add_placeholder_art()


func _add_placeholder_art() -> void:
	var size: Vector2 = Vector2(10, 128)
	var cs: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs and cs.shape is RectangleShape2D:
		size = (cs.shape as RectangleShape2D).size
	if kind == "ladder":
		_draw_ladder(size)
	else:
		_draw_rope(size)


func _draw_rope(size: Vector2) -> void:
	var rope := ColorRect.new()
	rope.size = Vector2(5, size.y)
	rope.position = Vector2(-2.5, -size.y * 0.5)
	rope.color = Color(0.78, 0.46, 0.22)
	rope.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rope)


func _draw_ladder(size: Vector2) -> void:
	var width: float = 14.0
	var height: float = size.y
	var left := ColorRect.new()
	left.size = Vector2(3, height)
	left.position = Vector2(-width * 0.5, -height * 0.5)
	left.color = Color(0.9, 0.74, 0.28)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(left)
	var right := ColorRect.new()
	right.size = Vector2(3, height)
	right.position = Vector2(width * 0.5 - 3.0, -height * 0.5)
	right.color = Color(0.9, 0.74, 0.28)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(right)
	var y: float = -height * 0.5 + 8.0
	while y < height * 0.5 - 4.0:
		var rung := ColorRect.new()
		rung.size = Vector2(width, 3)
		rung.position = Vector2(-width * 0.5, y)
		rung.color = Color(0.95, 0.82, 0.36)
		rung.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rung)
		y += 16.0
