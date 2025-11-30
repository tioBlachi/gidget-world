extends Node2D

@onready var player_scene = preload("res://scenes/player/player.tscn") # optional in tests
@onready var player1marker: Marker2D = $PlayerMarkers/Player1Marker
@onready var player2marker: Marker2D = $PlayerMarkers/Player2Marker
@onready var pSpawner: MultiplayerSpawner = $pSpawner

var players_spawned := false

func _ready() -> void:
	if Net.players.size() >= 2:
		spawn_players.rpc(Net.players)


@rpc("authority", "call_local", "reliable")
func spawn_players(p_array: PackedInt32Array) -> void:
	# Prevent double-spawning if this RPC gets called twice
	if players_spawned:
		print("CarDodge.spawn_players: already spawned, skipping")
		return
	players_spawned = true

	print("CarDodge.spawn_players called on peer", multiplayer.get_unique_id(), "with", p_array)

	if p_array.size() < 2:
		push_error("spawn_players: need 2 peer IDs, got %d" % p_array.size())
		return

	var markers := [player1marker, player2marker]
	var tints := [Color.WHITE, Color.hex(0xE0FFFF)]

	for i in 2:
		var peer_id := p_array[i]
		var player := player_scene.instantiate()

		player.name = str(peer_id)
		player.global_position = markers[i].global_position
		player.scale = Vector2(0.2, 0.2)
		player.set_multiplayer_authority(peer_id)

		var sprite: Sprite2D = player.get_node("Sprite")
		sprite.self_modulate = tints[i]
		if player.get_script():
			var props = player.get_property_list()
			for prop in props:
				if prop.name == "side_scroller":
					player.set(prop.name, false)

		pSpawner.add_child(player)

		var cam: Camera2D = player.get_node_or_null("Camera2D")
		if cam:
			cam.enabled = true
			if peer_id == multiplayer.get_unique_id():
				cam.make_current()
		else:
			push_warning("Player %s has no Camera2D!" % player.name)
