# Blas Antunez

extends Node2D

@export var map_limits: Rect2 = Rect2(-1573, -1415, 4000, 2250)
@onready var player_scene = preload("res://scenes/player/player.tscn")
@onready var player1marker: Node2D = $PlayerMarkers/Player1Marker
@onready var player2marker: Node2D = $PlayerMarkers/Player2Marker
@onready var pSpawner: Node = $pSpawner
@onready var popup: Control = $PopupUI/restart_screen

var players_in_game := Net.players.size()

func _ready() -> void:
	if multiplayer.is_server():
		await get_tree().physics_frame
		spawn_players.rpc(Net.players)
		
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
		player.scale = Vector2(0.2, 0.2)
		player.JUMP_VELOCITY = -400.0
		pSpawner.add_child(player)
		if multiplayer.get_unique_id() == peer_id:
			var cam: Camera2D = player.get_node("Camera2D")
			cam.make_current()
			cam.zoom = Vector2(2,2)
			
func get_map_limits() -> Rect2:
	return map_limits	


func _on_spikes_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		body.die()


func _on_finish_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		body.queue_free()
		players_in_game -= 1
		check_win()
		
#func check_win() -> void:
	#print("Checking for win...")
	#print(players_in_game)
	#if players_in_game <= 0:
		#popup.current_state = popup.LEVEL_STATE.COMPLETE
		#popup.pause()
func check_win() -> void:
	print("Checking for win...")
	print(players_in_game)
	if players_in_game <= 0:
		# Set state on all peers, then pause
		popup.set_level_state.rpc(popup.LEVEL_STATE.COMPLETE)
		popup.pause()
		
