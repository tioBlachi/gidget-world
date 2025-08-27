extends GutTest

# Minimal player expected by key_card.gd
class FakePlayer:
	extends Node2D
	var facing_right := true
	var picked := false
	func _init():
		name = "Player"  # key_card checks begins_with("Player")
	func pickup_keycard(k): picked = true


func _make_keycard(parent: Node) -> Area2D:
	var kc := Area2D.new()
	kc.set_script(load("res://scripts/key_card.gd"))
	# Provide required child so `$collect_sfx.play()` won't error
	var s := AudioStreamPlayer.new()
	s.name = "collect_sfx"
	kc.add_child(s)
	parent.add_child(kc)
	return kc

func test_pickup_reparents_and_calls_player():
	# Scene root
	var root := Node2D.new()
	add_child_autofree(root)

	# Keycard and player
	var kc := _make_keycard(root)
	kc._ready()  # okay if it tries to connect to door
	var player := FakePlayer.new()
	root.add_child(player)

	# Keycard gets picked up here
	kc._on_body_entered(player)
	await get_tree().process_frame

	assert_true(kc.collected, "Keycard should be marked collected")
	assert_eq(kc.get_parent(), player, "Keycard should reparent under the player")
	assert_true(player.picked, "Player.pickup_keycard should be called")
