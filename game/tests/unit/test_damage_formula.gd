extends GutTest

var cfg: StatsConfig
var rng: RandomNumberGenerator


func before_each() -> void:
	cfg = StatsConfig.new()
	cfg.mastery_base = 0.15
	cfg.crit_multiplier = 1.5
	cfg.defense_factor = 0.5
	cfg.level_diff_damage_penalty_per_level = 0.02
	rng = RandomNumberGenerator.new()
	rng.seed = 1234


func _atk(primary: int, secondary: int, attack: int) -> DamageFormula.AttackInput:
	var a := DamageFormula.AttackInput.new()
	a.level = 10
	a.primary = primary
	a.secondary = secondary
	a.attack = attack
	a.crit_rate = 0.0
	return a


func _def(level: int, defense: int) -> DamageFormula.DefenseInput:
	var d := DamageFormula.DefenseInput.new()
	d.level = level
	d.defense = defense
	return d


func test_max_base_formula() -> void:
	assert_almost_eq(DamageFormula.max_base(50, 20, 40), 88.0, 0.001)


func test_damage_within_range_over_many_rolls() -> void:
	var hi: float = DamageFormula.max_base(50, 20, 40)
	for _i: int in 500:
		var r: DamageFormula.Result = DamageFormula.roll(_atk(50, 20, 40), _def(10, 0), cfg, rng)
		assert_between(r.amount, int(floor(hi * 0.15)), int(ceil(hi)))


func test_damage_never_below_one() -> void:
	var r: DamageFormula.Result = DamageFormula.roll(_atk(1, 1, 1), _def(10, 9999), cfg, rng)
	assert_eq(r.amount, 1)


func test_same_seed_same_result() -> void:
	var r1: DamageFormula.Result = DamageFormula.roll(_atk(50, 20, 40), _def(10, 5), cfg, rng)
	rng.seed = 1234
	var r2: DamageFormula.Result = DamageFormula.roll(_atk(50, 20, 40), _def(10, 5), cfg, rng)
	assert_eq(r1.amount, r2.amount)


func test_higher_level_target_reduces_damage() -> void:
	var a: DamageFormula.AttackInput = _atk(50, 20, 40)
	var low_total: int = 0
	var high_total: int = 0
	for _i: int in 200:
		low_total += DamageFormula.roll(a, _def(10, 0), cfg, rng).amount
		high_total += DamageFormula.roll(a, _def(25, 0), cfg, rng).amount
	assert_lt(high_total, low_total)


func test_defense_reduces_damage() -> void:
	var a: DamageFormula.AttackInput = _atk(50, 20, 40)
	var raw: int = 0
	var armored: int = 0
	for _i: int in 200:
		raw += DamageFormula.roll(a, _def(10, 0), cfg, rng).amount
		armored += DamageFormula.roll(a, _def(10, 40), cfg, rng).amount
	assert_lt(armored, raw)


func test_crit_increases_average() -> void:
	var a: DamageFormula.AttackInput = _atk(50, 20, 40)
	var normal: int = 0
	var crits: int = 0
	rng.seed = 99
	for _i: int in 200:
		normal += DamageFormula.roll(a, _def(10, 0), cfg, rng).amount
	a.crit_rate = 1.0
	rng.seed = 99
	for _i: int in 200:
		var r: DamageFormula.Result = DamageFormula.roll(a, _def(10, 0), cfg, rng)
		assert_true(r.crit)
		crits += r.amount
	assert_gt(crits, normal)
