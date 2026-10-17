extends Node
## Entry scene. Picks the runtime mode and hands off to the right root scene.

const SERVER_SCENE := "res://server/server_main.tscn"
const CLIENT_SCENE := "res://client/client_main.tscn"


func _ready() -> void:
	Log.info("boot", "Skyrope starting mode=%s godot=%s" % [Config.mode_name(), Engine.get_version_info()["string"]])
	if not DataRegistry.is_loaded():
		Log.error("boot", "Data failed to load; aborting")
		get_tree().quit(1)
		return
	match Config.mode:
		Config.Mode.SERVER:
			_switch_to.call_deferred(SERVER_SCENE)
		Config.Mode.CLIENT:
			_switch_to.call_deferred(CLIENT_SCENE)
		_:
			_switch_to.call_deferred(CLIENT_SCENE)


func _switch_to(path: String) -> void:
	var err: Error = get_tree().change_scene_to_file(path)
	if err != OK:
		Log.error("boot", "Failed to load %s (%s)" % [path, error_string(err)])
		get_tree().quit(1)
