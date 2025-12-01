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

func _setup_level_logic():
	# Placeholder
	pass

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
		# I had to scale the players down here
		# this is just an arbitrary number but
		# they seem to be a good size for the level
		# may need to adjust the JUMP_VELOCITY for 
		# each player so it works for what you need in
		# the level
		player.scale = Vector2(0.15, 0.15)
		player.JUMP_VELOCITY = -400.0
		pSpawner.add_child(player)
		if multiplayer.get_unique_id() == peer_id:
			var cam: Camera2D = player.get_node("Camera2D")
			cam.make_current()
			cam.zoom = Vector2(2,2)
