extends GutTest

var was_emitted := false
func _mark_emitted() -> void:
	was_emitted = true

class FakePlayer:
	extends Node2D
	var has_keycard := true
	func _init():
		name = "Player"  # door checks begins_with("Player")

func _make_door() -> Area2D:
	var door := Area2D.new()
	door.set_script(load("res://scripts/objects/lab_exit_door.gd"))

	# AnimatedSprite2D child expected by script
	var anim := AnimatedSprite2D.new()
	anim.name = "AnimatedSprite2D"
	# Provide a dummy "opening" animation so play("opening") is valid
	var frames := SpriteFrames.new()
	frames.add_animation("opening")
	anim.sprite_frames = frames
	door.add_child(anim)

	# Audio child expected by script
	var sfx := AudioStreamPlayer.new()
	sfx.name = "LabDoorOpenSfx"
	door.add_child(sfx)

	return door

func before_each() -> void:
	was_emitted = false

func test_door_opens_and_emits_signal_with_keycard():
	# Arrange
	var door := _make_door()
	add_child_autofree(door)
	door.connect("lab_door_opened", Callable(self, "_mark_emitted"))

	var player := FakePlayer.new()

	# Act
	door._on_body_entered(player)
	await get_tree().process_frame

	# Assert
	assert_true(door.is_open, "Door should be open when player has keycard")
	assert_true(was_emitted, "lab_door_opened should be emitted when door opens")

func test_door_stays_closed_without_keycard():
	# Arrange
	var door := _make_door()
	add_child_autofree(door)
	door.connect("lab_door_opened", Callable(self, "_mark_emitted"))

	var player := FakePlayer.new()
	player.has_keycard = false

	# Act
	door._on_body_entered(player)
	await get_tree().process_frame

	# Assert
	assert_false(door.is_open, "Door should remain closed when player lacks keycard")
	assert_false(was_emitted, "Signal should not emit if door didn't open")
