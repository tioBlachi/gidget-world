extends GutTest

const HERD := preload("res://scripts/Levels/herding_cats.gd")

class FakeMine:
	extends Node2D
	signal exploded

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

func before_each() -> void:
	get_tree().paused = false

func test_ready_joins_group_and_counts_cats():
	_add(_make_cat("Cat1"))
	_add(_make_cat("Cat2"))
	_add(_make_cat("Cat3"))

	var level := HERD.new()
	_add(level)  # _ready runs

	assert_true(level.is_in_group("herdingCats"))
	assert_eq(level.cats_left, 3)

func test_mine_explosion_pauses_game():
	var mine := _make_mine()
	_add(mine)

	var level := HERD.new()
	_add(level)  # connects to mine.exploded

	mine.emit_signal("exploded")
	await get_tree().process_frame

	assert_true(get_tree().paused, "Game should pause when a mine explodes")

func test_pen_enter_decrements_and_pauses_when_zero():
	var cat := _make_cat()
	_add(cat)

	var level := HERD.new()
	_add(level)  # cats_left = 1
	get_tree().paused = false

	level._on_pen_body_entered(cat)
	await get_tree().process_frame

	assert_eq(level.cats_left, 0)
	assert_true(get_tree().paused, "Pause when all cats herded")

func test_pen_exit_increments_count():
	# Start with 2 cats
	var cat1 := _make_cat("Cat1"); _add(cat1)
	var cat2 := _make_cat("Cat2"); _add(cat2)

	var level := HERD.new()
	_add(level)  # cats_left = 2
	get_tree().paused = false

	# One cat enters pen, cats_left = 1 (no pause)
	level._on_pen_body_entered(cat1)
	await get_tree().process_frame
	assert_eq(level.cats_left, 1)
	assert_false(get_tree().paused)

	# That cat leaves pen, cats_left = 2
	level._on_pen_body_exited(cat1)
	await get_tree().process_frame
	assert_eq(level.cats_left, 2)
	assert_false(get_tree().paused)

func test_player_enter_exit_has_no_effect():
	var player := _make_player()
	_add(player)

	var level := HERD.new()
	_add(level)  # cats_left = 0
	get_tree().paused = false

	level._on_pen_body_entered(player)
	level._on_pen_body_exited(player)
	await get_tree().process_frame

	assert_eq(level.cats_left, 0, "Players shouldn't affect cats_left")
	assert_false(get_tree().paused, "Players entering alone should not pause")
