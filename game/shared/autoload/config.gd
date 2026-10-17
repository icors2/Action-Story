extends Node
## Runtime configuration from cmdline user args (after `--`), env vars, and user settings.

enum Mode { LOCAL, CLIENT, SERVER, TEST }

var mode: Mode = Mode.LOCAL
var server_port: int = 7777
var max_clients: int = 100
var connect_host: String = ""
var connect_port: int = 7777
var backend_url: String = "http://localhost:8080"
var service_token: String = ""
var ticket_hmac_key: String = ""
var channel_id: int = 1
var rng_seed: int = 0
var local_codec_roundtrip: bool = false
var data_dir: String = "/data"


func _init() -> void:
	_parse_args(OS.get_cmdline_user_args())
	_parse_env()
	if OS.has_feature("dedicated_server"):
		mode = Mode.SERVER


func is_server() -> bool:
	return mode == Mode.SERVER


func mode_name() -> String:
	return String(Mode.keys()[mode])


func _parse_args(args: PackedStringArray) -> void:
	for arg: String in args:
		if arg == "--server":
			mode = Mode.SERVER
		elif arg.begins_with("--port="):
			server_port = int(arg.get_slice("=", 1))
		elif arg.begins_with("--connect="):
			mode = Mode.CLIENT
			var target: String = arg.get_slice("=", 1)
			connect_host = target.get_slice(":", 0)
			if target.contains(":"):
				connect_port = int(target.get_slice(":", 1))
		elif arg.begins_with("--seed="):
			rng_seed = int(arg.get_slice("=", 1))
		elif arg == "--codec-roundtrip":
			local_codec_roundtrip = true


func _parse_env() -> void:
	server_port = _env_int("SKYROPE_PORT", server_port)
	max_clients = _env_int("SKYROPE_MAX_CLIENTS", max_clients)
	channel_id = _env_int("SKYROPE_CHANNEL", channel_id)
	if OS.has_environment("SKYROPE_BACKEND_URL"):
		backend_url = OS.get_environment("SKYROPE_BACKEND_URL")
	if OS.has_environment("SKYROPE_SERVICE_TOKEN"):
		service_token = OS.get_environment("SKYROPE_SERVICE_TOKEN")
	if OS.has_environment("SKYROPE_TICKET_KEY"):
		ticket_hmac_key = OS.get_environment("SKYROPE_TICKET_KEY")
	if OS.has_environment("SKYROPE_DATA_DIR"):
		data_dir = OS.get_environment("SKYROPE_DATA_DIR")


func _env_int(key: String, fallback: int) -> int:
	return int(OS.get_environment(key)) if OS.has_environment(key) else fallback
