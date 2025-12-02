# Jacob Ashmore and Blas Antunez

#This script handles how the exit of Alligator Dentistry is activated,
#thereby allowing players to complete the level

extends Area2D

const ACTIVE_TEXTURE = preload("res://assets/craftpix-net-965938-free-effects-for-platformer-pixel-art-pack/6 Extra/Objects/Capsule/4.png")
const FINISHED_TEXTURE = preload("res://assets/craftpix-net-965938-free-effects-for-platformer-pixel-art-pack/6 Extra/Objects/Capsule/1.png")

signal win_trigger

@onready var sprite: Sprite2D = $Sprite2D

var is_activated: bool = false
var is_finished: bool = false
var players_in_game: int = Net.players.size()

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("players"):
		return

	# Only the peer that controls this player should send the request.
	# That peer actually knows what item is being held.
	if not body.is_multiplayer_authority():
		return

	var peer_id := body.get_multiplayer_authority()
	var held_name := ""

	if body.has_method("get_held_item_name"):
		held_name = body.get_held_item_name()

	print("[Exit] local peer ", multiplayer.get_unique_id(),
		" sending exit request for player ", peer_id,
		" holding '", held_name, "'")

	# Send the request *only* to the server (peer_id 1)
	server_request_exit.rpc_id(1, peer_id, held_name)


@rpc("any_peer", "call_local", "reliable")
func server_request_exit(peer_id: int, held_name: String) -> void:
	# This runs on all peers, but only the server actually processes it
	if not multiplayer.is_server():
		return

	if is_finished:
		return

	print("[Exit][SERVER] got exit request from ", peer_id,
		" with held item '", held_name, "'")

	# ----- PHASE 1: Exit not activated yet -----
	if not is_activated:
		if held_name == "Exit 1":
			print("[Exit][SERVER] Exit activated by peer ", peer_id, " with Exit 1.")
			activate_exit.rpc()          # Tell everyone to update visuals
			handle_player_exit.rpc(peer_id)
		else:
			print("[Exit][SERVER] Peer ", peer_id,
				" entered exit but does not have Exit 1.")
		return

	# ----- PHASE 2: Exit already activated -----
	print("[Exit][SERVER] Activated exit reached by peer: ", peer_id)
	handle_player_exit.rpc(peer_id)


@rpc("any_peer", "call_local", "reliable")
func activate_exit() -> void:
	if multiplayer.is_server():
		is_activated = true
	sprite.texture = ACTIVE_TEXTURE


@rpc("any_peer", "call_local", "reliable")
func handle_player_exit(peer_id: int) -> void:
	for p in get_tree().get_nodes_in_group("players"):
		if str(peer_id) == str(p.name):
			p.queue_free()

	if multiplayer.is_server():
		players_in_game -= 1
		print("[Exit][SERVER] Player exited. Remaining players in game: ", players_in_game)

		if players_in_game <= 0:
			trigger_win.rpc()


@rpc("any_peer", "call_local", "reliable")
func trigger_win() -> void:
	if multiplayer.is_server():
		is_finished = true

	sprite.texture = FINISHED_TEXTURE
	emit_signal("win_trigger")
