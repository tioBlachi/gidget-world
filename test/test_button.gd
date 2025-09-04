extends GutTest

class FakeFloor:
	extends RigidBody2D
	var is_flimsy := false
	var is_open := false
	var unfreeze_called := false
	func unfreeze(): unfreeze_called = true

class FakePlayer:
	extends Node2D
	func _init():
		name = "Player1"

func _make_button() -> Node2D:
	var btn := Node2D.new()
	btn.set_script(load("res://scripts/objects/button.gd"))
	var anim := AnimatedSprite2D.new(); anim.name = "AnimatedSprite2D"; btn.add_child(anim)
	var click := AudioStreamPlayer.new(); click.name = "ClickSound"; btn.add_child(click)
	return btn

func test_button_presses_and_unfreezes_floors():
	var btn := _make_button()
	add_child_autofree(btn)

	var f1 := FakeFloor.new()
	var f2 := FakeFloor.new(); f2.is_flimsy = true   # should NOT unfreeze
	var f3 := FakeFloor.new(); f3.is_open = true     # should NOT unfreeze
	get_tree().get_root().add_child(f1); f1.add_to_group("cell_floor")
	get_tree().get_root().add_child(f2); f2.add_to_group("cell_floor")
	get_tree().get_root().add_child(f3); f3.add_to_group("cell_floor")

	var player := FakePlayer.new()

	# Actions
	btn._on_area_2d_body_entered(player)
	await get_tree().process_frame  # flush call_deferred

	# Assertions
	assert_true(btn.is_pressed, "Button should be marked pressed")
	assert_true(f1.unfreeze_called, "Non-flimsy, closed floor should unfreeze")
	assert_true(f2.unfreeze_called, "Flimsy floor should NOT unfreeze")
	assert_false(f3.unfreeze_called, "Already open floor should NOT unfreeze")
