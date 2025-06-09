extends CharacterBody2D

class_name bossGolem

@export var projectile_scene: PackedScene
@export var ranged_attack_range: float = 150.0
var use_projectile: bool = false

@export var detect_range = 200.0  # Increased detection range for boss
@export var attack_range = 20.0   # Attack range
var owner_spawner: Node = null

const speed = 30
var isEnemyChase: bool = false   # Start with false, only chase when player is in detect_range

var health = 150
var healthMax = 150
var healthMin = 0

var dead: bool = false
var takingDamage: bool = false
var damageToDeal = 13
var isDealingDamage: bool = false
var can_attack: bool = true

var dir: Vector2
const gravity = 900
var knockbackForce = -10  # Stronger knockback for boss

var target_player: CharacterBody2D
var playerInArea = false

var takingDamageTimer: float = 0.0
var takingDamageDuration: float = 0.2
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
	if $AnimatedSprite2D.animation == "attack" and $AnimatedSprite2D.frame == 2:
		if isDealingDamage and not has_dealt_damage:
			deal_damage_to_player()
			has_dealt_damage = true
	elif $AnimatedSprite2D.animation == "attackRange" and $AnimatedSprite2D.frame == 8:
		if isDealingDamage and not has_dealt_damage:
			shoot_projectile()
			has_dealt_damage = true
	else:
		has_dealt_damage = false
		
func _on_animation_finished():
	if $AnimatedSprite2D.animation in ["attack", "attackRange"]:
		isDealingDamage = false
		stop_attacking()   # ← ini meng-reset is_attacking & can_attack
			
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
	
	if attackCooldownTimer > 0.0:
		attackCooldownTimer -= delta
		if attackCooldownTimer <= 0.0:
			can_attack = true      # cooldown selesai
	else:
		can_attack = true 

	# Improved player detection logic like enemyHuman
	if Global.playerAlive:
		target_player = Global.playerBody
		if is_instance_valid(target_player):
			var to_player = target_player.global_position - global_position
			var distance = global_position.distance_to(target_player.global_position)
			dir.x = sign(to_player.x)
			if is_attacking and distance > detect_range:
				stop_attacking()  
			# 1. Prioritaskan serangan melee jika dalam area dekat
			elif distance < attack_range:
				if is_attacking and use_projectile and not takingDamage:
					stop_attacking()
					attackCooldownTimer = 0.0      
				use_projectile = false
				if can_attack and not is_attacking and not takingDamage:
					velocity.x = 0
					start_attacking()
				#return

			# 2. RANGED (kalau tidak di jarak melee)
			elif distance < ranged_attack_range:
				use_projectile = true
				if can_attack and not is_attacking and not takingDamage:
					velocity.x = 0
					start_attacking()
				#return

			# 3. Jika masih dalam jarak deteksi, kejar
			elif distance <= detect_range:
				isEnemyChase = true
				# Cegah gerakan saat sedang menyerang dengan projectile
				if not (is_attacking and use_projectile):
					velocity.x = speed * dir.x
				else:
					velocity.x = 0

			# 4. Di luar jarak deteksi, diam
			else:
				isEnemyChase = false
				velocity.x = 0

	else:
		isEnemyChase = false
		velocity.x = 0
		target_player = null
	
	move(delta)
	handleAnimation()
	move_and_slide()

func move(_delta):
	if dead:
		velocity.x = 0
		return

	if use_projectile:
		velocity.x = 0
		return
		
	if takingDamage:
		var knockbackDir = position.direction_to(target_player.position) * knockbackForce
		velocity.x = knockbackDir.x
		return

	if isEnemyChase and target_player:
		velocity.x = sign(target_player.position.x - position.x) * speed
	else:
		velocity.x = dir.x * speed

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
		if $AnimatedSprite2D.animation == "attack":
			animatedSprite.play("attack")
		if $AnimatedSprite2D.animation == "attackRange":
			animatedSprite.play("attackRange")
			
	elif isEnemyChase and abs(velocity.x) > 0.1:
		animatedSprite.play("run")
	else:
		animatedSprite.play("idle")
		velocity.x = 0  

	if dir.x < 0:
		animatedSprite.flip_h = true
	elif dir.x > 0:
		animatedSprite.flip_h = false

func drop_item():
	if not has_dropped_item:
		has_dropped_item = true
		var item_scene = preload("res://Scenes/item/damage_resistance.tscn")
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

	if use_projectile:
		$AnimatedSprite2D.play("attackRange")
	else:
		$AnimatedSprite2D.play("attack")

func shoot_projectile():
	if use_projectile:
		if projectile_scene == null or target_player == null:
			return
		var projectile = projectile_scene.instantiate()
		get_parent().add_child(projectile)
		
		# Hitung arah ke player
		var dir_to_player = (target_player.global_position - global_position).normalized()
		
		# Tempatkan projectile dan atur rotasi
		projectile.global_position = global_position + Vector2(dir.x * 24, -8)
		projectile.direction = dir_to_player
		projectile.rotation = dir_to_player.angle()  # <-- atur rotasi berdasarkan arah


func stop_attacking():
	is_attacking = false
	isDealingDamage = false
	#can_attack = true
	use_projectile = false

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


func _on_bos_golem_hitbox_area_entered(area: Area2D) -> void:
	if area == Global.playerDamageZone:
		takeDamage(Global.playerDamageAmount)


func _on_bos_golem_deal_damage_area_entered(area: Area2D) -> void:
	if area == Global.playerhitBox and not dead:
		playerInArea = true

		# paksa ganti ke melee kalau sedang menembak
		if is_attacking and use_projectile and not takingDamage:
			stop_attacking()
			attackCooldownTimer = 0.0   # boleh langsung melee
			use_projectile = false

		if not is_attacking and not takingDamage:
			start_attacking()


func _on_bos_golem_deal_damage_area_exited(area: Area2D) -> void:
	if area == Global.playerhitBox:
		playerInArea = false
		if use_projectile:  # Reset flag agar bisa berpindah logika serangan
			use_projectile = false
		stop_attacking()
		if is_instance_valid(target_player):
			var distance = global_position.distance_to(target_player.global_position)
			if distance > detect_range:
				isEnemyChase = false
				velocity.x = 0
				dir.x = 0
