extends Node2D

@onready var player_scene = preload("res://scenes/player/player.tscn")
@onready var player1marker: Node2D = $PlayerMarkers/Player1Marker
@onready var player2marker: Node2D = $PlayerMarkers/Player2Marker
@onready var pSpawner: Node = $pSpawner

func _ready():
	
	
	
	if multiplayer.multiplayer_peer == null:
		_setup_level_logic()
		return
	
	if multiplayer.is_server():
		spawn_players.rpc(Net.players)

	_setup_level_logic()

	var net = get_node_or_null("/root/NetworkManager")
	if net and multiplayer.multiplayer_peer != null:
		net._level_ready_rpc.rpc_id(1, multiplayer.get_unique_id())
		
		
	#Change Layers and Masks
	configure_players_for_new_interaction_zone()
	#Change layers and masks
	Global.configure_players_for_new_interaction_zone()
	

func _setup_level_logic():
	
	# Placeholder
	pass

@rpc("authority", "call_local", "reliable")
func spawn_players(p_array: PackedInt32Array):
	if p_array.size() < 2:
		push_error("spawn_players: need 2 peer IDs, got %d" % p_array.size())
		return

	var markers := [player1marker, player2marker]
	var tints := [Color.WHITE, Color.hex(0xE0FFFF)]

	for i in 2:
		var peer_id := p_array[i]
		var player = player_scene.instantiate()
		player.name = str(peer_id)
		player.modulate = tints[i]
		player.global_position = markers[i].global_position
		player.set_multiplayer_authority(peer_id)
		
		if player.get_script():
			var props = player.get_property_list()
			for prop in props:
				if prop.name == "side_scroller":
					player.set(prop.name, false)
					
		player.set_side_scroller(false)
		pSpawner.add_child(player)
		

		var cam: Camera2D = player.get_node("Camera2D")
		cam.enabled = true
		if peer_id == multiplayer.get_unique_id():
			cam.make_current()


func _on_exit_body_entered(body: Node2D) -> void:
	pass # Replace with function body.



func configure_players_for_new_interaction_zone():
	# Retrieve all nodes currently in the "players" group
	var players = get_tree().get_nodes_in_group("players")
	
	# Iterate through each player node found
	for player in players:
		# Check if the node is a PhysicsBody2D or Area2D
		if player is PhysicsBody2D or player is Area2D:
			
			# --- Set the Collision Layer: Only Layer 3 is ON ---
			player.collision_layer = 0 # Clear all layers first
			player.set_collision_layer_value(3, true)
			
			# --- Set the Collision Mask: Only Layers 1, 2, and 4 are ON ---
			# Using bitwise operation for efficiency: Layer 1(1) | Layer 2(2) | Layer 4(8)
			player.collision_mask = 1 | 2 | 8 
			
			print("Configured player: ", player.name, " -> Layer: 3 only | Mask: 1, 2, and 4 only.")
		else:
			print("Node ", player.name, " is in 'players' group but is not a valid physics body.")
