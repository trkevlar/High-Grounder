extends Area2D

@export var skill_type: PlayerSkill.SkillType = PlayerSkill.SkillType.STRENGTH_UP
@export var skill_value: float = 5   # Misal 20% speed tambaha

func _on_body_entered(body: Node2D) -> void:
	if body is player:
		var new_skill = PlayerSkill.new(skill_type, skill_value)
		body.add_skill(new_skill)
		queue_free()
