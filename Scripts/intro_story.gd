extends Node2D


func _ready() -> void:
	get_tree().create_timer(82).timeout.connect(start_gameplay)


func start_gameplay():
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")


func _on_video_stream_player_finished() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
