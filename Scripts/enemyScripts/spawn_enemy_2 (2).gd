extends Node2D


@export var enemy_scene: PackedScene
@export var spawn_positions: Array[Marker2D]  # Isi dengan node posisi spawn (Position2D misalnya)
@export var max_enemies_alive: int = 5  # jumlah musuh yg boleh hidup sekaligus
@export var max_enemies_total: int = 10 # total musuh yg boleh di-spawn
@export var spawn_interval: float = 2.0
@export var wall_barrier: Node2D

var has_spawned: bool = false
var current_enemies: int = 0
var total_spawned_enemies: int = 0

func _ready():
	$SpawnTimer.wait_time = spawn_interval
	$SpawnTimer.stop()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not has_spawned:
		has_spawned = true
		$SpawnTimer.start()
		activate_barrier()
		
func _on_spawn_timer_timeout() -> void:
	if current_enemies < max_enemies_alive and total_spawned_enemies < max_enemies_total:
		spawn_enemy()
	else:
		$SpawnTimer.stop()
		
func spawn_enemy():
	if spawn_positions.size() == 0:
		print("Error: spawn_positions is empty! Cannot spawn enemy.")
		return
		
	var enemy = enemy_scene.instantiate()
	var spawn_index = randi() % spawn_positions.size()
	enemy.position = spawn_positions[spawn_index].global_position
	get_tree().current_scene.add_child(enemy)
	
	current_enemies += 1
	total_spawned_enemies += 1
	print("Spawned enemy:", total_spawned_enemies, "/", max_enemies_total)

	if enemy.has_signal("enemy_died"):
		enemy.connect("enemy_died", Callable(self, "_on_enemy_died"))
		
func _on_enemy_died() -> void:
	current_enemies -= 1
	print("Enemy died. Remaining alive:", current_enemies)

	# Cek apakah masih boleh spawn lebih banyak musuh
	if has_spawned and !$SpawnTimer.is_stopped():
		return
	if current_enemies < max_enemies_alive and total_spawned_enemies < max_enemies_total:
		$SpawnTimer.start()
	elif current_enemies == 0 and total_spawned_enemies >= max_enemies_total:
		deactivate_barrier()
		print("Wave cleared! Barrier removed.")
		
func activate_barrier():
	if wall_barrier == null:
		print("No barrier assigned for this spawner, skipping activation.")
		return

	wall_barrier.visible = true

	var collision_shape = wall_barrier.get_node("CollisionShape2D")
	if collision_shape:
		collision_shape.call_deferred("set_disabled", false)

	wall_barrier.call_deferred("set_collision_layer", 2)
	wall_barrier.call_deferred("set_collision_mask", 1)



func deactivate_barrier():
	if wall_barrier == null:
		print("No barrier assigned for this spawner, skipping deactivation.")
		return

	wall_barrier.visible = false

	var collision_shape = wall_barrier.get_node("CollisionShape2D")
	if collision_shape:
		collision_shape.call_deferred("set_disabled", true)

	wall_barrier.call_deferred("set_collision_layer", 1)
	wall_barrier.call_deferred("set_collision_mask", 1)
