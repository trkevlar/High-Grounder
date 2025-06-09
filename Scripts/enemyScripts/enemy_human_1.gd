extends CharacterBody2D

class_name enemyHuman
@export var detect_range = 200.0
@export var attack_range = 30.0
var owner_spawner: Node = null

const speed = 30
var isEnemyChase: bool

var health = 100
var healthMax = 100
var healthMin = 0

var dead: bool = false
var takingDamage: bool = false
var damageToDeal = 15
var isDealingDamage: bool = false
var can_attack: bool = true

var dir: Vector2
const gravity = 900
var knockbackForce = -5

var target_player: CharacterBody2D
var playerInArea = false

var takingDamageTimer: float = 0.0
var takingDamageDuration: float = 0.8
var attackCooldownTimer: float = 0.0
var attackCooldown: float = 1.5

var has_dealt_damage: bool = false
var has_dropped_item: bool = false

var is_attacking: bool = false
signal enemy_died

func _ready():
	$AnimatedSprite2D.connect("animation_finished", Callable(self, "_on_animation_finished"))
	$AnimatedSprite2D.connect("frame_changed", Callable(self, "_on_frame_changed"))

func _on_frame_changed():
	if $AnimatedSprite2D.animation == "attack" and $AnimatedSprite2D.frame == 2:
		if isDealingDamage and not has_dealt_damage:  # Add a flag to track if damage was dealt
			deal_damage_to_player()
			has_dealt_damage = true
	else:
		has_dealt_damage = false 
		
func _on_animation_finished():
	if $AnimatedSprite2D.animation == "attack":
		isDealingDamage = false
		stop_attacking()
			
func deal_damage_to_player():
	if playerInArea and not dead and not takingDamage and target_player and is_instance_valid(target_player):
		target_player.takeDamage(damageToDeal)

func _process(delta):
	if dead:
		velocity = Vector2.ZERO
		handleAnimation()
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	if takingDamage:
		takingDamageTimer -= delta
		if takingDamageTimer <= 0:
			takingDamage = false
			# Setelah selesai takingDamage, coba mulai attack lagi kalau player masih di area
			if playerInArea and not is_attacking and can_attack and not dead:
				start_attacking()
	
	if attackCooldownTimer > 0:
		attackCooldownTimer -= delta
	else:
		can_attack = true

	if Global.playerAlive:
		target_player = Global.playerBody
		var to_player = target_player.global_position - global_position
		var distance = global_position.distance_to(target_player.global_position)

		if distance <= detect_range:
			isEnemyChase = true
			if distance > attack_range or not playerInArea or takingDamage:
				dir.x = sign(to_player.x)
				velocity.x = speed * dir.x
				isDealingDamage = false
			else:
				velocity.x = 0
				if can_attack and not isDealingDamage and not is_attacking:
					start_attacking()
		else:
			isEnemyChase = false
			#velocity.x = 0
	else:
		isEnemyChase = false
		#velocity.x = 0
		target_player = null
	
	#Global.enemyHumanDamageAmount = damageToDeal
	#Global.enemyHumanDamageZone = $enemyDealDamage
	
	if is_instance_valid(target_player):
		var distance = global_position.distance_to(target_player.global_position)
		if distance > detect_range:
			isEnemyChase = false
			velocity.x = 0
			dir.x = 0 
			
	move(delta)
	handleAnimation()
	move_and_slide()

func move(delta):
	if !dead:
		if !isEnemyChase:
			velocity += dir * speed * delta
		elif isEnemyChase and !takingDamage and target_player:
			var dirToPlayer = position.direction_to(target_player.position) * speed
			velocity.x = dirToPlayer.x
			if velocity.x != 0:
				dir.x = sign(velocity.x)
		elif takingDamage:
			var knockbackDir = position.direction_to(target_player.position) * knockbackForce
			velocity.x = knockbackDir.x
			
	else:
		velocity.x = 0

func handleAnimation():
	var animatedSprite = $AnimatedSprite2D
	if dead:
		animatedSprite.play("death")
		emit_signal("enemy_died")
		drop_item()
		await get_tree().create_timer(0.8).timeout
		handleDeath()
	elif takingDamage:
		animatedSprite.play("hit")
	elif isDealingDamage:
		animatedSprite.play("attack")
	elif isEnemyChase and abs(velocity.x) > 0.1:  # Hanya run jika mengejar
		animatedSprite.play("run")
	else:  # Default ke idle
		animatedSprite.play("idle")
		velocity.x = 0  

	# Handle flipping
	if dir.x < 0:
		animatedSprite.flip_h = true
	elif dir.x > 0:
		animatedSprite.flip_h = false

func drop_item():
	if not has_dropped_item:  # Add this flag as a class variable
		has_dropped_item = true
		var item_scene = preload("res://Scenes/item/strength_up.tscn")
		var dropped_item = item_scene.instantiate()
		get_parent().call_deferred("add_child", dropped_item)
		dropped_item.global_position = global_position

func handleDeath():
	has_dropped_item = false
	queue_free()

func _on_direction_timer_timeout() -> void:
	if dead or isEnemyChase:
		return
	$DirectionTimer.wait_time = choose([1.5, 2.0, 2.5])
	dir = choose([Vector2.RIGHT, Vector2.LEFT])
	velocity.x = 0
	
func choose(array):
	array.shuffle()
	return array.front()

func takeDamage(damage):
	if dead or takingDamage:
		return
	health -= damage
	takingDamage = true
	takingDamageTimer = takingDamageDuration
	if is_attacking:
		stop_attacking()
	if health <= healthMin:
		health = healthMin
		dead = true
		
func start_attacking():
	has_dealt_damage = false
	if dead or takingDamage or is_attacking:
		return
		
	is_attacking = true
	can_attack = false
	isDealingDamage = true
	attackCooldownTimer = attackCooldown
	$AnimatedSprite2D.play("attack")

func stop_attacking():
	is_attacking = false
	isDealingDamage = false
	can_attack = true

func _on_enemy_hitbox_area_entered(area: Area2D) -> void:
	if area == Global.playerDamageZone:
		takeDamage(Global.playerDamageAmount)

func _on_enemy_deal_damage_area_entered(area: Area2D) -> void:
	if area == Global.playerhitBox and not dead:
		playerInArea = true
		if not is_attacking and not takingDamage:
			start_attacking()
		
func _on_enemy_deal_damage_area_exited(area: Area2D) -> void:
	if area == Global.playerhitBox:
		playerInArea = false
		stop_attacking()
		# Tambahkan pengecekan jika player keluar dari detect_range
		if is_instance_valid(target_player):
			var distance = global_position.distance_to(target_player.global_position)
			if distance > detect_range:
				isEnemyChase = false
				velocity.x = 0
				dir.x = 0
