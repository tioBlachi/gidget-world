extends Node2D

@onready var player_scene = preload("res://scenes/player/player.tscn")
@onready var player1marker: Node2D = $PlayerMarkers/Player1Marker
@onready var player2marker: Node2D = $PlayerMarkers/Player2Marker
@onready var pSpawner: Node = $pSpawner

func _ready():
	if multiplayer.multiplayer_peer == null:
		return
	
	if multiplayer.is_server():
		spawn_players.rpc(Net.players)

	%"Score Manager".all_keys_collected.connect(func():
		popup.current_state = popup.LEVEL_STATE.COMPLETE
		popup.pause()
		)

	var net = get_node_or_null("/root/NetworkManager")
	if net and multiplayer.multiplayer_peer != null:
		net._level_ready_rpc.rpc_id(1, multiplayer.get_unique_id())

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

		pSpawner.add_child(player)

		var cam: Camera2D = player.get_node("Camera2D")
		cam.enabled = true
		if peer_id == multiplayer.get_unique_id():
			cam.make_current()
