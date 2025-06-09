extends Control

func _ready() -> void:
	$AnimationPlayer.play("RESET")
	hide()
	get_tree().paused = false

func resume():
	hide()
	get_tree().paused = false
	$AnimationPlayer.play_backwards("blur")
	
func pause():
	show()
	get_tree().paused = true
	$AnimationPlayer.play("blur")

func testEsc():
	if Input.is_action_just_pressed("escape") and get_tree().paused == false:
		pause()
	elif Input.is_action_just_pressed("escape") and get_tree().paused == true:
		resume()

func _on_button_pressed() -> void:
	resume()


func _on_button_2_pressed() -> void:
	resume()
	get_tree().reload_current_scene()


func _on_button_3_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
	

func _process(_delta: float) -> void:
	testEsc()
