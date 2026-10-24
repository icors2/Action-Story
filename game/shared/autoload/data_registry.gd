extends Node
## Loads every JSON content file listed in res://data/index.json into typed defs.
## Read-only after load. Fails loudly on any error.

const INDEX_PATH := "res://data/index.json"

var stats: StatsConfig
var level_table: PackedInt64Array = PackedInt64Array()
var classes: Dictionary = {}
var skills: Dictionary = {}
var mobs: Dictionary = {}
var items: Dictionary = {}
var drop_tables: Dictionary = {}
var maps: Dictionary = {}
var mob_ids: Array[StringName] = []
var quests: Dictionary = {}
var npcs: Dictionary = {}
var dialogues: Dictionary = {}
var shops: Dictionary = {}

var _loaded: bool = false
var _errors: PackedStringArray = PackedStringArray()


func _ready() -> void:
	_loaded = load_all()
	if not _loaded:
		for e: String in _errors:
			Log.error("data", e)


func is_loaded() -> bool:
	return _loaded


func errors() -> PackedStringArray:
	return _errors


func load_all() -> bool:
	_errors.clear()
	mobs.clear()
	mob_ids.clear()
	skills.clear()
	maps.clear()
	classes.clear()
	var index: Dictionary = _read_json(INDEX_PATH)
	if index.is_empty():
		return false
	stats = StatsConfig.from_dict(_read_json(String(index["stats"])))
	level_table = PackedInt64Array(_read_json(String(index["level_table"])).get("exp_to_next", []))
	_load_category(index, "classes", "classes", classes, func(d: Dictionary) -> BaseDef: return ClassDef.from_dict(d))
	_load_category(index, "mobs", "mobs", mobs, func(d: Dictionary) -> BaseDef: return MobDef.from_dict(d))
	for id: StringName in mobs.keys():
		mob_ids.append(id)
	_load_category(index, "skills", "skills", skills, func(d: Dictionary) -> BaseDef: return SkillDef.from_dict(d))
	_load_category(index, "maps", "maps", maps, func(d: Dictionary) -> BaseDef: return MapDef.from_dict(d))
	validate_references()
	return _errors.is_empty()


func mob(id: StringName) -> MobDef:
	var d: MobDef = mobs.get(id)
	if d == null:
		push_error("Unknown mob id: %s" % id)
	return d


func mob_index(id: StringName) -> int:
	return mob_ids.find(id)


func mob_id_from_index(index: int) -> StringName:
	if index < 0 or index >= mob_ids.size():
		return &""
	return mob_ids[index]


func class_def(id: StringName) -> ClassDef:
	var d: ClassDef = classes.get(id)
	if d == null:
		push_error("Unknown class id: %s" % id)
	return d


func skill(id: StringName) -> SkillDef:
	var d: SkillDef = skills.get(id)
	if d == null:
		push_error("Unknown skill id: %s" % id)
	return d


func map_def(id: StringName) -> MapDef:
	var d: MapDef = maps.get(id)
	if d == null:
		push_error("Unknown map id: %s" % id)
	return d


func validate_references() -> void:
	for m: MobDef in mobs.values():
		if not drop_tables.is_empty() and not drop_tables.has(m.drop_table):
			_errors.append("mob %s references unknown drop_table %s" % [m.id, m.drop_table])
	for s: SkillDef in skills.values():
		if not classes.is_empty() and not classes.has(s.class_id):
			_errors.append("skill %s references unknown class %s" % [s.id, s.class_id])
	for c: ClassDef in classes.values():
		for sid: StringName in c.starting_skills:
			if not skills.has(sid):
				_errors.append("class %s starting skill missing %s" % [c.id, sid])
	for md: MapDef in maps.values():
		if md.scene_path.is_empty() or not ResourceLoader.exists(md.scene_path):
			_errors.append("map %s scene missing %s" % [md.id, md.scene_path])


func _load_category(index: Dictionary, index_key: String, array_key: String, target: Dictionary, factory: Callable) -> void:
	for path: String in index.get(index_key, []):
		var root: Dictionary = _read_json(path)
		for entry: Dictionary in root.get(array_key, []):
			var def: BaseDef = factory.call(entry)
			if def == null:
				_errors.append("%s: failed to parse entry %s" % [path, entry.get("id", "?")])
				continue
			if target.has(def.id):
				_errors.append("%s: duplicate id %s" % [path, def.id])
				continue
			def.source_path = path
			target[def.id] = def


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		_errors.append("missing data file %s (is it in index.json and the export include_filter?)" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		_errors.append("invalid JSON object in %s" % path)
		return {}
	return parsed
