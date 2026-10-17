class_name MapDef
extends BaseDef

var display_name: String = ""
var scene_path: String = ""
var return_map: StringName = &""
var flags: Dictionary = {}


static func from_dict(d: Dictionary) -> MapDef:
	var m := MapDef.new()
	m.id = StringName(d["id"])
	m.display_name = String(d.get("name", d["id"]))
	m.scene_path = String(d["scene"])
	m.return_map = StringName(d.get("return_map", d["id"]))
	m.flags = d.get("flags", {})
	return m
