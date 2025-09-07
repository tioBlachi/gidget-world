#extends Node2D
#
#@onready var player_scene = preload("res://scenes/player/player.tscn")
#@onready var cell1 = $LabCell1/CellFloor
#@onready var cell2 = $LabCell2/CellFloor
#@onready var pSpawner = $pSpawner
#@onready var player1marker = $PlayerMarkers/Player1Marker
#@onready var player2marker = $PlayerMarkers/Player2Marker
#
#var players_spawned = 0
#var jump_needed = 4
#
#func _ready() -> void:
	#if multiplayer.is_server():
		#spawn_player.rpc(1)
		#var client = multiplayer.get_peers()[0]
		#if client != 1:
			#spawn_player.rpc(client)
			#print("Client spawned")
		#
		#_set_initial_flimsy_cell()
#
## This is a regular function on the server
#func _set_initial_flimsy_cell():
	#randomize()
	#var choice = randi() % 2
	#
	#set_flimsy_cell.rpc(choice)
#
#@rpc("call_local", "reliable")
#func set_flimsy_cell(choice: int):
	#
	#if choice == 0:
		#cell1.is_flimsy = true
		#print("Cell 1 is flimsy")
	#else:
		#cell2.is_flimsy = true
		#print("cell 2 is flimsy")
#
#@rpc("authority", "call_local", "reliable")
#func spawn_player(id: int):
	#var player_instance = player_scene.instantiate()
	#player_instance.name = str(id)
	#
	#var spawn_pos: Vector2
	#if players_spawned == 0:
		#spawn_pos = player1marker.global_position
	#elif players_spawned == 1:
		#spawn_pos = player2marker.global_position
	#
	#player_instance.global_position = spawn_pos
	#pSpawner.add_child(player_instance)
	#players_spawned += 1
	#
#
#@rpc("authority", "call_local")
#func _on_cell2_jump(area: Area2D) -> void:
	#if cell1.is_flimsy:
		#cell1.freeze = false
	#elif cell2.is_flimsy:
		#cell2.freeze = false
		
extends Node2D

@onready var player_scene = preload("res://scenes/player/player.tscn")
@onready var cell1 = $LabCell1/CellFloor
@onready var cell2 = $LabCell2/CellFloor
@onready var pSpawner = $pSpawner
@onready var player1marker = $PlayerMarkers/Player1Marker
@onready var player2marker = $PlayerMarkers/Player2Marker

var players_spawned := 0

func _ready() -> void:
	add_to_group("lab_escape")
	if multiplayer.is_server():
		spawn_player.rpc(1)
		var peers := multiplayer.get_peers()
		if peers.size() > 0:
			var client := peers[0]
			if client != 1:
				spawn_player.rpc(client)
				print("Client spawned")
		_set_initial_flimsy_cell()

func _set_initial_flimsy_cell():
	randomize()
	var choice = randi() % 2
	set_flimsy_cell.rpc(choice)

@rpc("call_local", "reliable")
func set_flimsy_cell(choice: int):
	if choice == 0:
		cell1.is_flimsy = true
		print("Cell 1 is flimsy")
	else:
		cell2.is_flimsy = true
		print("Cell 2 is flimsy")

@rpc("authority", "call_local", "reliable")
func spawn_player(id: int):
	var player_instance = player_scene.instantiate()
	player_instance.name = str(id)
	var spawn_pos: Vector2 = player1marker.global_position if players_spawned == 0 else player2marker.global_position
	player_instance.global_position = spawn_pos
	pSpawner.add_child(player_instance)
	players_spawned += 1

# ---- NEW: clients report jumps; server validates + unfreezes if needed
@rpc("any_peer", "reliable")
func rpc_report_jump(peer_id: int):
	if not multiplayer.is_server():
		return
	var floor = cell1 if peer_id == 1 else cell2
	if not floor.is_flimsy or floor.is_open:
		return
	floor.jump_count += 1
	if floor.jump_count >= floor.jumps_needed:
		floor.rpc("rpc_unfreeze")
