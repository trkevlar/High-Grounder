extends Area2D

@export var skill_type: PlayerSkill.SkillType = PlayerSkill.SkillType.LIFE_STEAL
@export var skill_value: float = 0.2

func _on_body_entered(body):
	if body is player:
		var new_skill = PlayerSkill.new(skill_type, skill_value)
		body.add_skill(new_skill)
		queue_free()
		# Tambahkan efek visual/suara jika perlu
