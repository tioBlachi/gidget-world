extends Node

const MAX_CLIENTS = 2

var players: PackedInt32Array = []

@onready var network_ui = $NetworkUI
@onready var ip_input = $NetworkUI/VBoxContainer/IP_Input
@onready var port_input = $NetworkUI/VBoxContainer/Port_Input
@onready var option_button: OptionButton = $"../LevelManager/LevelSelectorUI/VBoxContainer/OptionButton"

@onready var host_id_label = $"../ServerManager/ServerManagerUI/VBoxContainer/HostID"
@onready var client_id_label = $"../ServerManager/ServerManagerUI/VBoxContainer/ClientID"
@onready var lm = $"../LevelManager"

var selected_level
var ready_peers = {}
var level_path = ""

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_connected_to_server)
	multiplayer.connection_failed.connect(_connection_failed)
	multiplayer.server_disconnected.connect(_server_disconnected)


# --- Host Functions ---

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
	
	print("Hosting server with ID: %d" % local_peer_id)
	
	print_players_list()
	_update_player_labels()

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
	_update_player_labels()
	
# --- RPCs (Remote Procedure Calls) ---

# The server sends RPC to all peers except itself.
# The `_sync_players` method should only be called on remote peers.
@rpc("any_peer")
func _sync_players(synced_players: PackedInt32Array):
	players = synced_players
	_update_player_labels()
	print_players_list()
	
@rpc("any_peer", "call_local")
func change_scene_rpc(level_path: String):
	lm.load_level(level_path)
	

@rpc("any_peer")
func _level_ready_rpc(peer_id: int) -> void:
	ready_peers[peer_id] = true
	print("Peer %d reports level ready" % peer_id)
	if multiplayer.is_server() and ready_peers.size() == players.size():
		_assign_authority()  # safe: nodes exist now
		
@rpc("authority", "call_local")
func _assign_authority():
	if not multiplayer.is_server():
		return
	if players.size() < 2:
		push_warning("Not enough players to assign authority."); return

	var p1 = get_tree().get_root().find_child("Player1", true, false)
	var p2 = get_tree().get_root().find_child("Player2", true, false)
	if p2 == null:
		push_warning("Player nodes not found in scene."); return

	var server_id := 1
	var client_id = players[1] if players[0] == server_id else players[0]

	_set_player_authority.rpc(p1.name, server_id)
	_set_player_authority.rpc(p2.name, client_id)


@rpc("any_peer", "call_local")
func _set_player_authority(player_name: String, peer_id: int) -> void:
	var node = get_tree().get_root().find_child(player_name, true, false)
	if node:
		node.set_multiplayer_authority(peer_id)
		print("Set %s authority -> %d (by %d)" % [player_name, peer_id, multiplayer.get_unique_id()])


# --- Signal Handlers ---

func _on_peer_connected(id: int):
	if multiplayer.is_server():
		print("Server: Client with ID %d connected." % id)
		_add_player_to_server(id) 
		
		# Update the server's state locally
		_update_player_labels()
		print_players_list()
		
		# Now, send the RPC to all OTHER peers
		_sync_players.rpc(players)
		
		if players.size() >= MAX_CLIENTS:
			_all_players_loaded()
		
func _on_peer_disconnected(id: int):
	if multiplayer.is_server():
		var index = players.find(id)
		
		if index != -1:
			players.remove_at(index)
			print("Server: Player %s disconnected." % id)
			
			# Update the server's state locally
			_update_player_labels()
			print_players_list()
			
			_sync_players.rpc(players)


func _connected_to_server():
	print("Client %d Successfully connected to the server!" % multiplayer.get_unique_id())

func _connection_failed():
	print("Client: Connection failed.")

func _server_disconnected():
	print("Client: Disconnected from server.")
	players.clear()
	_update_player_labels()
	print_players_list()
	
# --- UI Update Functions ---
	
func _update_player_labels():	
	if players.is_empty():
		return

	for player_id in players:
		if player_id == 1:
			host_id_label.text = "Host ID: " + str(player_id)
		else:
			client_id_label.text = "Client ID: " + str(player_id)
			
func _add_player_to_server(id: int):
	players.push_back(id)
	print("Server: Added player %d to list." % id)

func print_players_list():
	print("--- Current Players List (IDs Only) ---")
	print(players)
	print("--- Current Peers List (IDs Only) ---")
	print(multiplayer.get_peers())
	print("---------------------------------------")


func _all_players_loaded():
	if not multiplayer.is_server():
		return

	var level_path := ""
	if selected_level == "Herding Cats":
		level_path = "res://scenes/Levels/herding_cats.tscn"
	elif selected_level == "Lab Escape":
		level_path = "res://scenes/Levels/lab-escape.tscn"
	else:
		print("No level selected"); return

	ready_peers.clear()
	change_scene_rpc.rpc(level_path)  # one call → runs on server + clients
	# DO NOT call _assign_authority() here; wait for _level_ready_rpc pings
	
func _on_option_button_item_selected(index: int) -> void:
	selected_level = option_button.get_item_text(index)
	print(selected_level)
