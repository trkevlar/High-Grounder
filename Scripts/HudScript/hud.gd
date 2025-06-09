extends CanvasLayer

@onready var health_bar = $MarginContainer/VBoxContainer/HealthBar
@onready var stamina_bar = $MarginContainer/VBoxContainer/StaminaBar

func _ready():
	# Ensure MarginContainer is positioned at top-left
	$MarginContainer.set_anchors_preset(Control.PRESET_TOP_LEFT)
	# Set margins for padding (optional, can be set in editor)
	$MarginContainer.add_theme_constant_override("margin_left", 10)
	$MarginContainer.add_theme_constant_override("margin_top", 10)
	$MarginContainer.add_theme_constant_override("margin_right", 10)
	$MarginContainer.add_theme_constant_override("margin_bottom", 10)
	
	# Initialize progress bars
	if Global.playerBody:
		health_bar.max_value = Global.playerBody.healthMax
		stamina_bar.max_value = Global.playerBody.max_block_stamina
	else:
		print("Warning: PlayerBody not found in Global!")

func _process(delta):
	if Global.playerBody and is_instance_valid(Global.playerBody):
		health_bar.value = Global.playerBody.health
		stamina_bar.value = Global.playerBody.block_stamina
	else:
		health_bar.value = 0
		stamina_bar.value = 0
		print("Warning: PlayerBody is invalid or not set!")
