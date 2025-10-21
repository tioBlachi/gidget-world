extends Node2D

@onready var player_scene = preload("res://scenes/player/player.tscn") # optional in tests
@onready var player1marker: Node2D = get_node_or_null("PlayerMarkers/Player1Marker")
@onready var player2marker: Node2D = get_node_or_null("PlayerMarkers/Player2Marker")
@onready var pSpawner: Node = get_node_or_null("pSpawner")

func _ready() -> void:
	if Net.players.size() >= 2:
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
		var sprite := player.get_node("Sprite")
		player.JUMP_VELOCITY = -400
		player.name = str(peer_id)
		sprite.self_modulate = tints[i]
		player.global_position = markers[i].global_position
		player.set_multiplayer_authority(peer_id)

		pSpawner.add_child(player)
		if player.get_script():
			var props = player.get_property_list()
			for prop in props:
				if prop.name == "side_scroller":
					player.set(prop.name, false)

		if multiplayer.get_unique_id() == peer_id:
			var cam: Camera2D = player.get_node("Camera2D")
			cam.make_current()
