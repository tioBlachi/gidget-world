extends Node

const MAX_CLIENTS = 2

var players: PackedInt32Array = []

@onready var network_ui = $NetworkUI
@onready var ip_input = $NetworkUI/VBoxContainer/IP_Input
@onready var port_input = $NetworkUI/VBoxContainer/Port_Input
@onready var option_button: OptionButton = $"../LevelManager/LevelSelectorUI/VBoxContainer/OptionButton"
@onready var ready_label = $"../ServerManager/ServerManagerUI/VBoxContainer/ReadyLabel"
@onready var selected_level_label = $"../ServerManager/ServerManagerUI/VBoxContainer/SelectedLevelLabel"
@onready var server_label = $"../ServerManager/ServerManagerUI/VBoxContainer/ServerLabel"
@onready var lm = $"../LevelManager"

var selected_level
var server_started: bool = false
var level_selected: bool = false

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_connected_to_server)
	multiplayer.connection_failed.connect(_connection_failed)
	multiplayer.server_disconnected.connect(_server_disconnected)
	
func start_host():
	var peer = ENetMultiplayerPeer.new()
	var port = int(port_input.text)
	var error = peer.create_server(port, MAX_CLIENTS)
	if error != OK:
		print("Error: Cannot host server: %s" % error)
		return

	multiplayer.multiplayer_peer = peer
	var local_peer_id = multiplayer.get_unique_id()

	_add_player_to_server(local_peer_id)
	
	server_label.text = "Hosting server with ID: %d" % local_peer_id
	server_started = true
# --- Client Functions ---

func start_client():
	var client_peer = ENetMultiplayerPeer.new()
	var ip = ip_input.text
	var port = int(port_input.text)
	var error = client_peer.create_client(ip, port)
	if error != OK:
		print("Error: Cannot connect as client: %s" % error)
		return

	multiplayer.multiplayer_peer = client_peer
	
	print("Attempting to connect to server...")
	
# --- RPCs (Remote Procedure Calls) ---
	
@rpc("any_peer", "call_local")
func change_scene_rpc(level_path: String):
	lm.load_level(level_path)
	
func _on_peer_connected(id: int):
	if multiplayer.is_server():
		print("Server: Client with ID %d connected." % id)
		_add_player_to_server(id) 
		
		#if players.size() >= MAX_CLIENTS:
			#_all_players_loaded()
		
func _on_peer_disconnected(id: int):
	if multiplayer.is_server():
		var index = players.find(id)
		
		if index != -1:
			players.remove_at(index)
			print("Server: Player %s disconnected." % id)

func _connected_to_server():
	print("Client %d Successfully connected to the server!" % multiplayer.get_unique_id())

func _connection_failed():
	print("Client: Connection failed.")

func _server_disconnected():
	print("Client: Disconnected from server.")
	players.clear()
			
func _add_player_to_server(id: int):
	players.push_back(id)
	print("Server: Added player %d to list." % id)
	
func _load_level():
	if not multiplayer.is_server():
		return
	if level_selected == true and server_started == true:
		var level_path := ""
		if selected_level == "Herding Cats":
			level_path = "res://scenes/Levels/herding_cats.tscn"
		elif selected_level == "Lab Escape":
			level_path = "res://scenes/Levels/lab-escape.tscn"
		change_scene_rpc.rpc(level_path)
	else:
		ready_label.text = "The server must be started and a level must be selected"
		return
	
func _on_option_button_item_selected(index: int) -> void:
	selected_level = option_button.get_item_text(index)
	level_selected = true
	selected_level_label.text = "Selected Level: " + selected_level
