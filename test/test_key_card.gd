extends GutTest

class FakePlayer:
	extends Node2D
	var move_direction := 1.0
	var picked := false
	var direction := 1.0

	func _init():
		name = "1"
		add_to_group("players")

	func pickup_keycard(_k):
		picked = true


func _make_keycard(parent: Node) -> Area2D:
	var kc := Area2D.new()
	kc.set_script(load("res://scripts/objects/key_card.gd"))  # adjust path if needed
	var s := AudioStreamPlayer.new()
	s.name = "collect_sfx"
	kc.add_child(s)
	parent.add_child(kc)
	return kc

func test_pickup_sets_state_and_calls_player():
	# Make multiplayer think we’re the server
	get_tree().get_multiplayer().multiplayer_peer = OfflineMultiplayerPeer.new()

	var root := Node2D.new()
	add_child_autofree(root)

	var kc := _make_keycard(root)
	kc._ready()

	var player := FakePlayer.new()
	root.add_child(player)

	# Simulate server approval for peer 1
	kc.rpc_request_pickup(1)
	await get_tree().process_frame

	assert_true(kc.collected, "Keycard should be marked collected by the server")
	assert_eq(kc.holder_peer_id, 1, "holder_peer_id should be set to the player's peer id")
	assert_true(player.picked, "Player.pickup_keycard should be called on pickup")
	assert_eq(kc.get_parent(), root, "Keycard should NOT be reparented under the player (visual follow only)")
