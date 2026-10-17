class_name StatsConfig
extends RefCounted
## Global balance constants from stats.json.

var ap_per_level: int = 5
var sp_per_level: int = 3
var starting_ap: int = 0
var base_stats: Dictionary = {"str": 4, "dex": 4, "int": 4, "luk": 4}
var crit_base_rate: float = 0.05
var crit_multiplier: float = 1.5
var mastery_base: float = 0.15
var defense_factor: float = 0.5
var level_diff_damage_penalty_per_level: float = 0.02
var hp_regen_interval_s: float = 10.0
var mp_regen_interval_s: float = 10.0
var death_exp_loss_pct: float = 0.05
var invincibility_after_hit_s: float = 1.2
var movement: Dictionary = {}


static func from_dict(d: Dictionary) -> StatsConfig:
	var s := StatsConfig.new()
	if d.is_empty():
		return s
	s.ap_per_level = int(d.get("ap_per_level", s.ap_per_level))
	s.sp_per_level = int(d.get("sp_per_level", s.sp_per_level))
	s.starting_ap = int(d.get("starting_ap", s.starting_ap))
	s.base_stats = d.get("base_stats", s.base_stats)
	s.crit_base_rate = float(d.get("crit_base_rate", s.crit_base_rate))
	s.crit_multiplier = float(d.get("crit_multiplier", s.crit_multiplier))
	s.mastery_base = float(d.get("mastery_base", s.mastery_base))
	s.defense_factor = float(d.get("defense_factor", s.defense_factor))
	s.level_diff_damage_penalty_per_level = float(d.get("level_diff_damage_penalty_per_level", s.level_diff_damage_penalty_per_level))
	s.hp_regen_interval_s = float(d.get("hp_regen_interval_s", s.hp_regen_interval_s))
	s.mp_regen_interval_s = float(d.get("mp_regen_interval_s", s.mp_regen_interval_s))
	s.death_exp_loss_pct = float(d.get("death_exp_loss_pct", s.death_exp_loss_pct))
	s.invincibility_after_hit_s = float(d.get("invincibility_after_hit_s", s.invincibility_after_hit_s))
	s.movement = d.get("movement", {})
	return s
