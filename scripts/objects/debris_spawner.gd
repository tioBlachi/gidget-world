extends Node2D

@export var debris_scene: PackedScene = preload("res://scenes/objects/debris.tscn")

var closest_player: Node2D = null

# Vertical distance BELOW the player
@export var spawn_vertical_offset: float = 500.0

# Horizontal spawn range (doubled)
@export var spawn_horizontal_range: float = 260.0

# How long to spawn debris (in seconds)
@export var spawn_duration: float = 20.0

# Fade and flash durations
@export var flash_duration: float = 0.3
@export var fade_out_duration: float = 1.0

# Internal timer tracking total spawn time
var spawn_time_elapsed: float = 0.0

func _ready():
	randomize()
	$Timer.wait_time = 1.0  # half as frequent as before
	$Timer.one_shot = false
	$Timer.autostart = false
	Global.player_died.connect(remove_self)
	print("Spawner ready function activated")
	start_spawning_process()

func remove_self():
	queue_free()

func start_spawning_process():
	if not closest_player:
		find_closest_player()
	if not closest_player:
		print("No players found in group 'players'!")
		return
	spawn_time_elapsed = 0.0
	$Timer.start()

func _on_timer_timeout():
	if not closest_player:
		return

	spawn_debris()
	spawn_time_elapsed += $Timer.wait_time

	if spawn_time_elapsed >= spawn_duration:
		print("Spawner finished after 20 seconds.")
		$Timer.stop()
		flash_and_fade_out()

func spawn_debris():
	if not is_instance_valid(closest_player):
		find_closest_player()
	if not closest_player:
		return

	var new_debris = debris_scene.instantiate()
	var player_pos = closest_player.global_position

	# Twice as wide horizontally
	var rand_x = randf_range(-spawn_horizontal_range, spawn_horizontal_range)

	# Spawn BELOW the player (positive Y is downward)
	var rand_y = randf_range(spawn_vertical_offset, spawn_vertical_offset * 2)

	new_debris.global_position = Vector2(player_pos.x + rand_x, player_pos.y + rand_y)
	get_tree().root.add_child(new_debris)
	print("New Debris Spawned below player at ", new_debris.global_position)

func find_closest_player():
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		closest_player = null
		return

	var shortest_distance = INF
	var nearest_player = null
	for player in players:
		if is_instance_valid(player):
			var distance = self.global_position.distance_to(player.global_position)
			if distance < shortest_distance:
				shortest_distance = distance
				nearest_player = player
	closest_player = nearest_player

func flash_and_fade_out():
	print("Spawner flashing, then fading out...")

	var tween = create_tween()

	# Step 1: Flash to bright white
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), flash_duration / 2)
	# Step 2: Flash back to normal color
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), flash_duration / 2)
	# Step 3: Fade out alpha to 0 over 1 second
	tween.tween_property(self, "modulate:a", 0.0, fade_out_duration)

	tween.finished.connect(remove_self)
