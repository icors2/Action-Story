class_name Buffs
extends Component
## Timed stat bonuses. Expire restores StatsComponent.buff_bonus exactly.

class Entry:
	var stat: StringName
	var amount: int
	var ticks_left: int


var _entries: Array[Entry] = []


func apply(stat: StringName, amount: int, ticks: int) -> void:
	var e := Entry.new()
	e.stat = stat
	e.amount = amount
	e.ticks_left = maxi(ticks, 1)
	_entries.append(e)
	_rebuild()
	if entity and entity.map:
		entity.map.emit(SimEvent.make(
			Protocol.EventType.BUFF_APPLIED,
			entity.map.sim.tick,
			[entity.eid, String(stat), amount, ticks],
			Protocol.Scope.MAP
		))
	_notify_player()


func tick() -> void:
	if _entries.is_empty():
		return
	var expired: bool = false
	var keep: Array[Entry] = []
	for e: Entry in _entries:
		e.ticks_left -= 1
		if e.ticks_left <= 0:
			expired = true
			if entity and entity.map:
				entity.map.emit(SimEvent.make(
					Protocol.EventType.BUFF_EXPIRED,
					entity.map.sim.tick,
					[entity.eid, String(e.stat)],
					Protocol.Scope.MAP
				))
		else:
			keep.append(e)
	if expired:
		_entries = keep
		_rebuild()
		_notify_player()


func _rebuild() -> void:
	var stats: StatsComponent = entity.get_component(&"StatsComponent") as StatsComponent if entity else null
	if stats == null:
		return
	stats.buff_bonus.clear()
	for e: Entry in _entries:
		stats.buff_bonus[e.stat] = int(stats.buff_bonus.get(e.stat, 0)) + e.amount
	stats.recalculate()


func _notify_player() -> void:
	if entity is PlayerEntity:
		(entity as PlayerEntity).emit_stats_changed()
