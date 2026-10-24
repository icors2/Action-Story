class_name MapDef
extends BaseDef

var display_name: String = ""
var scene_path: String = ""
var return_map: StringName = &""
var flags: Dictionary = {}
var bounds: Rect2 = Rect2(0, 0, 640, 360)
var spawns: Array[Dictionary] = []


static func from_dict(d: Dictionary) -> MapDef:
	var m := MapDef.new()
	m.id = StringName(d["id"])
	m.display_name = String(d.get("name", d["id"]))
	m.scene_path = String(d["scene"])
	m.return_map = StringName(d.get("return_map", d["id"]))
	m.flags = d.get("flags", {})
	var b: Array = d.get("bounds", [0, 0, 640, 360])
	if b.size() >= 4:
		m.bounds = Rect2(float(b[0]), float(b[1]), float(b[2]) - float(b[0]), float(b[3]) - float(b[1]))
	m.spawns = []
	for entry: Variant in d.get("spawns", []):
		if entry is Dictionary:
			m.spawns.append(entry)
	return m
