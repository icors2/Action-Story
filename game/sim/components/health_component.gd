class_name HealthComponent
extends Component
## HP/MP pool with invulnerability frames. Tick-based timers only.

signal damaged(amount: int, source_eid: int, is_crit: bool)
signal healed(amount: int)
signal died(killer_eid: int)

var hp: int = 1
var max_hp: int = 1
var mp: int = 0
var max_mp: int = 0
var invuln_ticks: int = 0


func is_dead() -> bool:
	return hp <= 0


## Returns damage actually dealt (0 if invulnerable/dead).
func apply_damage(amount: int, source_eid: int, is_crit: bool, invuln_after: int = 0) -> int:
	if is_dead() or invuln_ticks > 0 or amount <= 0:
		return 0
	var dealt: int = mini(amount, hp)
	hp -= dealt
	invuln_ticks = invuln_after
	damaged.emit(dealt, source_eid, is_crit)
	if hp <= 0:
		died.emit(source_eid)
	return dealt


func heal(amount: int) -> int:
	if is_dead():
		return 0
	var before: int = hp
	hp = mini(hp + maxi(amount, 0), max_hp)
	if hp != before:
		healed.emit(hp - before)
	return hp - before


func restore_mp(amount: int) -> int:
	if is_dead():
		return 0
	var before: int = mp
	mp = mini(mp + maxi(amount, 0), max_mp)
	return mp - before


func spend_mp(amount: int) -> bool:
	if amount <= 0:
		return true
	if mp < amount:
		return false
	mp -= amount
	return true


func fill(p_hp: int, p_max_hp: int, p_mp: int, p_max_mp: int) -> void:
	max_hp = maxi(p_max_hp, 1)
	max_mp = maxi(p_max_mp, 0)
	hp = clampi(p_hp, 0, max_hp)
	mp = clampi(p_mp, 0, max_mp)
	invuln_ticks = 0


func tick() -> void:
	if invuln_ticks > 0:
		invuln_ticks -= 1
