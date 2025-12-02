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

	var peer_id := body.get_multiplayer_authority()

	var held_name := ""
	if body.has_method("get_held_item_name"):
		held_name = body.get_held_item_name()

	request_exit.rpc(peer_id, held_name)


@rpc("any_peer", "call_local", "reliable")
func request_exit(peer_id: int, held_name: String) -> void:
	if not multiplayer.is_server():
		return

	if is_finished:
		return

	# ----- PHASE 1: Exit not activated yet -----
	if not is_activated:
		if held_name == "Exit 1":
			print("Exit activated by peer ", peer_id, " with Exit 1.")
			activate_exit.rpc()
			handle_player_exit.rpc(peer_id)
		else:
			print("Peer ", peer_id, " entered exit but does not have Exit 1.")
		return

	# ----- PHASE 2: Exit already activated -----
	print("Activated exit reached by peer: ", peer_id)
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
		print("Player exited. Remaining players in game: ", players_in_game)

		if players_in_game <= 0:
			trigger_win.rpc()


@rpc("any_peer", "call_local", "reliable")
func trigger_win() -> void:
	# Server tracks finished state
	if multiplayer.is_server():
		is_finished = true

	# This is not working as intended but I will just go with it
	sprite.texture = FINISHED_TEXTURE
	emit_signal("win_trigger")
