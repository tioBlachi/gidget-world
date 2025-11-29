#extends GutTest
#
#func _make_cell_floor() -> RigidBody2D:
	#var cf := RigidBody2D.new()
	#cf.set_script(load("res://scripts/objects/cell_floor.gd"))
	#var sfx := AudioStreamPlayer.new(); sfx.name = "OpenDoor"; cf.add_child(sfx)
	#return cf
#
#func test_flimsy_floor_opens_after_enough_jumps():
	#var cf := _make_cell_floor()
	#add_child_autofree(cf)
	#cf.is_flimsy = true
	#cf.jumps_needed = 1
	#cf._ready()  # sets freeze = true
#
	#cf.count_jumps()
	#await get_tree().create_timer(1.1).timeout  # internal wait is 1.0
#
	#assert_false(cf.freeze, "Floor should unfreeze (open) after enough jumps")
	#assert_true(cf.first_cell_open, "first_cell_open should be set")
#
#func test_unfreeze_opens_non_flimsy_after_delay():
	#var cf := _make_cell_floor()
	#add_child_autofree(cf)
	#cf._ready()
	#assert_true(cf.freeze)
#
	#cf.unfreeze()
	#await get_tree().create_timer(0.8).timeout  # internal wait is 0.75
	#assert_true(cf.is_open, "Flag should be set open")
	#assert_false(cf.freeze, "RigidBody2D should be unfrozen")
extends GutTest

func _make_cell_floor() -> RigidBody2D:
	var cf := RigidBody2D.new()
	cf.set_script(load("res://scripts/objects/cell_floor.gd"))
	var sfx := AudioStreamPlayer.new(); sfx.name = "OpenDoor"; cf.add_child(sfx)
	return cf

func test_rpc_unfreeze_drops_floor():
	var cf := _make_cell_floor()
	add_child_autofree(cf)

	cf._ready()
	assert_true(cf.freeze, "Floor should start frozen")

	cf.rpc_unfreeze()
	# rpc_unfreeze() defers actual unfreeze to next frame
	await get_tree().process_frame
	await get_tree().process_frame

	assert_true(cf.is_open, "Flag should be set open after rpc_unfreeze")
	assert_false(cf.freeze, "RigidBody2D should be unfrozen after rpc_unfreeze")

func test_late_joiner_starts_unfrozen_when_is_open_true():
	var cf := _make_cell_floor()
	add_child_autofree(cf)

	# Simulate replicated state arriving before _ready()
	cf.is_open = true
	cf._ready()

	# Unfreeze is deferred in _ready() if is_open was already true
	await get_tree().process_frame

	assert_false(cf.freeze, "Late joiner should see floor already unfrozen")

func test_rpc_unfreeze_is_idempotent():
	var cf := _make_cell_floor()
	add_child_autofree(cf)

	cf._ready()
	cf.rpc_unfreeze()
	await get_tree().process_frame
	await get_tree().process_frame

	var was_open = cf.is_open
	var was_frozen := cf.freeze

	# Call again—should not refreeze or error
	cf.rpc_unfreeze()
	await get_tree().process_frame

	assert_true(cf.is_open, "Calling rpc_unfreeze twice should keep is_open true")
	assert_false(cf.freeze, "Calling rpc_unfreeze twice should keep floor unfrozen")
