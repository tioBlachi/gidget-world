extends GutTest

const HERD := preload("res://scripts/Levels/herding_cats.gd")

class FakeMine:
	extends Node2D
	signal exploded

class FakePopup:
	extends Node
	const LEVEL_STATE = {
		"RUNNING": 0,
		"FAILED": 1,
		"COMPLETE": 2,
	}

	var current_state: int = LEVEL_STATE.RUNNING
	var pause_called := false

	func pause() -> void:
		pause_called = true

func _make_cat(name := "Cat") -> Node2D:
	var n := Node2D.new()
	n.name = name
	n.add_to_group("cats")
	return n

func _make_player(name := "Player") -> Node2D:
	var n := Node2D.new()
	n.name = name
	n.add_to_group("players")
	return n

func _make_mine() -> Node2D:
	var m := FakeMine.new()
	m.add_to_group("mines")
	return m

func _add(n: Node) -> void:
	get_tree().get_root().add_child(n)
	add_child_autofree(n)

func _attach_fake_popup(level: Node) -> FakePopup:
	var popup := FakePopup.new()
	_add(popup)
	level.popup = popup
	return popup

func before_each() -> void:
	get_tree().paused = false

func test_ready_joins_group_and_counts_cats():
	_add(_make_cat("Cat1"))
	_add(_make_cat("Cat2"))
	_add(_make_cat("Cat3"))

	var level := HERD.new()
	_add(level)

	assert_eq(level.cats_left, 3)

func test_mine_explosion_sets_failed_and_pauses_via_popup():
	var mine := _make_mine()
	_add(mine)

	var level := HERD.new()
	_add(level)  # should connect to mine
	var popup := _attach_fake_popup(level)

	mine.emit_signal("exploded")
	await get_tree().process_frame

	assert_true(popup.pause_called, "Popup.pause should be called when a mine explodes")
	assert_eq(
		popup.current_state,
		popup.LEVEL_STATE.FAILED,
		"Popup state should be FAILED after mine explosion"
	)

func test_pen_enter_decrements_and_triggers_win_when_zero():
	var cat := _make_cat()
	_add(cat)

	var level := HERD.new()
	_add(level)  # cats_left = 1
	var popup := _attach_fake_popup(level)
	get_tree().paused = false

	level._on_pen_body_entered(cat)
	await get_tree().process_frame

	assert_eq(level.cats_left, 0)
	assert_true(popup.pause_called, "Popup.pause should be called when all cats are herded")
	assert_eq(
		popup.current_state,
		popup.LEVEL_STATE.COMPLETE,
		"Popup state should be COMPLETE when all cats are herded"
	)

func test_pen_exit_increments_count():
	# Start with 2 cats
	var cat1 := _make_cat("Cat1"); _add(cat1)
	var cat2 := _make_cat("Cat2"); _add(cat2)

	var level := HERD.new()
	_add(level)  # cats_left = 2
	# popup not needed here because we never hit cats_left <= 0
	get_tree().paused = false

	# One cat enters pen, cats_left = 1 (no win yet)
	level._on_pen_body_entered(cat1)
	await get_tree().process_frame
	assert_eq(level.cats_left, 1)

	# That cat leaves pen, cats_left = 2
	level._on_pen_body_exited(cat1)
	await get_tree().process_frame
	assert_eq(level.cats_left, 2)

func test_player_enter_exit_has_no_effect():
	var player := _make_player()
	_add(player)

	var level := HERD.new()
	_add(level)
	get_tree().paused = false

	level._on_pen_body_entered(player)
	level._on_pen_body_exited(player)
	await get_tree().process_frame

	assert_eq(level.cats_left, 0, "Players shouldn't affect cats_left")
