extends GutTest

const MINE := preload("res://scripts/objects/mine.gd")

func _make_audio(name: String) -> AudioStreamPlayer:
	var a := AudioStreamPlayer.new()
	a.name = name
	return a

func _make_mine() -> Node2D:
	var mine := MINE.new()

	# Minimal children the script expects
	var anim := AnimatedSprite2D.new()
	anim.name = "AnimatedSprite2D"
	anim.sprite_frames = SpriteFrames.new() # empty is fine since we won't assert animation
	mine.add_child(anim)

	mine.add_child(_make_audio("Boom"))
	mine.add_child(_make_audio("Beep"))
	var t := Timer.new(); t.name = "BeepTimer"; mine.add_child(t)

	var kill := Area2D.new();  kill.name = "KillZone";      mine.add_child(kill)
	var inner := Area2D.new(); inner.name = "InnerWarning"; mine.add_child(inner)
	var outer := Area2D.new(); outer.name = "OuterWarning"; mine.add_child(outer)

	add_child_autofree(mine)
	mine._ready()
	return mine

func _nodes(m: Node) -> Dictionary:
	return {
		"kill":  m.get_node("KillZone") as Area2D,
		"inner": m.get_node("InnerWarning") as Area2D,
		"outer": m.get_node("OuterWarning") as Area2D,
	}

func test_ready_joins_group():
	var mine := _make_mine()
	assert_true(mine.is_in_group("mines"), "Mine should join 'mines' group in _ready")

func test_kill_sets_triggered_and_disables_zones():
	var mine := _make_mine()
	var n := _nodes(mine)

	var body := Node2D.new()
	body.add_to_group("players")

	mine._on_kill_entered(body)
	await get_tree().process_frame

	assert_true(mine.triggered, "Mine should be marked triggered after kill")
	assert_false(n.kill.monitoring,  "KillZone monitoring should be disabled")
	assert_false(n.inner.monitoring, "InnerWarning monitoring should be disabled")
	assert_false(n.outer.monitoring, "OuterWarning monitoring should be disabled")
