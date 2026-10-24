extends SceneTree
## Headless: build content/tilesets/placeholder.tres from placeholder.png.


func _init() -> void:
	var tex: Texture2D = load("res://content/tilesets/placeholder.png")
	if tex == null:
		push_error("placeholder.png missing; run tools/gen_placeholder_png.py first")
		quit(1)
		return
	var ts := TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 0)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(1, 2)
	ts.set_physics_layer_collision_mask(1, 0)
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(16, 16)
	src.create_tile(Vector2i(0, 0))
	src.create_tile(Vector2i(1, 0))
	ts.add_source(src, 0)
	var box: PackedVector2Array = PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)
	])
	var solid: TileData = src.get_tile_data(Vector2i(0, 0), 0)
	solid.add_collision_polygon(0)
	solid.set_collision_polygon_points(0, 0, box)
	var oneway: TileData = src.get_tile_data(Vector2i(1, 0), 0)
	oneway.add_collision_polygon(1)
	oneway.set_collision_polygon_points(1, 0, box)
	oneway.set_collision_polygon_one_way(1, 0, true)
	var err: Error = ResourceSaver.save(ts, "res://content/tilesets/placeholder.tres")
	if err != OK:
		push_error("Failed to save tileset: %s" % error_string(err))
		quit(1)
		return
	print("wrote res://content/tilesets/placeholder.tres")
	quit(0)
