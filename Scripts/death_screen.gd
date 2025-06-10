extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	#pass

func death():
	if Global.playerAlive == false:
		#get_tree().paused = true
		show()
		#$AnimationPlayer.play("death_screen")
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	death()


func _on_retry_pressed() -> void:
	print("retry pressed")
	get_tree().reload_current_scene()
	hide()


func _on_mainmenu_pressed() -> void:
	print("back pressed")
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
