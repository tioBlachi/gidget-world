extends Control

@onready var level_select := $ButtonContainer/LevelSelect
@onready var player1_label := $Panel/Player1
@onready var player2_label := $Panel/Player2
@onready var players_ready_label := $Panel/PlayersReady  # make sure this node exists
@onready var start_button := $ButtonContainer/StartButton
@onready var new_game_button := $ButtonContainer/NewGame

var selected_level = ""

func _ready() -> void:
	if not Net.players_changed.is_connected(_on_players_changed):
		Net.players_changed.connect(_on_players_changed)

	Net.rpc_id(1, "rpc_request_players")

	var skip := ["Title", "Lobby", "Testing"]
	var scene_names: Array = []
	for scene_name in SceneManager.SCENES.keys():
		if scene_name in skip:
			continue
		scene_names.append(scene_name)
	scene_names.sort()
	for name in scene_names:
		level_select.add_item(name)
	level_select.selected = 0
	
	if level_select.item_count > 0:
		level_select.select(0)
	selected_level = level_select.text

	update_labels()

func _on_players_changed(_p) -> void:
	update_labels()

func update_labels() -> void:
	player1_label.text = "Player 1 Ready!" if Net.players.size() > 0 and Net.players[0] != 0 else "Waiting for Player 1..."
	player2_label.text = "Player 2 Ready!" if Net.players.size() > 1 and Net.players[1] != 0 else "Waiting for Player 2..."

	var both_ready = Net.players.size() > 1 and Net.players[0] != 0 and Net.players[1] != 0
	players_ready_label.visible = both_ready
	if both_ready:
		new_game_button.visible = true
	
	if both_ready and selected_level != "":
		start_button.visible = true


func _on_level_select_item_selected(index: int) -> void:
	selected_level = level_select.get_item_text(index)

func start_game():
	SoundManager.stop_track.rpc()
	Net.rpc_id(1, "rpc_start_game", selected_level)


func _on_new_game_pressed() -> void:
	SoundManager.stop_track.rpc()
	selected_level = SceneManager.LEVEL_ORDER[0]
	Net.rpc_id(1, "rpc_start_game", selected_level)
