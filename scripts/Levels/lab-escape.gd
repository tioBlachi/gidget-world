extends Node2D

@onready var player_scene = preload("res://scenes/player/player.tscn")
@onready var cell1 = $LabCell1/CellFloor
@onready var cell2 = $LabCell2/CellFloor
@onready var pSpawner = $pSpawner
@onready var player1marker = $PlayerMarkers/Player1Marker
@onready var player2marker = $PlayerMarkers/Player2Marker

var players_spawned = 0
var jump_needed = 4

func _ready() -> void:
	if multiplayer.is_server():
		# Call the private server function to determine and set the flimsy cell.
		spawn_player.rpc(1)
		var client = multiplayer.get_peers()[0]
		if client != 1:
			spawn_player.rpc(client)
			print("Client spawned")
		
		_set_initial_flimsy_cell()

# This is a regular function on the server
func _set_initial_flimsy_cell():
	randomize()
	var choice = randi() % 2
	
	# After determining the choice on the server, call the RPC.
	set_flimsy_cell.rpc(choice)

# This RPC is executed on all peers to update the cell states
@rpc("call_local", "reliable")
func set_flimsy_cell(choice: int):
	# This RPC must be called by the authority.
	# The "authority" keyword is not needed on the RPC itself if it's called
	# by the server on a node where it has authority.
	
	if choice == 0:
		cell1.is_flimsy = true
		print("Cell 1 is flimsy")
		# The players need to be spawned before this
		# player1.cell_floor = cell1
	else:
		cell2.is_flimsy = true
		print("cell 2 is flimsy")

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
	players_spawned += 1
	

@rpc("authority", "call_local")
func _on_cell2_jump(area: Area2D) -> void:
	if cell1.is_flimsy:
		cell1.freeze = false
	elif cell2.is_flimsy:
		cell2.freeze = false
	 
