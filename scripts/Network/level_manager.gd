extends Node

@onready var level_root = $LevelRoot

var current_level: Node = null

func load_level(path : String):
	if current_level and is_instance_valid(current_level):
		current_level.queue_free()
		current_level = null
		await get_tree().process_frame
		
	var packed = load(path)
	if packed == null:
		push_error("[Level Manager] Could not find scene path %s" % path)
	
	$LevelSelectorUI.hide()
	$"../Panel".hide()
	$"../Background".hide()
	$"../NetworkManager/NetworkUI".hide()
	$"../ServerManager/ServerManagerUI".hide()
	   	
	current_level = packed.instantiate()
	level_root.add_child(current_level)
