class_name ProjectileEntity
extends Entity
## Tick-stepped projectile. Hits mob hurtboxes via HitQuery.

var owner_eid: int = 0
var skill: SkillDef
var skill_level: int = 1
var facing: int = 1
var speed: float = 220.0
var _life: int = 48
var _spent: bool = false


func _ready() -> void:
	kind = Const.EntityKind.PROJECTILE
	collision_layer = Const.bit(int(Const.Layer.PROJECTILE))
	collision_mask = 0


func setup(owner: PlayerEntity, p_skill: SkillDef, p_level: int, p_facing: int) -> void:
	owner_eid = owner.eid
	skill = p_skill
	skill_level = p_level
	facing = 1 if p_facing >= 0 else -1
	speed = p_skill.projectile_speed
	_life = p_skill.projectile_lifetime_ticks
	global_position = owner.global_position + Vector2(float(facing) * 12.0, -10.0)
	velocity = Vector2(float(facing) * speed, 0.0)


func step_projectile(_tick: int) -> void:
	if _spent:
		return
	global_position += velocity * NetConfig.TICK_DT
	_life -= 1
	_try_hit()
	if _life <= 0 and map:
		map.remove_entity(eid)


func _try_hit() -> void:
	if map == null or skill == null:
		return
	var size: Vector2 = skill.hitbox_size
	if size == Vector2.ZERO:
		size = Vector2(12, 10)
	var hits: Array[Entity] = HitQuery.query_rect(
		map.space_state(),
		global_position,
		facing,
		Vector2.ZERO,
		size,
		int(Const.Layer.MOB_HURTBOX),
		skill.max_targets
	)
	if hits.is_empty():
		return
	var owner: PlayerEntity = map.entities.get(owner_eid) as PlayerEntity
	if owner == null:
		_spent = true
		map.remove_entity(eid)
		return
	for t: Entity in hits:
		CombatResolver.resolve_direct_hit(owner, t, skill, skill_level, facing, 0)
	_spent = true
	map.remove_entity(eid)


func to_entity_state() -> EntityState:
	var s: EntityState = super.to_entity_state()
	s.kind = int(Const.EntityKind.PROJECTILE)
	s.flags = 0 if facing >= 0 else Const.FLAG_FACE_LEFT
	s.anim = Const.Anim.ATTACK
	return s
