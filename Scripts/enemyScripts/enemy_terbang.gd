extends CharacterBody2D

class_name flyEnemy

const speed = 30
var dir: Vector2

var is_crab_chase: bool

var target_player: CharacterBody2D

var health = 50
var healthMax = 50
var healthMin = 0
var dead = false
var takingDamage = false
var isRoaming: bool
var damageToDeal = 10

@onready var animatedSprite = $AnimatedSprite2D

func _ready():
	is_crab_chase = true

func _process(delta):
	Global.crabDamageAmount = damageToDeal
	Global.crabDamageZone = $crabDamageArea
	target_player = Global.playerBody
	if Global.playerAlive and is_instance_valid(Global.playerBody):
		target_player = Global.playerBody
		is_crab_chase = true
	else:
		is_crab_chase = false
	
	if is_on_floor() and dead:
		await get_tree().create_timer(0.8).timeout
		self.queue_free()
	
	move(delta)
	handle_animation()
	


func move(delta):
	if !dead:
		isRoaming = true
		if !takingDamage and is_crab_chase and Global.playerAlive and is_instance_valid(target_player):
			velocity = position.direction_to(target_player.position) * speed
			dir.x = abs(velocity.x) / velocity.x
		elif takingDamage and is_instance_valid(target_player):
			var knockbackDir = position.direction_to(target_player.position) * -50
			velocity = knockbackDir
		else:
			velocity += dir * speed * delta
	elif dead:
		velocity.y += 10 * delta
		velocity.x = 0
	move_and_slide()

func _on_timer_timeout() -> void:
	$Timer.wait_time = choose([1.0, 1.5, 2.0])
	if !is_crab_chase:
		dir = choose([Vector2.RIGHT, Vector2.UP, Vector2.LEFT, Vector2.DOWN])

func handle_animation():
	if !dead and !takingDamage:
		animatedSprite.play("run")
		if dir.x == -1:
			animatedSprite.flip_h = false
		elif dir.x == 1:
			animatedSprite.flip_h = true
	elif !dead and takingDamage:
		animatedSprite.play("hit")
		await get_tree().create_timer(0.8).timeout
		takingDamage = false
	elif dead and isRoaming:
		isRoaming = false
		animatedSprite.play("death")
		set_collision_layer_value(1, true)
		set_collision_layer_value(2, false)
		set_collision_mask_value(1, true)
		set_collision_mask_value(2, false)

func choose(array):
	array.shuffle()
	return array.front()


func _on_crab_hitbox_area_entered(area: Area2D) -> void:
	if area == Global.playerDamageZone:
		var damage = Global.playerDamageAmount
		takeDamage(damage)

func takeDamage(damage):
	health -= damage
	takingDamage = true
	if health <= 0:
		health = 0
		dead = true
	print(str(self), "Darah = ", health)
