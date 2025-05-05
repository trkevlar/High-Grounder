extends CharacterBody2D
class_name player

#@onready var animation = $AnimationPlayer
@onready var animation = $AnimatedSprite2D
@onready var attack_area = $AttackArea

var base_speed = 120.0
var current_speed = base_speed
@export var JUMP_VELOCITY = -300.0

@export var attacking = false
var attackType: String

var health = 100
var healthMax = 100
var healthMin = 0
var dead: bool
var canTakingDamage: bool

var is_hit: bool = false

var active_skills: Array[PlayerSkill] = []

#attack
#func _process(delta):
	#if Input.is_action_just_pressed("attack"):
		#attack()

func _ready():
	Global.load_player_skills(self)
	Global.playerBody = self
	dead = false
	canTakingDamage = true
	Global.playerAlive = true
	Global.playerDamageZone = attack_area
	Global.playerhitBox = $playerHitbox
	
func _physics_process(delta: float) -> void:
	#flip juga
	#if Input.is_action_pressed("left"):
		#sprite.scale.x = abs(sprite.scale.x) * -1
	#if Input.is_action_pressed("right"):
		#sprite.scale.x = abs(sprite.scale.x)
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	if !dead and !is_hit:
		# Handle jump.
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
		var direction := Input.get_axis("left", "right")
		if !attacking:
			if is_on_floor():
				if direction == 0:
					animation.play("idle")
				else:
					animation.play("run")
			if !is_on_floor():
				if velocity.y < 0:
					animation.play("jump")
				if velocity.y > 0:
					animation.play("fall")
			if Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("attack2"):
				attacking = true
				if Input.is_action_just_pressed("attack") and is_on_floor():
					attackType = "attack"
				elif Input.is_action_just_pressed("attack2") and is_on_floor():
					attackType = "attack2"
				else:
					attackType = "airAttack"
				setDamage(attackType)
				handleAttackAnimation(attackType)
		
		#movement
		if direction:
			velocity.x = direction * current_speed
		else:
			velocity.x = move_toward(velocity.x, 0, current_speed)
		toggle_flip_sprite(direction)
		checkHitbox()
	move_and_slide()

func checkHitbox():
	var hitboxAreas = $playerHitbox.get_overlapping_areas()
	var damage: int
	if hitboxAreas:
		#tambahan beberapa
		var hitbox = hitboxAreas.front()
		var parent = hitbox.get_parent()
		if parent is flyEnemy and !parent.dead:
			damage = Global.crabDamageAmount
		elif parent is enemyTanah and !parent.dead:
			damage = Global.enemyTanahDamageAmount
			
	if canTakingDamage:
		takeDamage(damage)

func takeDamage(damage):
	if damage <= 0 or not canTakingDamage or dead:
		return
	is_hit = true
	health -= damage
	print("Player Health: ", health)
	animation.play("hit")
	canTakingDamage = false 
	
	var pre_hit_velocity = velocity
	velocity = Vector2.ZERO
	
	await get_tree().create_timer(0.3).timeout
	if not dead:
		velocity = pre_hit_velocity
		is_hit = false
		
		# Return to appropriate animation
		if attacking:
			handleAttackAnimation(attackType)
		else:
			update_movement_animation()
	if health <= 0:
		health = 0
		dead = true
		Global.playerAlive = false
		handleDeathAnimation()
	else:
		# Start damage cooldown
		takeDamageCooldown(1.0)

func update_movement_animation():
	if is_on_floor():
		if Input.get_axis("left", "right") == 0:
			animation.play("idle")
		else:
			animation.play("run")
	else:
		if velocity.y < 0:
			animation.play("jump")
		else:
			animation.play("fall")

func handleDeathAnimation():
	$CollisionShape2D.position.y = 5
	animation.play("death")
	await get_tree().create_timer(0.5).timeout
	$Camera2D.zoom.x = 4
	$Camera2D.zoom.y = 4
	await get_tree().create_timer(3.5).timeout
	self.queue_free()

func takeDamageCooldown(waitTime):
	canTakingDamage = false
	await get_tree().create_timer(waitTime).timeout
	canTakingDamage = true

func toggle_flip_sprite(dir):
	if dir > 0:
		animation.flip_h = false
		$AttackArea.scale.x = 1
	elif dir < 0:
		animation.flip_h = true
		$AttackArea.scale.x = -1

func handleAttackAnimation(attackType):
	if attacking:
		var animasiJalan = str(attackType)
		animation.play(animasiJalan)
		toggleDamageCollision(attackType)

func toggleDamageCollision(attackType):
	var damageZoneCollision = attack_area.get_node("CollisionShape2D")
	var waitTime: float
	if attackType == "airAttack":
		waitTime = 0.5
	elif attackType == "attack":
		waitTime = 0.6
	elif attackType == "attack2":
		waitTime = 0.4
	damageZoneCollision.disabled = false
	await get_tree().create_timer(waitTime).timeout
	damageZoneCollision.disabled = true
	

func _on_animated_sprite_2d_animation_finished() -> void:
	attacking = false

func setDamage(attackType):
	var base_attack_damage: int
	
	if attackType == "attack":
		base_attack_damage = 8
	elif attackType == "attack2":
		base_attack_damage = 5
	elif attackType == "airAttack":
		base_attack_damage = 10
	Global.playerDamageAmount = calculate_final_damage(base_attack_damage)

func add_skill(skill: PlayerSkill):
	active_skills.append(skill)
	apply_skill_effect(skill)

func apply_skill_effect(skill: PlayerSkill):
	match skill.type:
		PlayerSkill.SkillType.LIFE_STEAL:
			print("Life Steal +", skill.value * 100, "%")
		PlayerSkill.SkillType.STRENGTH_UP:
			print("Damage +", skill.value)
		PlayerSkill.SkillType.HEALTH_UP:
			healthMax += int(skill.value)
			health += int(skill.value)  # Heal sekaligus
			print("Max HP increased to ", healthMax)
		PlayerSkill.SkillType.SPEED_UP:
			current_speed += base_speed * skill.value
			print("Speed +", skill.value)
			
func calculate_final_damage(base_attack_damage: int) -> int:
	var final_damage = base_attack_damage
	for skill in active_skills:
		if skill.type == PlayerSkill.SkillType.STRENGTH_UP:
			final_damage += int(skill.value)
	for skill in active_skills:
		if skill.type == PlayerSkill.SkillType.LIFE_STEAL:
			var heal_amount = final_damage * skill.value
			health = min(health + heal_amount, healthMax)
	
	return final_damage
	

#func attack():
	#var overlapping_objects = $AttackArea.get_overlapping_areas()
	#
	##for area in overlapping_objects:
		##var parent = area.get_parent()
		##parent.queue_free()
		#
	#attacking = true
	#animation.play("attack")







#extends CharacterBody2D
#
#@onready var animated_sprite = $AnimatedSprite2D
#
#@export var SPEED = 300.0
#@export var JUMP_VELOCITY = -400.0
#
#func _ready():
	#Global.playerBody = self
#
#func _physics_process(delta: float) -> void:
	#if not is_on_floor():
		#velocity += get_gravity() * delta
#
	## Handle jump.
	#if Input.is_action_just_pressed("jump") and is_on_floor():
		#velocity.y = JUMP_VELOCITY
#
	#var direction := Input.get_axis("left", "right")
	#if direction:
		#velocity.x = direction * SPEED
	#else:
		#velocity.x = move_toward(velocity.x, 0, SPEED)
	#
	#
	#move_and_slide()
	#handle_movement_animation(direction)
#
#func handle_movement_animation(dir):
	#if is_on_floor():
		#if !velocity:
			#animated_sprite.play("idle")
		#if velocity:
			#animated_sprite.play("run")
			#toggle_flip_sprite(dir)
	#elif !is_on_floor():
		#animated_sprite.play("fall")
#
#func toggle_flip_sprite(dir):
	#if dir == 1:
		#animated_sprite.flip_h = false
	#if dir == -1:
		#animated_sprite.flip_h = true
	
