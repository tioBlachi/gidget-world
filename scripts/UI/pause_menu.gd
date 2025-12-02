extends Control

var player: Node = null

var is_paused = false

func _ready():
	hide()
	await get_tree().process_frame
	_find_local_player()
	$AnimationPlayer.play("RESET_restart")

func _find_local_player() -> void:
	for p in get_tree().get_nodes_in_group("players"):
		if p.is_multiplayer_authority():
			player = p
			print("[PauseMenu] Found local player:", p.name)
			return
	print("[PauseMenu] No local player found!")

@rpc("any_peer", "call_local")
func pause():
	if multiplayer.is_server():
		pause_all.rpc()
	else:
		pause.rpc_id(1)
	
@rpc("authority", "call_local")
func pause_all():
	get_tree().paused = true
	is_paused = true
	show()
	$AnimationPlayer.play("blur_restart")

@rpc("any_peer", "call_local")
func resume():
	await get_tree().physics_frame
	if multiplayer.is_server():
		resume_all.rpc()
	else:
		resume.rpc_id(1)
	
@rpc("authority", "call_local")
func resume_all():
	get_tree().paused = false
	is_paused = false
	hide()
	$AnimationPlayer.play_backwards("blur_restart")


func testEsc():
	if Input.is_action_just_pressed("esc") and !is_paused:
		pause.rpc()
	elif Input.is_action_just_pressed("esc") and is_paused:
		print("resuming")
		resume.rpc()

@rpc("any_peer", "call_local")
func change_scene_rpc(scene_name: String) -> void:
	SceneManager.switch_scene(scene_name)

func _on_resume_pressed() -> void:
	resume.rpc()
	

@rpc("any_peer", "call_local")
func request_restart() -> void:
	#if multiplayer.get_unique_id() == 1:
	await get_tree().physics_frame
	var scene = get_tree().current_scene.name
	Net.rpc_start_game(scene)

@rpc("any_peer", "call_local")
func _on_restart_pressed() -> void:
	resume.rpc()
	request_restart.rpc()

func _on_level_select_pressed() -> void:
	print("Not implemented yet")

@rpc("any_peer", "call_local")
func request_main_menu() -> void:
	#if multiplayer.get_unique_id() == 1:
	Net.players.clear()
	Net.rpc_start_game("Title")

func _on_quit_menu_pressed() -> void:
	resume()
	request_main_menu.rpc()

func _on_quit_desktop_pressed() -> void:
	get_tree().quit()

func _process(delta):
	testEsc()
