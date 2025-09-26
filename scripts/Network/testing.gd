extends Node

@onready var network_ui = $NetworkManager/NetworkUI
@onready var ip_input = $NetworkManager/NetworkUI/VBoxContainer/IP_Input
@onready var port_input = $NetworkManager/NetworkUI/VBoxContainer/Port_Input
@onready var option_button: OptionButton = $LevelManager/LevelSelectorUI/VBoxContainer/OptionButton
@onready var ready_label = $ServerManager/ServerManagerUI/VBoxContainer/ReadyLabel
@onready var selected_level_label = $ServerManager/ServerManagerUI/VBoxContainer/SelectedLevelLabel
@onready var server_label = $ServerManager/ServerManagerUI/VBoxContainer/ServerLabel

var selected_level: String
var server_started := false
var level_selected := false

func _ready() -> void:
	for scene_name in SceneManager.SCENES.keys():
		option_button.add_item(scene_name)
		option_button.select(0)
		
func start_server() -> void:
	var port := int(port_input.text)
	if Net.become_host(port):
		var local_peer_id := multiplayer.get_unique_id()
		server_label.text = "Hosting server with ID: %d" % local_peer_id
		server_started = true
	else:
		print("NetworkManager: server not started (headless or error).")

func start_client() -> void:
	var ip = ip_input.text.strip_edges() 

	var port := int(port_input.text)
	print("[JOIN] dialing %s:%d" % [ip, port])

	if Net.start_client(ip, port):
		print("Attempting to connect to server...")
	else:
		print("NetworkManager: client not started (headless or error).")


@rpc("any_peer", "call_local")
func change_scene_rpc(scene_name: String) -> void:
	SceneManager.switch_scene(scene_name)

func _load_level() -> void:
	if not multiplayer.is_server() or OS.has_feature("dedicated_server"):
		return
	if level_selected and server_started:
		change_scene_rpc.rpc(selected_level)
	else:
		ready_label.text = "The server must be started and a level must be selected"

func _on_option_button_item_selected(index: int) -> void:
	selected_level = option_button.get_item_text(index)
	level_selected = true
	selected_level_label.text = "Selected Level: " + selected_level
