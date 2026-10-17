extends Node
## Leveled logger. JSON lines on the server, readable text on the client.

enum Level { DEBUG, INFO, WARN, ERROR }

var min_level: Level = Level.INFO
var json_lines: bool = false


func debug(tag: String, msg: String, fields: Dictionary = {}) -> void:
	_emit(Level.DEBUG, tag, msg, fields)


func info(tag: String, msg: String, fields: Dictionary = {}) -> void:
	_emit(Level.INFO, tag, msg, fields)


func warn(tag: String, msg: String, fields: Dictionary = {}) -> void:
	_emit(Level.WARN, tag, msg, fields)


func error(tag: String, msg: String, fields: Dictionary = {}) -> void:
	_emit(Level.ERROR, tag, msg, fields)


func _emit(level: Level, tag: String, msg: String, fields: Dictionary) -> void:
	if level < min_level:
		return
	var lvl_name: String = String(Level.keys()[level]).to_lower()
	if json_lines:
		var rec: Dictionary = {"ts": Time.get_unix_time_from_system(), "lvl": lvl_name, "tag": tag, "msg": msg}
		rec.merge(fields)
		print(JSON.stringify(rec))
	else:
		var extra: String = "" if fields.is_empty() else " " + JSON.stringify(fields)
		print("[%s] %s: %s%s" % [lvl_name.to_upper(), tag, msg, extra])
	if level == Level.ERROR:
		push_error("%s: %s" % [tag, msg])
	elif level == Level.WARN:
		push_warning("%s: %s" % [tag, msg])
