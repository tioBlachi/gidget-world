extends Node2D

@onready var player_scene = preload("res://scenes/player/player.tscn") # optional in tests
@onready var player1marker: Node2D = get_node_or_null("PlayerMarkers/Player1Marker")
@onready var player2marker: Node2D = get_node_or_null("PlayerMarkers/Player2Marker")
@onready var pSpawner: Node = get_node_or_null("pSpawner")
@onready var popup := $PopupUI/restart_screen


var cats_left: int = 0

func _ready() -> void:
	if multiplayer.multiplayer_peer == null:
		_setup_level_logic()
		return

	# ---- Multiplayer path (runtime only) ----
	if multiplayer.is_server():
		spawn_players.rpc(Net.players)

	_setup_level_logic()

	# Tell the server this peer finished loading the level (only if manager exists)
	var net = get_node_or_null("/root/NetworkManager")
	if net and multiplayer.multiplayer_peer != null:
		net._level_ready_rpc.rpc_id(1, multiplayer.get_unique_id())	

func _setup_level_logic() -> void:
	var cats_group := get_tree().get_nodes_in_group("cats")
	cats_left = cats_group.size()

	var mines_group := get_tree().get_nodes_in_group("mines")
	for mine in mines_group:
		if is_instance_valid(mine) and mine.has_signal("exploded"):
			if not mine.is_connected("exploded", Callable(self, "_on_mine_exploded")):
				mine.exploded.connect(Callable(self, "_on_mine_exploded"))

func _on_mine_exploded():
	print("A mine exploded!")
	popup.current_state = popup.LEVEL_STATE.FAILED
	popup.pause()
	#get_tree().paused = true
	
	#SceneManager.switch_scene("Lobby")

# ----- Cat Counting -----
func _on_pen_body_entered(body: Node2D) -> void:
	if body.is_in_group("cats"):
		cats_left -= 1
		print(cats_left, " cats left to herd")
		if cats_left <= 0:
			#print("All cats herded! You win!")
			#get_tree().paused = true
			popup.current_state = popup.LEVEL_STATE.COMPLETE
			# TODO: Level complete UI
			popup.pause()

func _on_pen_body_exited(body: Node2D) -> void:
	if body.is_in_group("cats"):
		cats_left += 1

func set_side_scroller_now(id: int, value: bool):
	if multiplayer.is_server() and pSpawner:
		if id >= 0 and id < pSpawner.get_child_count():
			var node = pSpawner.get_child(id)
			if node and node.has_method("set_side_scroller"):
				node.set_side_scroller.rpc(value)

@rpc("authority", "call_local", "reliable")
func spawn_players(p_array: PackedInt32Array) -> void:
	if p_array.size() < 2:
		push_error("spawn_players: need 2 peer IDs, got %d" % p_array.size())
		return
		
	var markers := [player1marker, player2marker]
	var tints := [Color.WHITE, Color.hex(0xE0FFFF)]
	
	for i in 2:
		var peer_id := p_array[i]
		var player := player_scene.instantiate()
		player.name = str(peer_id)
		player.modulate = tints[i]
		player.global_position = markers[i].global_position
		player.set_multiplayer_authority(peer_id)

		pSpawner.add_child(player)
		if player.get_script():
			print("Found script")
			var props = player.get_property_list()
			for prop in props:
				if prop.name == "side_scroller":
					player.set(prop.name, false)

		var cam: Camera2D = player.get_node("Camera2D")
		cam.enabled = false
