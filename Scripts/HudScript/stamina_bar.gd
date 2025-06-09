extends ProgressBar

@export var player_path: NodePath     # drag Player node di inspector
var players: player                    # cache

func _ready() -> void:
	players = get_node(player_path)

	# set nilai awal
	max_value = players.max_block_stamina
	value = players.block_stamina

	# dengarkan sinyal stamina
	players.connect("stamina_changed", self._on_stamina_changed)

func _on_stamina_changed(new_stamina: float, max_stamina: float) -> void:
	# perbarui bar (pakai tween biar halus)
	max_value = max_stamina
	create_tween().tween_property(self, "value", new_stamina, 0.1)
