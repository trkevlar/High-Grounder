extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Areas/Levels/Level_1.tscn")


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/settings.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()
