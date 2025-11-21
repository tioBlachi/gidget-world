extends Control

@onready var popup_msg = $"PanelContainer/VBoxContainer/HBoxContainer/Pause Menu Text"
@onready var restart_button = $PanelContainer/VBoxContainer/Restart

var player: Node = null

var is_paused = false
var has_been_triggered = false

enum LEVEL_STATE {
	IN_PROGRESS,
	FAILED,
	COMPLETE
}

var current_state: LEVEL_STATE = LEVEL_STATE.IN_PROGRESS:
	set(new_value):
		if current_state == new_value:
			return
		current_state = new_value
		on_state_changed()
	
func _ready():
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS  # keep UI working while paused
	await get_tree().process_frame
	_find_local_player()
	_connect_to_killzones()
	$AnimationPlayer.play("RESET_restart")
	
func on_state_changed():
	print("Level State changed to: ", current_state)
	match current_state:
		LEVEL_STATE.FAILED:
			popup_msg.text = "Level Failed - Retry?"
		LEVEL_STATE.COMPLETE:
			popup_msg.text = "Level Complete!"
			restart_button.text = "Play Next Level"
	
	
func _connect_to_killzones():
	for kz in get_tree().get_nodes_in_group("killzones"):
		if not kz.is_connected("character_died", Callable(self, "_on_player_died")):
			kz.character_died.connect(_on_player_died)
			print("Connected to killzone:", kz.name)

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


#func testEsc():
	#if Input.is_action_just_pressed("esc") and is_paused:
		#print("restarting")
		#request_restart()

@rpc("any_peer", "call_local")
func change_scene_rpc(scene_name: String) -> void:
	SceneManager.switch_scene.rpc_id(1, scene_name)

func _on_resume_pressed() -> void:
	resume()
	

@rpc("any_peer", "call_local")
func request_restart() -> void:
	if multiplayer.get_unique_id() == 1:
		Net.rpc_start_game(get_tree().current_scene.name)

@rpc("any_peer", "call_local")
func _on_restart_pressed() -> void:
	resume()
	request_restart.rpc()

func _on_level_select_pressed() -> void:
	print("Not implemented yet")

@rpc("any_peer", "call_local")
func request_main_menu() -> void:
	if multiplayer.get_unique_id() == 1:
		Net.rpc_start_game("Title")

func _on_quit_menu_pressed() -> void:
	resume()
	request_main_menu.rpc()

func _on_quit_desktop_pressed() -> void:
	get_tree().quit()

func _on_player_died():
	pause()

#func _process(delta):
	#testEsc()
