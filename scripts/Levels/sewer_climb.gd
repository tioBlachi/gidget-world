extends Node2D

@export var map_limits: Rect2 = Rect2(130.0, -198.0, 1500, 1100)
@onready var player_scene = preload("res://scenes/player/player.tscn")
@onready var pSpawner = $pSpawner
@onready var player1marker = $PlayerMarkers/Player1Marker
@onready var player2marker = $PlayerMarkers/Player2Marker
@onready var popup = $PopupUI/restart_screen
@onready var door = $LabExitDoor

var players_in_game := Net.players.size()

func _ready() -> void:
	if multiplayer.is_server():
		spawn_players.rpc(Net.players)
	
	door.player_left.connect( func():
		players_in_game -= 1
		check_win()
		)
		
func check_win() -> void:
	print("Checking for win...")
	print(players_in_game)
	if players_in_game <= 0:
		popup.current_state = popup.LEVEL_STATE.COMPLETE
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

func get_map_limits() -> Rect2:
	return map_limits
