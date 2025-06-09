extends CharacterBody2D

class_name bossSlime

@export var detect_range = 150.0  # Increased detection range for boss
@export var attack_range = 40.0   # Attack range
var owner_spawner: Node = null

const speed = 30
var isEnemyChase: bool = false   # Start with false, only chase when player is in detect_range

var health = 20
var healthMax = 200
var healthMin = 0

var dead: bool = false
var takingDamage: bool = false
var damageToDeal = 15
var isDealingDamage: bool = false
var can_attack: bool = true

var dir: Vector2
const gravity = 900
var knockbackForce = -10  # Stronger knockback for boss

var target_player: CharacterBody2D
var playerInArea = false

var takingDamageTimer: float = 0.0
var takingDamageDuration: float = 0.8
var attackCooldownTimer: float = 0.0
var attackCooldown: float = 1.5

var has_dealt_damage: bool = false
var has_dropped_item: bool = false
var is_attacking: bool = false

@export var enemy_to_spawn: PackedScene  # Drag and drop musuh .tscn
@export var spawn_enemy_count: int = 10  # Jumlah musuh yang akan spawn
var has_spawned_enemies: bool = false

signal enemy_died

func _ready():
	$AnimatedSprite2D.connect("animation_finished", Callable(self, "_on_animation_finished"))
	$AnimatedSprite2D.connect("frame_changed", Callable(self, "_on_frame_changed"))

func _on_frame_changed():
	if $AnimatedSprite2D.animation == "idle" and $AnimatedSprite2D.frame == 1:
		if isDealingDamage and not has_dealt_damage:
			deal_damage_to_player()
			has_dealt_damage = true
	else:
		has_dealt_damage = false
		
func _on_animation_finished():
	if $AnimatedSprite2D.animation == "idle":
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
			if playerInArea and not is_attacking and can_attack and not dead:
				start_attacking()
	
	if attackCooldownTimer > 0:
		attackCooldownTimer -= delta
	else:
		can_attack = true

	# Improved player detection logic like enemyHuman
	if Global.playerAlive:
		target_player = Global.playerBody
		if is_instance_valid(target_player):
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
				velocity.x = 0
				dir.x = 0
	else:
		isEnemyChase = false
		velocity.x = 0
		target_player = null
	
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
	# Commented out attack animation
	elif isDealingDamage:
		animatedSprite.play("idle")
	elif isEnemyChase and abs(velocity.x) > 0.1:
		animatedSprite.play("run")
	else:
		animatedSprite.play("idle")
		velocity.x = 0  

	if dir.x < 0:
		animatedSprite.flip_h = false
	elif dir.x > 0:
		animatedSprite.flip_h = true

func drop_item():
	if not has_dropped_item:
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
		
	if health <= healthMax / 2.0 and not has_spawned_enemies:
		has_spawned_enemies = true
		call_deferred("spawn_enemies")
		
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
	# Commented out attack animation
	#$AnimatedSprite2D.play("attack")
	$AnimatedSprite2D.play("idle")  # Use idle animation instead

func stop_attacking():
	is_attacking = false
	isDealingDamage = false
	can_attack = true
		

func _on_bos_slime_hitbox_area_entered(area: Area2D) -> void:
	if area == Global.playerDamageZone:
		takeDamage(Global.playerDamageAmount)
		
		


func _on_bos_slime_deal_damage_area_entered(area: Area2D) -> void:
	if area == Global.playerhitBox and not dead:
		playerInArea = true
		if not is_attacking and not takingDamage:
			start_attacking()


func _on_bos_slime_deal_damage_area_exited(area: Area2D) -> void:
	if area == Global.playerhitBox:
		playerInArea = false
		stop_attacking()
		if is_instance_valid(target_player):
			var distance = global_position.distance_to(target_player.global_position)
			if distance > detect_range:
				isEnemyChase = false
				velocity.x = 0
				dir.x = 0

const FLOOR_MASK: int = 1 << 0  # Ganti sesuai collision layer TileMap kamu

func spawn_enemies() -> void:
	if enemy_to_spawn == null or target_player == null:
		return
	var space_state := get_world_2d().direct_space_state
	var spawned := 0
	var attempts := 0
	var max_attempts := spawn_enemy_count * 10
	while spawned < spawn_enemy_count and attempts < max_attempts:
		attempts += 1
		var offset := Vector2(randf_range(-80, 80), -40)
		var start_pos := global_position + offset
		var end_pos := start_pos + Vector2(0, 1000)
		var query := PhysicsRayQueryParameters2D.create(start_pos, end_pos)
		query.exclude = [self]
		query.collision_mask = FLOOR_MASK  # Harus sesuai dengan layer TileMap kamu
		var hit := space_state.intersect_ray(query)
		if hit:
			var ground_pos = hit.position
			if ground_pos.distance_to(target_player.global_position) > 50:
				var enemy := enemy_to_spawn.instantiate()
				# Opsional: sesuaikan tinggi spawn agar tidak setengah tertanam
				if enemy.has_node("CollisionShape2D"):
					var shape := enemy.get_node("CollisionShape2D")
					if shape is CollisionShape2D and shape.shape is RectangleShape2D:
						ground_pos.y -= (shape.shape as RectangleShape2D).size.y * 0.5
				enemy.global_position = ground_pos
				get_parent().add_child(enemy)
				spawned += 1
