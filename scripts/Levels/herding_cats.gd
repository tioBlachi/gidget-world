# herding_cats.gd
extends Node2D

@onready var player_scene = preload("res://scenes/player/player.tscn")
@onready var cats_group = get_tree().get_nodes_in_group("cats")
@onready var mines_group = get_tree().get_nodes_in_group("mines")
@onready var player1marker = $PlayerMarkers/Player1Marker
@onready var player2marker = $PlayerMarkers/Player2Marker
@onready var pSpawner = $pSpawner

var players_spawned = 0

var cats_left : int

func _ready() -> void:
	if multiplayer.is_server():
		# Call the private server function to determine and set the flimsy cell.
		spawn_player.rpc(1)
		#set_side_scroller.rpc(1, false)
		var client = multiplayer.get_peers()[0]
		if client != 1:
			spawn_player.rpc(client)
			#set_side_scroller.rpc(client, false)
			print("Client spawned")
		
			set_side_scroller.rpc(false)
			
	# Normal level setup
	cats_left = cats_group.size()
	for mine in mines_group:
		if is_instance_valid(mine) and mine.has_signal("exploded"):
			mine.exploded.connect(Callable(self, "_on_mine_exploded"))

	# Tell the server this peer finished loading the level
	var net = get_node_or_null("/root/NetworkManager")
	if net and multiplayer.multiplayer_peer != null:
		net._level_ready_rpc.rpc_id(1, multiplayer.get_unique_id())  # 1 = server

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
			# TODO: implement level complete UI message
			
			
func _on_pen_body_exited(body: Node2D) -> void:
	if body.is_in_group("cats"):
		cats_left += 1
	
func set_side_scroller_now(id: int, value: bool):
	if multiplayer.is_server():
		var node = pSpawner.get_child(id)
		if node:
			node.set_side_scroller.rpc(value)
			
# ------------ RPCs ----------------
@rpc("authority", "call_local", "reliable")
func spawn_player(id: int):
	var player_instance = player_scene.instantiate()
	player_instance.name = str(id)
	
	var spawn_pos: Vector2
	if players_spawned == 0:
		spawn_pos = player1marker.global_position
	elif players_spawned == 1:
		spawn_pos = player2marker.global_position
	
	player_instance.global_position = spawn_pos
	pSpawner.add_child(player_instance)
	print("Players Spawned: ", players_spawned)
	players_spawned += 1
	
@rpc("authority", "call_local", "reliable")
func set_side_scroller(value: bool):
	var players = pSpawner.get_children()
	for p in players:
		p.side_scroller = value
