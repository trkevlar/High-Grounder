extends Node2D

@onready var animation_story = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation_story.play("opening")
	get_tree().create_timer(35).timeout.connect(start_gameplay)


func start_gameplay():
	get_tree().change_scene_to_file("res://Scenes/Areas/game.tscn")
