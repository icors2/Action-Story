class_name Spawner
extends RefCounted
## Keeps max_alive mobs in a marker group and respawns after a tick delay.

var map: MapInstance
var mob_id: StringName
var marker_group: StringName
var max_alive: int = 1
var respawn_ticks: int = 480
var markers: Array[Vector2] = []
var alive_eids: Array[int] = []
var _respawn_at: Array[int] = []


func setup(p_map: MapInstance, entry: Dictionary) -> void:
	map = p_map
	mob_id = StringName(entry.get("mob", ""))
	marker_group = StringName(entry.get("marker_group", ""))
	max_alive = int(entry.get("max_alive", 1))
	var def: MobDef = DataRegistry.mob(mob_id)
	respawn_ticks = int(entry.get("respawn_ticks", def.respawn_ticks if def else 480))


func populate() -> void:
	if markers.is_empty() and map:
		markers = map.markers_in_group(marker_group)
	var n: int = mini(max_alive, markers.size()) if not markers.is_empty() else 0
	if n == 0 and max_alive > 0:
		Log.warn("sim", "spawner %s has no markers in group %s" % [mob_id, marker_group])
		return
	for _i: int in n:
		_spawn_one()


func step(tick: int) -> void:
	_prune_dead(tick)
	var still: Array[int] = []
	for due: int in _respawn_at:
		if due <= tick and alive_eids.size() < max_alive:
			_spawn_one()
		else:
			still.append(due)
	_respawn_at = still


func _prune_dead(tick: int) -> void:
	var keep: Array[int] = []
	for eid: int in alive_eids:
		if map.entities.has(eid):
			keep.append(eid)
		else:
			_respawn_at.append(tick + respawn_ticks)
	alive_eids = keep


func _spawn_one() -> void:
	if map == null or markers.is_empty():
		return
	var def: MobDef = DataRegistry.mob(mob_id)
	if def == null:
		return
	var idx: int = map.sim.rng.randi_range(0, markers.size() - 1)
	var mob: MobEntity = map.spawn_mob(def, markers[idx])
	if mob:
		alive_eids.append(mob.eid)
