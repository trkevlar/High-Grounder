extends CharacterBody2D

class_name enemyTanah

const speed = 30
var isEnemyChase: bool

var health = 80
var healthMax = 80
var healthMin = 0

var dead: bool = false
var takingDamage: bool = false
var damageToDeal = 20
var isDealingDamage: bool = false
var can_attack: bool = true

var dir: Vector2
const gravity = 900
var knockbackForce = -20
var isRoaming: bool = true

var player: CharacterBody2D
var playerInArea = false

var takingDamageTimer: float = 0.0
var takingDamageDuration: float = 0.8

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
	
	player = Global.playerBody
	
	move(delta)
	handleAnimation()
	move_and_slide()

func move(delta):
	if !dead:
		if !isEnemyChase:
			velocity += dir * speed * delta
		elif isEnemyChase and !takingDamage:
			var dirToPlayer = position.direction_to(player.position) * speed
			velocity.x = dirToPlayer.x
			dir.x = abs(velocity.x) / velocity.x
		elif takingDamage:
			var knockbackDir = position.direction_to(player.position) * knockbackForce
			velocity.x = knockbackDir.x
		isRoaming = true
			
	elif dead:
		velocity.x = 0

func handleAnimation():
	var animatedSprite = $AnimatedSprite2D
	if !dead and !takingDamage and !isDealingDamage:
		animatedSprite.play("run")
		if dir.x == -1:
			animatedSprite.flip_h = false
		elif dir.x == 1:
			animatedSprite.flip_h = true
	elif !dead and takingDamage and !isDealingDamage:
		animatedSprite.play("hit")
	elif dead and isRoaming:
		isRoaming = false
		animatedSprite.play("death")
		await get_tree().create_timer(0.8).timeout
		handleDeath()
	elif !dead and isDealingDamage:
		animatedSprite.play("attack")

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
	print(str(self), "Health sekarang = ", health)

func _on_enemy_tanah_deal_damage_area_entered(area: Area2D) -> void:
	if area == Global.playerhitBox and not dead and not takingDamage:
		start_attacking()  # Mulai serangan berulang
		
func _on_enemy_tanah_deal_damage_area_exited(area: Area2D) -> void:
	if area == Global.playerhitBox:
		stop_attacking() 

func start_attacking():
	playerInArea = true
	try_attack_loop()

func stop_attacking():
	playerInArea = false
	isDealingDamage = false  # Stop animasi attack

func try_attack_loop():
	if not playerInArea or dead or takingDamage or not can_attack:
		return
	
	# Trigger serangan
	isDealingDamage = true
	can_attack = false
	
	# Beri cooldown sebelum serangan berikutnya
	await get_tree().create_timer(0.8).timeout
	
	can_attack = true
	try_attack_loop()  # Cek lagi apakah masih dalam jangkauan



#animasi attack

#extends CharacterBody2D
#
#class_name enemyTanah
#
#const speed = 30
#var isEnemyChase: bool
#
#var health = 80
#var healthMax = 80
#var healthMin = 0
#
#var dead: bool = false
#var takingDamage: bool = false
#var damageToDeal = 20
#var isDealingDamage: bool = false
#
#var dir: Vector2
#const gravity = 900
#var knockbackForce = -20
#var isRoaming: bool = true
#
#var player: CharacterBody2D
#var playerInArea = false
#
#var takingDamageTimer: float = 0.0
#var takingDamageDuration: float = 0.8
#
#var attack_timer: Timer
#
#func _ready():
	## Create and configure the timer
	#attack_timer = Timer.new()
	#attack_timer.wait_time = 0.8
	#attack_timer.one_shot = true
	#attack_timer.timeout.connect(_on_attack_timer_timeout)
	#add_child(attack_timer)
#
#func _process(delta):
	#if takingDamage:
		#takingDamageTimer -= delta
		#if takingDamageTimer <= 0:
			#takingDamage = false
	#if !is_on_floor():
		#velocity.y += gravity * delta
		#velocity.x = 0
	#
	#if Global.playerAlive:
		#isEnemyChase = true
	#elif !Global.playerAlive:
		#isEnemyChase = false
	#
	#Global.enemyTanahDamageAmount = damageToDeal
	#Global.enemyTanahDamageZone = $enemyTanahDealDamage
	#
	#player = Global.playerBody
	#
	#move(delta)
	#handleAnimation()
	#move_and_slide()
#
#func move(delta):
	#if !dead:
		#if !isEnemyChase:
			#velocity += dir * speed * delta
		#elif isEnemyChase and !takingDamage:
			#var dirToPlayer = position.direction_to(player.position) * speed
			#velocity.x = dirToPlayer.x
			#dir.x = abs(velocity.x) / velocity.x
		#elif takingDamage:
			#var knockbackDir = position.direction_to(player.position) * knockbackForce
			#velocity.x = knockbackDir.x
		#isRoaming = true
			#
	#elif dead:
		#velocity.x = 0
#
#func handleAnimation():
	#var animatedSprite = $AnimatedSprite2D
	#if !dead and !takingDamage:
		#if isDealingDamage:
			#animatedSprite.play("attack")
		#else:
			#animatedSprite.play("run")
			#if dir.x == -1:
				#animatedSprite.flip_h = false
			#elif dir.x == 1:
				#animatedSprite.flip_h = true
	#elif !dead and takingDamage:
		#animatedSprite.play("hit")
	#elif dead and isRoaming:
		#isRoaming = false
		#animatedSprite.play("death")
		#await get_tree().create_timer(0.8).timeout
		#handleDeath()
#
#func handleDeath():
	#self.queue_free()
#
#func _on_direction_timer_timeout() -> void:
	#$DirectionTimer.wait_time = choose([1.5, 2.0, 2.5])
	#if !isEnemyChase:
		#dir = choose([Vector2.RIGHT, Vector2.LEFT])
		#velocity.x = 0
	#
#func choose(array):
	#array.shuffle()
	#return array.front()
	#
#func _on_enemy_tanah_hitbox_area_entered(area: Area2D) -> void:
	#var damage = Global.playerDamageAmount
	#if area == Global.playerDamageZone:
		#takeDamage(damage)
#
#func takeDamage(damage):
	#health -= damage
	#takingDamage = true
	#if health <= healthMin:
		#health = healthMin
		#dead = true
	#else:
		#takingDamage = true
		#takingDamageTimer = takingDamageDuration
	#print(str(self), "Health sekarang = ", health)
#
#func _on_enemy_tanah_deal_damage_area_entered(area: Area2D) -> void:
	#if area == Global.playerhitBox:
		#isDealingDamage = true
		#attack_timer.stop()
#
#func _on_enemy_tanah_deal_damage_area_exited(area: Area2D) -> void:
	#if area == Global.playerhitBox:
		#attack_timer.start()
#
#func _on_attack_timer_timeout():
	#isDealingDamage = false
		#
		#
		#
