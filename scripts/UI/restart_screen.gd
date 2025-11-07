extends Control

var player: Node = null

var is_paused = false
@onready var killzone = get_node("../killzone")
var has_been_triggered = false

func _ready():
	hide()
	await get_tree().process_frame
	_find_local_player()
	_connect_to_killzones()
	$AnimationPlayer.play("RESET_restart")

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

func pause():
	show()
	if has_been_triggered:
		return
	has_been_triggered = true
	if not player:
		_find_local_player()
	if player:
		print("player died, restart menu opening")
		player.set_paused(true)
		is_paused = true
	else:
		print("no player found for this peer")
	$AnimationPlayer.play("blur_restart")

func resume():
	if not player:
		_find_local_player()
	if player:
		player.set_paused(false)
		is_paused = false
	hide()
	$AnimationPlayer.play_backwards("blur_restart")

func testEsc():
	if Input.is_action_just_pressed("esc") and is_paused:
		print("restarting")
		request_restart()

@rpc("any_peer", "call_local")
func change_scene_rpc(scene_name: String) -> void:
	SceneManager.switch_scene(scene_name)

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

func _process(delta):
	testEsc()
