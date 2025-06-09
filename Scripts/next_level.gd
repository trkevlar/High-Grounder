extends Area2D

const FILE_BEGIN = "res://Scenes/Areas/Levels/Level_"

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		PlayerStats.save_from_player(body)
		Global.player_health = body.health
		Global.player_has_sword = body.has_sword
		Global.player_skills = body.active_skills.duplicate()
		
		var bosses = get_tree().get_nodes_in_group("Boss")
		for boss in bosses:
			if not boss.dead:
				var popup = get_tree().current_scene.get_node("MessagePopup")
				if popup:
					popup.show_message("Boss Is Still Alive!")

				return
				
		var current_scene_file = get_tree().current_scene.scene_file_path
		var next_level_number = current_scene_file.to_int() + 1
		
		
		var next_level_path = FILE_BEGIN + str(next_level_number) +".tscn"
		print(next_level_path)
		get_tree().change_scene_to_file(next_level_path)
