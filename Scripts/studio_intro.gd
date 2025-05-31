extends Node2D

@onready var animation_intro = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	animation_intro.play("studio_in")
	get_tree().create_timer(3).timeout.connect(studio_out)

func studio_out():
	animation_intro.play("studio_out")
	get_tree().create_timer(3).timeout.connect(start_menu_scene)

func start_menu_scene():
	get_tree().change_scene_to_file("res://Scenes/intro_story.tscn")
