extends Area2D

func _ready() -> void:
	$AnimatedSprite2D.play("default")

func _on_body_entered(body: Node2D) -> void:
	if body is player:
		body.pick_up_key()  # panggil fungsi di player
		queue_free()  # hapus pedang dari scene
