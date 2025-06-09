extends RefCounted
class_name PlayerSkill

enum SkillType {
	LIFE_STEAL,     # % life steal
	STRENGTH_UP,    # +damage
	HEALTH_UP,      # +max HP
	SPEED_UP,
	DAMAGE_RESISTANCE
}

var type: SkillType
var value: float
var is_active: bool = true

func _init(skill_type: SkillType, skill_value: float):
	type = skill_type
	value = skill_value
