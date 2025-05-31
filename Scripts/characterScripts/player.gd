extends CharacterBody2D
class_name player

#@onready var animation = $AnimationPlayer
@onready var animation = $AnimatedSprite2D
@onready var attack_area = $AttackArea

var base_speed = 120.0
var current_speed = base_speed
@export var JUMP_VELOCITY = -350.0

@export var attacking = false
var attackType: String

var health = 100
var healthMax = 100
var healthMin = 0
var dead: bool
var canTakingDamage: bool
var is_taking_damage = false

var is_hit: bool = false

var active_skills: Array[PlayerSkill] = []

func _ready():
	Global.load_player_skills(self)
	Global.playerBody = self
	dead = false
	canTakingDamage = true
	Global.playerAlive = true
	Global.playerDamageZone = attack_area
	Global.playerhitBox = $playerHitbox
	
func _physics_process(delta: float) -> void:
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
	var totalDamage = 0
	for hitbox in hitboxAreas:
		var parent = hitbox.get_parent()
		if parent is flyEnemy and !parent.dead:
			if parent.isDealingDamage:
				totalDamage += Global.crabDamageAmount
		elif parent is enemyTanah and !parent.dead:
			if parent.isDealingDamage:
				totalDamage += Global.enemyTanahDamageAmount
		elif parent is enemyMushroom and !parent.dead:
			if parent.isDealingDamage:
				totalDamage += Global.enemyMushroomDamageAmount
	
	if totalDamage > 0 and canTakingDamage:
		takeDamage(totalDamage)

func takeDamage(damage):
	if damage <= 0 or not canTakingDamage or dead or is_taking_damage:
		return
	is_taking_damage = true
	is_hit = true
	health -= damage
	print(health)
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
	is_taking_damage = false

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
	velocity = Vector2.ZERO
	$CollisionShape2D.position.y = 5
	animation.play("death")
	
	set_physics_process(false)
	
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

func handleAttackAnimation(attack_type):
	if attacking:
		var animasiJalan = str(attack_type)
		animation.play(animasiJalan)
		toggleDamageCollision(attack_type)

func toggleDamageCollision(attack_type):
	var damageZoneCollision = attack_area.get_node("CollisionShape2D")
	var waitTime: float
	if attack_type == "airAttack":
		waitTime = 0.5
	elif attack_type == "attack":
		waitTime = 0.6
	elif attack_type == "attack2":
		waitTime = 0.4
	damageZoneCollision.disabled = false
	await get_tree().create_timer(waitTime).timeout
	damageZoneCollision.disabled = true
	

func _on_animated_sprite_2d_animation_finished() -> void:
	attacking = false

func setDamage(attack_type):
	var base_attack_damage: int
	
	if attack_type == "attack":
		base_attack_damage = 8
	elif attack_type == "attack2": 
		base_attack_damage = 5
	elif attack_type == "airAttack":
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
