# herding_cats.gd (test-friendly)
extends Node2D

@onready var player_scene = preload("res://scenes/player/player.tscn") # optional in tests
@onready var player1marker: Node2D = get_node_or_null("PlayerMarkers/Player1Marker")
@onready var player2marker: Node2D = get_node_or_null("PlayerMarkers/Player2Marker")
@onready var pSpawner: Node = get_node_or_null("pSpawner")

var players_spawned := 0
var cats_left: int = 0

func _ready() -> void:
	# ---- Single-player / Test mode: skip multiplayer setup entirely ----
	if multiplayer.multiplayer_peer == null:
		# Pure level logic for tests
		_setup_level_logic()
		return

	# ---- Multiplayer path (runtime only) ----
	if multiplayer.is_server():
		# Only attempt spawn if we have a valid spawner and markers
		if pSpawner and player_scene:
			spawn_player.rpc(1)
			var peers := multiplayer.get_peers()
			if peers.size() > 0:
				var client := peers[0]
				if client != 1:
					spawn_player.rpc(client)
					print("Client spawned")
					set_side_scroller.rpc(false)

	_setup_level_logic()

	# Tell the server this peer finished loading the level (only if manager exists)
	var net = get_node_or_null("/root/NetworkManager")
	if net and multiplayer.multiplayer_peer != null:
		net._level_ready_rpc.rpc_id(1, multiplayer.get_unique_id())

func _setup_level_logic() -> void:
	# Count cats currently in the tree
	var cats_group := get_tree().get_nodes_in_group("cats")
	cats_left = cats_group.size()

	# Connect to mines that may explode
	var mines_group := get_tree().get_nodes_in_group("mines")
	for mine in mines_group:
		if is_instance_valid(mine) and mine.has_signal("exploded"):
			# Avoid duplicate connections if re-entering
			if not mine.is_connected("exploded", Callable(self, "_on_mine_exploded")):
				mine.exploded.connect(Callable(self, "_on_mine_exploded"))

func _on_mine_exploded():
	print("A mine exploded!")
	get_tree().paused = true

# ----- Cat Counting -----
func _on_pen_body_entered(body: Node2D) -> void:
	if body.is_in_group("cats"):
		cats_left -= 1
		print(cats_left, " cats left to herd")
		if cats_left <= 0:
			print("All cats herded! You win!")
			get_tree().paused = true
			# TODO: Level complete UI

func _on_pen_body_exited(body: Node2D) -> void:
	if body.is_in_group("cats"):
		cats_left += 1

func set_side_scroller_now(id: int, value: bool):
	if multiplayer.is_server() and pSpawner:
		if id >= 0 and id < pSpawner.get_child_count():
			var node = pSpawner.get_child(id)
			if node and node.has_method("set_side_scroller"):
				node.set_side_scroller.rpc(value)

# ------------ RPCs ----------------
@rpc("authority", "call_local", "reliable")
func spawn_player(id: int):
	if not (pSpawner and player_scene):
		return
	var player_instance = player_scene.instantiate()
	if id != 1:
		player_instance.modulate = Color.hex(0xE0FFFF)
	player_instance.name = str(id)

	var spawn_pos := Vector2.ZERO
	if players_spawned == 0 and player1marker:
		spawn_pos = player1marker.global_position
	elif players_spawned == 1 and player2marker:
		spawn_pos = player2marker.global_position

	player_instance.global_position = spawn_pos
	pSpawner.add_child(player_instance)
	print("Players Spawned: ", players_spawned)
	players_spawned += 1

@rpc("authority", "call_local", "reliable")
func set_side_scroller(value: bool):
	if not pSpawner:
		return
	for p in pSpawner.get_children():
		if p.has_method("set_side_scroller"):
			p.set_side_scroller(value)
