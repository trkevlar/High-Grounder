extends CanvasLayer

@onready var label: Label = $Label

func show_message(text: String, duration := 2.0) -> void:
	label.text = text
	label.visible = true
	
	await get_tree().create_timer(duration).timeout
	label.visible = false
