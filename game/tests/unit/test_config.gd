extends GutTest


func _cfg() -> Node:
	return autofree(load("res://shared/autoload/config.gd").new())


func test_parse_server() -> void:
	var c: Node = _cfg()
	c._parse_args(PackedStringArray(["--server"]))
	assert_eq(c.mode, c.Mode.SERVER)


func test_parse_port() -> void:
	var c: Node = _cfg()
	c._parse_args(PackedStringArray(["--port=7799"]))
	assert_eq(c.server_port, 7799)


func test_parse_connect() -> void:
	var c: Node = _cfg()
	c._parse_args(PackedStringArray(["--connect=10.0.0.2:8888"]))
	assert_eq(c.mode, c.Mode.CLIENT)
	assert_eq(c.connect_host, "10.0.0.2")
	assert_eq(c.connect_port, 8888)


func test_parse_seed() -> void:
	var c: Node = _cfg()
	c._parse_args(PackedStringArray(["--seed=42"]))
	assert_eq(c.rng_seed, 42)
