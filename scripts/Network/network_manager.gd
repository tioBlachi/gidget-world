extends Node

const MAX_CLIENTS = 2

var players: PackedInt32Array = []

@onready var network_ui = $NetworkUI
@onready var ip_input = $NetworkUI/VBoxContainer/IP_Input
@onready var port_input = $NetworkUI/VBoxContainer/Port_Input
@onready var option_button: OptionButton = $"../LevelManager/LevelSelectorUI/VBoxContainer/OptionButton"

@onready var host_id_label = $"../ServerManager/ServerManagerUI/VBoxContainer/HostID"
@onready var client_id_label = $"../ServerManager/ServerManagerUI/VBoxContainer/ClientID"

var selected_level

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

	# Add the host's ID to the player list.
	_add_player_to_server(local_peer_id)
	
	print("Hosting server with ID: %d" % local_peer_id)
	
	print_players_list() # Print the list after host starts
	_update_player_labels() # Update UI on the host

# --- Client Functions ---

func start_client():
	var peer = ENetMultiplayerPeer.new()
	var ip = ip_input.text
	var port = int(port_input.text)
	var error = peer.create_client(ip, port)
	if error != OK:
		print("Error: Cannot connect as client: %s" % error)
		return

	multiplayer.multiplayer_peer = peer
	
	print("Attempting to connect to server...")
	_update_player_labels()
	
# --- RPCs (Remote Procedure Calls) ---

# This RPC is sent by the server to all clients to sync player IDs.
@rpc("any_peer")
func _sync_players(synced_players: PackedInt32Array):
	players = synced_players
	_update_player_labels()
	print_players_list()

# --- Signal Handlers ---

# Emitted on the server when a new client connects.
func _on_peer_connected(id: int):
	if multiplayer.is_server():
		print("Server: Client with ID %d connected." % id)
		# Server adds the new client's ID to its list.
		_add_player_to_server(id) 
		# Sync the updated player list with all clients.
		_sync_players.rpc("any_peer", players)
		# for everybody "any_peer", sync the players arrary
		print_players_list()
		_update_player_labels()
		
func _on_peer_disconnected(id: int):
	if multiplayer.is_server():
		# Find the index of the ID in the list.
		var index = players.find(id)
		
		# Check if the ID was actually found.
		if index != -1:
			# Remove the element at the found index.
			players.remove_at(index)
			print("Server: Player %s disconnected." % id)
			
			# Sync the updated player list with all clients.
			_sync_players.rpc("any_peer", players)
			
			# _update_player_labels() is now handled by the RPC on all peers.
			print_players_list()


# Emitted on a client when a connection is successful.
func _connected_to_server():
	print("Client %d Successfully connected to the server!" % multiplayer.get_unique_id())
	# The server will send the _sync_players RPC which updates the local 'players' list
	# and calls _update_player_labels() and print_players_list().

# Emitted on a client when the connection fails.
func _connection_failed():
	print("Client: Connection failed.")

# Emitted on a client when the server disconnects.
func _server_disconnected():
	print("Client: Disconnected from server.")
	players.clear()
	_update_player_labels()
	print_players_list()
	
# --- UI Update Functions (corrected) ---
	
func _update_player_labels():
	# Reset labels to default state.
	host_id_label.text = "Host ID: N/A"
	client_id_label.text = "Client ID: N/A"
	
	if players.is_empty():
		return

	# The players list SHOULD be synced here
	for player_id in players:
		if player_id == 1:
			host_id_label.text = "Host ID: " + str(player_id)
		else:
			client_id_label.text = "Client ID: " + str(player_id)
			
	if players[0] == 1 and players.size() >= MAX_CLIENTS:
		_all_players_loaded()
		
# --- Internal Helper for Host#func _all_players_loaded():
	#if players.size() == MAX_CLIENTS:
		#get_tree().change_scene ---

func _add_player_to_server(id: int):
	# Add the player ID to the local player list on the server.
	players.push_back(id)
	print("Server: Added player %d to list." % id)

# ----- Print debugging messages

func print_players_list():
	print("--- Current Players List (IDs Only) ---")
	print(players)
	print("---------------------------------------")

func _all_players_loaded():
	if players.size() == MAX_CLIENTS:
		if selected_level == "Herding Cats":
			get_tree().change_scene_to_file("res://scenes/Levels/herding_cats.tscn")
		else:
			print("Yeah, you cannot go somewhere you have not set up yet")

func _on_option_button_item_selected(index: int) -> void:
	selected_level = option_button.get_item_text(index)
	print(selected_level)
