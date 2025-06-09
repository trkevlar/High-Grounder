extends Area2D

@export var speed: float = 200.0
@export var damage: int = 10
@export var lifetime: float = 3.0

var direction := Vector2.ZERO

func _ready():
	$Timer.wait_time = lifetime
	$Timer.start()
	connect("area_entered", Callable(self, "_on_area_entered"))

func set_direction(dir: Vector2):
	direction = dir.normalized()
	rotation = direction.angle()  # optional, if you want it to face movement

func _physics_process(delta):
	position += direction * speed * delta

func _on_area_entered(area: Area2D):
	if area == Global.playerhitBox:
		if Global.playerBody and is_instance_valid(Global.playerBody):
			Global.playerBody.takeDamage(damage)
		queue_free()

func _on_Timer_timeout():
	queue_free()
