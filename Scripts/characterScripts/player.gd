extends CharacterBody2D
class_name player

@onready var animation = $AnimatedSprite2D
@onready var attack_area = $AttackArea
@onready var sword_sfx = $SFX/sword_slash
@onready var hit_sfx = $SFX/enemy_hit

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

var has_sword: bool = false
var has_key: bool = false

var is_hit: bool = false

var active_skills: Array[PlayerSkill] = []

# Shield
var is_blocking: bool = false
var block_stamina = 100.0
var max_block_stamina = 100.0
var block_cooldown: float = 0.0
var block_cooldown_duration: float = 5.0
var block_depletion_rate: float = 20.0  # Stamina lost per second while blocking
var block_hit_depletion: float = 30.0   # Additional stamina lost per hit
var block_regen_rate: float = 15.0      # Stamina regained per second when not blocking
var block_damage_reduction: float = 0.7 # 70% damage reduction when blocking
var can_block: bool = true

# Signals for UI updates
signal health_changed(new_health: int, max_health: int)
signal stamina_changed(new_stamina: float, max_stamina: float)
signal skill_added(skill: PlayerSkill)
signal damage_updated(new_damage: int)

func _ready():
	health = Global.player_health
	has_sword = Global.player_has_sword
	Global.load_player_skills(self)
	Global.playerBody = self
	dead = false
	canTakingDamage = true
	Global.playerAlive = true
	Global.playerDamageZone = attack_area
	Global.playerhitBox = $playerHitbox

	# Muat data dari PlayerStats (jika ada)
	#PlayerStats.apply_to_player(self)
	active_skills.clear()
	
	# Muat skills dari Global saja
	for skill in Global.player_skills:
		# Gunakan langsung apply_skill_effect tanpa memicu signal
		_internal_add_skill(skill)
	
	# Emit initial health and stamina values
	emit_signal("health_changed", health, healthMax)
	emit_signal("stamina_changed", block_stamina, max_block_stamina)
	
func _internal_add_skill(skill: PlayerSkill):
	var existing_skill: PlayerSkill = null
	for s in active_skills:
		if s.type == skill.type:
			existing_skill = s
			break

	if existing_skill:
		existing_skill.value += skill.value
	else:
		active_skills.append(skill)
	
	apply_skill_effect(skill)  # Tetap terapkan efek
	
func _physics_process(delta: float) -> void:
	# Update block cooldown
	if block_cooldown > 0:
		block_cooldown -= delta
		if block_cooldown <= 0:
			can_block = true
	
	# Handle block stamina regeneration/depletion
	if is_blocking:
		block_stamina = max(0, block_stamina - block_depletion_rate * delta)
		if block_stamina <= 0:
			break_block()
	elif block_stamina < max_block_stamina and not is_blocking:
		block_stamina = min(max_block_stamina, block_stamina + block_regen_rate * delta)
	
	# Emit stamina changes
	emit_signal("stamina_changed", block_stamina, max_block_stamina)
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	if !dead and !is_hit:
		var direction := Input.get_axis("left", "right")
		if !attacking and !is_blocking:  # Only allow movement and jump when not blocking
			# Handle jump
			if Input.is_action_just_pressed("jump") and is_on_floor():
				velocity.y = JUMP_VELOCITY
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
			if has_sword and Input.is_action_just_pressed("attack"):
				if is_on_floor():
					attacking = true
					attackType = "attack"
				else:
					attacking = true
					attackType = "airAttack"
					
				setDamage(attackType)
				handleAttackAnimation(attackType)
		
		# Movement
		if is_blocking:
			velocity.x = 0  # Prevent horizontal movement while blocking
		else:
			if direction:
				velocity.x = direction * current_speed
			else:
				velocity.x = move_toward(velocity.x, 0, current_speed)
		toggle_flip_sprite(direction)
		checkHitbox()
	move_and_slide()

func _process(_delta):
	# Skip block input handling if dead
	if dead:
		return
	# Handle block input
	if has_sword and Input.is_action_pressed("attack2") and is_on_floor() and can_block and not dead:
		if not is_blocking and block_stamina > 10:  # Need at least 10 stamina to start blocking
			start_blocking()
	elif is_blocking:
		stop_blocking()

func start_blocking():
	is_blocking = true
	attacking = false  # Cancel any attack
	current_speed = base_speed * 0.3  # Keep for compatibility, though movement is disabled
	velocity.x = 0  # Ensure no horizontal movement
	animation.play("attack2")  # Use attack2 animation as block animation
	print("Blocking activated")

func stop_blocking():
	if is_blocking:
		is_blocking = false
		current_speed = base_speed
		if not attacking and is_on_floor():  # Only go back to idle if not attacking
			update_movement_animation()
		print("Blocking deactivated")

func break_block():
	is_blocking = false
	can_block = false
	block_cooldown = block_cooldown_duration
	current_speed = base_speed
	velocity.x = 0  # Ensure no movement after block break
	animation.play("attack2")  # Keep attack2 for block break to avoid needing new animation
	print("Block broken! Cooldown started")
	await get_tree().create_timer(1.0).timeout  # Show break animation for 1 second
	if not attacking and not dead and is_on_floor():  # Return to idle after break animation
		update_movement_animation()

func checkHitbox():
	var hitboxAreas = $playerHitbox.get_overlapping_areas()
	var totalDamage = 0
	for hitbox in hitboxAreas:
		var parent = hitbox.get_parent()
		if parent is flyEnemy and parent.isDealingDamage and !parent.dead:
			takeDamage(Global.crabDamageAmount)
			parent.isDealingDamage = false
		elif parent is enemyTanah and parent.isDealingDamage and !parent.dead:
			totalDamage += Global.enemyTanahDamageAmount
		elif parent is enemyMushroom and !parent.dead:
			if parent.isDealingDamage:
				totalDamage += Global.enemyMushroomDamageAmount
		#elif parent is enemyHuman and !parent.dead:
			#if parent.isDealingDamage:
				#totalDamage += Global.enemyHumanDamageAmount
	
	if totalDamage > 0 and canTakingDamage:
		takeDamage(totalDamage)

func _get_total_damage_resistance() -> float:
	var resist := 0.0
	for s in active_skills:
		if s.type == PlayerSkill.SkillType.DAMAGE_RESISTANCE:
			resist += s.value           # kalau boleh stack
	return clamp(resist, 0.0, 0.8)      # batasi 80 % supaya tak kebal total


func takeDamage(damage):
	if damage <= 0 or dead or is_taking_damage:
		return
	
	# Handle blocked damage
	if is_blocking and block_stamina > 0 and not dead:
		# Reduce damage and consume extra stamina for hit
		var resist = _get_total_damage_resistance()
		var reduced_damage = damage
		reduced_damage *= (1.0 - resist)              # kurangi oleh resistensi
		reduced_damage *= (1.0 - block_damage_reduction)  # lalu kurangi oleh block
		block_stamina = max(0, block_stamina - block_hit_depletion)  # Extra stamina loss per hit
		health -= reduced_damage
		animation.play("attack2")  # Reinforce block animation
		print("Blocked attack! Took ", reduced_damage, " damage (", damage, " blocked)")
		
		# Emit health and stamina changes
		emit_signal("health_changed", health, healthMax)
		emit_signal("stamina_changed", block_stamina, max_block_stamina)
		
		# Check if block broke from this hit
		if block_stamina <= 0:
			break_block()
		else:
			# Return to blocking after hit animation
			await get_tree().create_timer(0.3).timeout
			if is_blocking and is_on_floor() and not dead:  # Still blocking after hit
				animation.play("attack2")
	else:
		# Normal damage handling
		is_taking_damage = true
		is_hit = true
		var resist = _get_total_damage_resistance()
		var final_damage = damage * (1.0 - resist)
		health -= final_damage
		emit_signal("health_changed", health, healthMax)  # Emit health change
		print(health)
		
		if health <= 0:
			dead = true
			Global.playerAlive = false
			is_blocking = false  # Matikan blocking
			attacking = false    # Matikan attacking
			handleDeathAnimation()
			return  
		
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
			elif is_blocking and is_on_floor():
				animation.play("attack2")
			else:
				update_movement_animation()
	
	if health <= 0:
		health = 0
		dead = true
		Global.playerAlive = false
		emit_signal("health_changed", health, healthMax)  # Emit health change
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
	animation.stop()
	$CollisionShape2D.position.y = 5
	animation.play("death")
	
	set_physics_process(false)
	
	await get_tree().create_timer(0.5).timeout
	$Camera2D.zoom.x = 4
	$Camera2D.zoom.y = 4
	await get_tree().create_timer(3.5).timeout
	
	PlayerStats.reset()
	
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
	if is_blocking or dead:  # Can't attack while blocking or dead
		return
		
	if attacking:
		var animasiJalan = str(attack_type)
		animation.play(animasiJalan)
		sword_sfx.play()
		toggleDamageCollision(attack_type)

func toggleDamageCollision(attack_type):
	var damageZoneCollision = attack_area.get_node("CollisionShape2D")
	var waitTime: float
	if attack_type == "attack":
		waitTime = 0.6
	if attack_type == "airAttack":
		waitTime = 0.6
	damageZoneCollision.disabled = false
	await get_tree().create_timer(waitTime).timeout
	damageZoneCollision.disabled = true
	

func _on_animated_sprite_2d_animation_finished() -> void:
	attacking = false
	if dead:
		animation.play("death")  # Ensure death animation plays if dead
	elif is_blocking and is_on_floor():
		animation.play("attack2")
	elif not dead:
		update_movement_animation()

func setDamage(attack_type):
	var base_attack_damage: int
	
	if attack_type == "attack":
		base_attack_damage = 8
	if attack_type == "airAttack":
		base_attack_damage = 12
	Global.playerDamageAmount = calculate_final_damage(base_attack_damage)
	emit_signal("damage_updated", Global.playerDamageAmount) 

func add_skill(new_skill: PlayerSkill):
	var existing_skill: PlayerSkill = null  # deklarasi tipe dengan null
	for skill in active_skills:
		if skill.type == new_skill.type:
			existing_skill = skill
			break

	if existing_skill != null:
		existing_skill.value += new_skill.value
		apply_skill_effect(existing_skill)
		emit_signal("skill_added", existing_skill)
	else:
		active_skills.append(new_skill)
		apply_skill_effect(new_skill)
		emit_signal("skill_added", new_skill)

func apply_skill_effect(skill: PlayerSkill):
	match skill.type:
		PlayerSkill.SkillType.LIFE_STEAL:
			print("Life Steal +", skill.value * 100, "%")
		PlayerSkill.SkillType.STRENGTH_UP:
			print("Damage +", skill.value)
		PlayerSkill.SkillType.HEALTH_UP:
			healthMax += int(skill.value)
			health += int(skill.value)  
			emit_signal("health_changed", health, healthMax)
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
			emit_signal("health_changed", health, healthMax)  # Emit health change
	
	return final_damage


func pick_up_sword():
	has_sword = true
	print("Sword picked up!")

func pick_up_key():
	has_key = true
	print("Key Picked up!")
