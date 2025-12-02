extends Node2D

@onready var player_scene = preload("res://scenes/player/player.tscn")
@onready var pSpawner = $pSpawner
@onready var player1marker = $PlayerMarkers/Player1Marker
@onready var player2marker = $PlayerMarkers/Player2Marker
@onready var popup = $PopupUI/restart_screen

var players_in_game := Net.players.size()

func _ready() -> void:
	for player in get_tree().get_nodes_in_group("players"):
		player.is_gravity_level = true
	var players_in_scene = get_tree().get_nodes_in_group("players")
	#print("Nodes in 'players' group: ", players_in_scene)
	if multiplayer.is_server():
		await get_tree().physics_frame
		spawn_players.rpc(Net.players)



func _on_death_line_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		body.die()
		


func _on_exit_line_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		body.queue_free()
		players_in_game -= 1
		check_win()
		
func check_win() -> void:
	print("Checking for win...")
	print(players_in_game)
	if players_in_game <= 0:
		Global.level_ended.emit() # Cause all heat-seek enemies to despawn
		# Set state on all peers, then pause
		popup.set_level_state.rpc(popup.LEVEL_STATE.COMPLETE)
		popup.pause()
		
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
		if multiplayer.get_unique_id() == peer_id:
			var cam: Camera2D = player.get_node("Camera2D")
			cam.make_current()
