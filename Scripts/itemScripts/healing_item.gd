extends Area2D

@export var health_restore_amount := 20

func _on_body_entered(body):
	if body.is_in_group("Player"):  # Pastikan player masuk grup
		if body.health < body.healthMax:
			body.health += health_restore_amount
			if body.health > body.healthMax:
				body.health = body.healthMax
			queue_free()
