class_name Leveling
## Pure EXP / level math. No nodes.

class Result:
	var level: int
	var exp: int
	var levels_gained: int

	func _init(p_level: int, p_exp: int, p_gained: int) -> void:
		level = p_level
		exp = p_exp
		levels_gained = p_gained


static func exp_to_next(level: int, table: PackedInt64Array) -> int:
	if level < 1 or level > table.size():
		return 0
	return int(table[level - 1])


static func max_level(table: PackedInt64Array) -> int:
	return table.size() + 1


static func add_exp(level: int, exp: int, amount: int, table: PackedInt64Array) -> Result:
	var lv: int = maxi(level, 1)
	var cur: int = maxi(exp, 0)
	var add: int = maxi(amount, 0)
	var gained: int = 0
	var cap: int = max_level(table)
	cur += add
	while lv < cap:
		var need: int = exp_to_next(lv, table)
		if need <= 0 or cur < need:
			break
		cur -= need
		lv += 1
		gained += 1
	if lv >= cap:
		cur = 0
	return Result.new(lv, cur, gained)


static func apply_death_penalty(level: int, exp: int, pct: float, table: PackedInt64Array) -> int:
	var need: int = exp_to_next(level, table)
	if need <= 0:
		return exp
	var loss: int = int(floor(float(need) * pct))
	return maxi(0, exp - loss)
