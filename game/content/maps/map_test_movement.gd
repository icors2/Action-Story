extends Node2D
## Paints placeholder tiles for the Phase 1 movement yard. Idempotent.

const TILE: int = 16
const WIDTH_TILES: int = 80
const HEIGHT_TILES: int = 45
const GROUND_Y: int = 42
const SRC: int = 0
const SOLID: Vector2i = Vector2i(0, 0)
const ONEWAY: Vector2i = Vector2i(1, 0)

@onready var ground: TileMapLayer = $Ground
@onready var platforms: TileMapLayer = $Platforms


func _ready() -> void:
	_paint_solids()
	_paint_platforms()


func _paint_solids() -> void:
	for x: int in range(WIDTH_TILES):
		ground.set_cell(Vector2i(x, GROUND_Y), SRC, SOLID)
		ground.set_cell(Vector2i(x, HEIGHT_TILES - 1), SRC, SOLID)
	for y: int in range(HEIGHT_TILES):
		ground.set_cell(Vector2i(0, y), SRC, SOLID)
		ground.set_cell(Vector2i(WIDTH_TILES - 1, y), SRC, SOLID)


func _paint_platforms() -> void:
	_row(8, 24, 34)
	_row(28, 46, 26)
	_row(10, 26, 18)
	_row(40, 58, 12)


func _row(x0: int, x1: int, y: int) -> void:
	for x: int in range(x0, x1):
		platforms.set_cell(Vector2i(x, y), SRC, ONEWAY)
