extends CharacterBody2D

class_name enemyTanah

var owner_spawner: Node = null

const speed = 30
var isEnemyChase: bool

var health = 80
var healthMax = 80
var healthMin = 0

var dead: bool = false
var takingDamage: bool = false
var damageToDeal = 6
var isDealingDamage: bool = false
var can_attack: bool = true

var dir: Vector2
const gravity = 900
var knockbackForce = -20
var isRoaming: bool = true

var target_player: CharacterBody2D
var playerInArea = false

var takingDamageTimer: float = 0.0
var takingDamageDuration: float = 0.8
signal enemy_died

func _ready():
	$AnimatedSprite2D.connect("frame_changed", Callable(self, "_on_frame_changed"))

func _on_frame_changed():
	pass
	#if $AnimatedSprite2D.animation == "attack":
		#if $AnimatedSprite2D.frame == 3 and isDealingDamage:
			#deal_damage_to_player()
			
func deal_damage_to_player():
	print("Attempting to deal damage")
	if target_player and not dead and not takingDamage:
		print("Dealing damage once")
		target_player.takeDamage(damageToDeal)

func _process(delta):
	if takingDamage:
		takingDamageTimer -= delta
		if takingDamageTimer <= 0:
			takingDamage = false
	if !is_on_floor():
		velocity.y += gravity * delta
		velocity.x = 0
	
	if Global.playerAlive:
		isEnemyChase = true
	elif !Global.playerAlive:
		isEnemyChase = false
	
	Global.enemyTanahDamageAmount = damageToDeal
	Global.enemyTanahDamageZone = $enemyTanahDealDamage
	
	target_player = Global.playerBody
	
	move(delta)
	handleAnimation()
	move_and_slide()

func move(delta):
	if !dead:
		if !isEnemyChase:
			velocity += dir * speed * delta
		elif isEnemyChase and !takingDamage:
			var dirToPlayer = position.direction_to(target_player.position) * speed
			velocity.x = dirToPlayer.x
			dir.x = abs(velocity.x) / velocity.x
		elif takingDamage:
			var knockbackDir = position.direction_to(target_player.position) * knockbackForce
			velocity.x = knockbackDir.x
		isRoaming = true
			
	elif dead:
		velocity.x = 0

func handleAnimation():
	var animatedSprite = $AnimatedSprite2D

	if dead and isRoaming:
		isRoaming = false
		animatedSprite.play("death")
		emit_signal("enemy_died")
		await get_tree().create_timer(0.8).timeout
		handleDeath()

	elif !dead and takingDamage and !isDealingDamage:
		animatedSprite.play("hit")

	elif !dead and !takingDamage and !isDealingDamage:
		animatedSprite.play("run")

	if dir.x == -1:
		animatedSprite.flip_h = false
	elif dir.x == 1:
		animatedSprite.flip_h = true

func handleDeath():
	self.queue_free()

func _on_direction_timer_timeout() -> void:
	$DirectionTimer.wait_time = choose([1.5, 2.0, 2.5])
	if !isEnemyChase:
		dir = choose([Vector2.RIGHT, Vector2.LEFT])
		velocity.x = 0
	
func choose(array):
	array.shuffle()
	return array.front()
	
func _on_enemy_tanah_hitbox_area_entered(area: Area2D) -> void:
	var damage = Global.playerDamageAmount
	if area == Global.playerDamageZone:
		takeDamage(damage)

func takeDamage(damage):
	health -= damage
	takingDamage = true
	if health <= healthMin:
		health = healthMin
		dead = true
	else:
		takingDamage = true
		takingDamageTimer = takingDamageDuration
		
func _on_enemy_tanah_deal_damage_area_entered(area: Area2D) -> void:
	if area == Global.playerhitBox and not dead and not takingDamage:
		start_attacking()


func _on_enemy_tanah_deal_damage_area_exited(area: Area2D) -> void:
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
	
	$AnimatedSprite2D.play("run")
	await $AnimatedSprite2D.animation_finished
	
	# Hanya deal damage di frame tertentu (contoh: frame 3)
	if playerInArea and isDealingDamage:  # Pastikan masih dalam keadaan menyerang
		
		deal_damage_to_player()
	
	isDealingDamage = false
	await get_tree().create_timer(0.5).timeout  # Cooldown sebelum serangan berikutnya
	can_attack = true
	
	if playerInArea:  # Jika player masih dalam area, lanjutkan serangan
		try_attack_loop()
