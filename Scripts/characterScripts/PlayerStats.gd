extends Node
class_name PlayerStatsData

# Status Umum
var current_level: int = 1

# Status Player
var health: int = 100
var health_max: int = 100
var has_sword: bool = false
var position: Vector2 = Vector2.ZERO

# Statistik & Buff
var current_speed: float = 120.0
var jump_velocity: float = -350.0

# Skill
var skills: Array[PlayerSkill] = []

# Damage Player
var base_attack_damage := {
	"attack": 8,
	"attack2": 5,
	"airAttack": 10
}

func reset():
	# Digunakan untuk reset data ketika game over
	current_level = 1
	health = 100
	health_max = 100
	has_sword = false
	position = Vector2.ZERO
	current_speed = 120.0
	jump_velocity = -350.0
	skills.clear()

func save_from_player(playera: CharacterBody2D):
	current_level += 1
	health = playera.health
	health_max = playera.healthMax
	has_sword = playera.has_sword
	#position = player.global_position
	skills = playera.active_skills.duplicate(true)

func apply_to_player(playera: CharacterBody2D):
	playera.health = health
	playera.healthMax = health_max
	playera.has_sword = has_sword
	#player.global_position = position
	playera.active_skills = skills.duplicate(true)
