extends CharacterBody2D

class_name flyEnemy

var owner_spawner: Node = null

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

var chase_threshold_distance = 10.0

var can_attack = true
var isDealingDamage = false
var playerInArea = false

signal enemy_died

@onready var animatedSprite = $AnimatedSprite2D

func _ready():
	is_crab_chase = true

func _on_frame_changed():
	if animatedSprite.animation == "run" and animatedSprite.frame == 3 and isDealingDamage:
		deal_damage_to_player()

func deal_damage_to_player():
	if not is_instance_valid(target_player):
		return
	if playerInArea and !dead and !takingDamage and isDealingDamage:
		target_player.takeDamage(damageToDeal)
		isDealingDamage = false

func _process(delta):
	Global.crabDamageAmount = damageToDeal
	Global.crabDamageZone = $crabDamageArea
	target_player = Global.playerBody
	if Global.playerAlive and is_instance_valid(Global.playerBody):
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
		if is_crab_chase and Global.playerAlive and is_instance_valid(target_player):
			var distance_to_player = position.distance_to(target_player.position)
			if !takingDamage and is_crab_chase:
				if distance_to_player > chase_threshold_distance:
					velocity = position.direction_to(target_player.position) * speed
					if velocity.x != 0:
						dir.x = sign(velocity.x)
						animatedSprite.flip_h = dir.x < 0
				else:
					# Jarak terlalu dekat, berhenti atau tetap menghadap arah
					velocity = Vector2.ZERO
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
		if dir.x != 0:
			animatedSprite.flip_h = dir.x < 0

func handle_animation():
	if !dead and takingDamage:
		animatedSprite.play("hit")
		await get_tree().create_timer(0.8).timeout
		takingDamage = false
	
	elif !dead and !takingDamage and !isDealingDamage:
		animatedSprite.play("run")
	
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
		emit_signal("enemy_died")
		dead = true


func _on_crab_damage_area_area_entered(area: Area2D) -> void:
	if area == Global.playerhitBox and !dead and !takingDamage:
		start_attacking()


func _on_crab_damage_area_area_exited(area: Area2D) -> void:
	if area == Global.playerhitBox:
		stop_attacking() 

func start_attacking():
	playerInArea = true
	try_attack_loop()

func stop_attacking():
	playerInArea = false
	isDealingDamage = false

func try_attack_loop():
	if not playerInArea or dead or takingDamage or not can_attack:
		return

	isDealingDamage = true
	can_attack = false
	
	animatedSprite.play("run")
	await animatedSprite.animation_finished
	await get_tree().create_timer(0.5).timeout

	isDealingDamage = false
	can_attack = true

	if playerInArea:
		try_attack_loop()
