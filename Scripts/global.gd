extends Node

var playerBody: CharacterBody2D

var playerAlive: bool
var playerDamageZone: Area2D
var playerDamageAmount: int
var playerhitBox: Area2D

var crabDamageZone: Area2D
var crabDamageAmount: int

var enemyTanahDamageZone: Area2D
var enemyTanahDamageAmount: int

var player_skills: Array[PlayerSkill] = []

func save_player_skill(skill: PlayerSkill):
	player_skills.append(skill)

func load_player_skills(player_node: player):
	for skill in player_skills:
		player_node.add_skill(skill)
