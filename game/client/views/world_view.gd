class_name WorldView
extends Node2D
## Spawns and interpolates mob/projectile views from snapshots. Combat FX from events.

var _views: Dictionary = {}
var _projs: Dictionary = {}
var _missing: Dictionary = {}
var _stacks: Dictionary = {}
var player_view: PlayerView


func apply_snapshot(snap: Snapshot) -> void:
	var seen: Dictionary = {}
	var now: float = Time.get_ticks_msec() / 1000.0
	for st: EntityState in snap.entities:
		if st.kind == int(Const.EntityKind.MOB):
			seen[st.eid] = true
			_missing.erase(st.eid)
			var view: MobView = _views.get(st.eid)
			if view == null:
				view = MobView.new()
				view.setup(st)
				add_child(view)
				_views[st.eid] = view
			view.apply_state(st, now)
		elif st.kind == int(Const.EntityKind.PROJECTILE):
			seen[st.eid] = true
			_missing.erase(st.eid)
			var bolt: ProjectileView = _projs.get(st.eid)
			if bolt == null:
				bolt = ProjectileView.new()
				bolt.setup(st)
				add_child(bolt)
				_projs[st.eid] = bolt
			bolt.apply_state(st, now)
	_sweep_missing(_views, seen)
	_sweep_missing(_projs, seen)


func apply_event(event: SimEvent) -> void:
	match event.type:
		Protocol.EventType.DAMAGE:
			_on_damage(event.data)
		Protocol.EventType.ENTITY_DESPAWNED:
			if event.data.size() > 0:
				despawn(int(event.data[0]))
		Protocol.EventType.INTENT_REJECTED:
			if player_view and event.data.size() > 0 and int(event.data[0]) == GameState.last_cast_seq:
				player_view.cancel_attack()


func despawn(eid: int) -> void:
	_free_node(_views, eid)
	_free_node(_projs, eid)
	_missing.erase(eid)
	_stacks.erase(eid)


func _sweep_missing(bucket: Dictionary, seen: Dictionary) -> void:
	var gone: Array[int] = []
	for eid: int in bucket.keys():
		if seen.has(eid):
			continue
		var misses: int = int(_missing.get(eid, 0)) + 1
		_missing[eid] = misses
		if misses >= 3:
			gone.append(eid)
	for eid: int in gone:
		despawn(eid)


func _free_node(bucket: Dictionary, eid: int) -> void:
	var n: Node = bucket.get(eid)
	if n:
		n.queue_free()
	bucket.erase(eid)


func _on_damage(data: Array) -> void:
	if data.size() < 5:
		return
	var attacker: int = int(data[0])
	var target: int = int(data[1])
	var amount: int = int(data[2])
	var crit: bool = bool(data[3])
	var stack: int = int(_stacks.get(target, 0))
	_stacks[target] = stack + 1
	var at: Vector2 = _pos_of(target)
	_spawn_number(at + Vector2(0, -20), amount, crit, stack)
	var view: MobView = _views.get(target)
	if view:
		view.flash()
		view.show_hp()
	if attacker == GameState.self_eid and player_view:
		player_view.hit_stop(3)


func _pos_of(eid: int) -> Vector2:
	var view: Node2D = _views.get(eid)
	if view:
		return view.global_position
	var bolt: Node2D = _projs.get(eid)
	if bolt:
		return bolt.global_position
	if GameState.self_eid == eid:
		return GameState.self_pos
	return Vector2.ZERO


func _spawn_number(at: Vector2, amount: int, crit: bool, stack: int) -> void:
	var n := DamageNumber.new()
	add_child(n)
	n.global_position = at
	n.play(amount, crit, stack)
