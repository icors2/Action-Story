class_name DamageFormula
## Pure damage math. No node access. All randomness via injected RNG.

class AttackInput:
	var level: int
	var primary: int
	var secondary: int
	var attack: int
	var mastery_bonus: float = 0.0
	var crit_rate: float = 0.05
	var skill_pct: float = 100.0


class DefenseInput:
	var level: int
	var defense: int


class Result:
	var amount: int
	var crit: bool

	func _init(a: int, c: bool) -> void:
		amount = a
		crit = c


static func max_base(primary: int, secondary: int, attack: int) -> float:
	return float(primary * 4 + secondary) * float(attack) / 100.0


static func roll(
		atk: AttackInput,
		def_in: DefenseInput,
		cfg: StatsConfig,
		rng: RandomNumberGenerator
	) -> Result:
	var hi: float = max_base(atk.primary, atk.secondary, atk.attack) * atk.skill_pct / 100.0
	var mastery: float = clampf(cfg.mastery_base + atk.mastery_bonus, 0.1, 0.9)
	var dmg: float = rng.randf_range(hi * mastery, hi)
	var crit: bool = rng.randf() < atk.crit_rate
	if crit:
		dmg *= cfg.crit_multiplier
	dmg -= float(def_in.defense) * cfg.defense_factor
	var gap: int = maxi(def_in.level - atk.level, 0)
	dmg *= maxf(0.1, 1.0 - float(gap) * cfg.level_diff_damage_penalty_per_level)
	return Result.new(maxi(1, roundi(dmg)), crit)
