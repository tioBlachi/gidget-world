# Blas Antunez
# Script for setting up the win conditions in Car Dodge level

extends Node2D

@onready var player_scene = preload("res://scenes/player/player.tscn")
@onready var player1marker: Marker2D = $PlayerMarkers/Player1Marker
@onready var player2marker: Marker2D = $PlayerMarkers/Player2Marker
@onready var pSpawner: MultiplayerSpawner = $pSpawner
@onready var popup := $PopupUI/restart_screen

var players_spawned := false
var players_in_game := Net.players.size()

func _ready() -> void:
	if Net.players.size() >= 2:
		spawn_players.rpc(Net.players)


@rpc("authority", "call_local", "reliable")
func spawn_players(p_array: PackedInt32Array) -> void:
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
				cam.zoom = Vector2(3, 3)
		else:
			push_warning("Player %s has no Camera2D!" % player.name)


func _on_goal_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		body.queue_free()
		players_in_game -= 1
		check_win()

func check_win() -> void:
	print("Checking for win...")
	print(players_in_game)
	if players_in_game <= 0:
		popup.set_level_state.rpc(popup.LEVEL_STATE.COMPLETE)
		popup.pause()
