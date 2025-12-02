extends Node

const DEFAULT_MAX_CLIENTS := 2
const DEFAULT_PORT := 8080

signal players_changed(players)

var players: PackedInt32Array = []
			
func _ready() -> void:
	if _is_dedicated_server():
		var port := DEFAULT_PORT
		if OS.has_environment("PORT"):
			var s := OS.get_environment("PORT")
			if s.is_valid_int(): port = int(s)
		var ok := become_host(port)
		print("[DEDICATED] features: dedicated_server=", OS.has_feature("dedicated_server"), " headless=", OS.has_feature("headless"))
		print("[DEDICATED] peer_id=", multiplayer.get_unique_id()," port=", port, " started=", ok)
		if not ok:
			push_error("[DEDICATED] Failed to start server on port %d" % port)

func _is_dedicated_server() -> bool:
	return OS.has_feature("dedicated_server") or OS.has_feature("headless")


func is_hosting() -> bool:
	var p := multiplayer.multiplayer_peer
	return p != null \
		and p is ENetMultiplayerPeer \
		and p.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED \
		and multiplayer.is_server()

# ----------------- Server / Client API -----------------

func become_host(port: int) -> bool:
	if is_hosting():
		print("[NET] Already hosting (peer_id=%d)" % multiplayer.get_unique_id())
		return true

	var server_peer := ENetMultiplayerPeer.new()
	var err := server_peer.create_server(port, DEFAULT_MAX_CLIENTS)
	if err != OK:
		if err == ERR_ALREADY_IN_USE:
			print("[NET] Port %d is in use — likely a dedicated server is already running." % port)
		else:
			print("[NET] Failed to start server on port %d (err=%d)." % [port, err])
		return false

	multiplayer.multiplayer_peer = server_peer
	multiplayer.peer_connected.connect(_add_player_to_game)
	multiplayer.peer_disconnected.connect(_del_player)
	multiplayer.connected_to_server.connect(_connected_to_server)
	multiplayer.server_disconnected.connect(_server_disconnected)

	if not _is_dedicated_server():
		var host_id := multiplayer.get_unique_id()
		if players.find(host_id) == -1:
			players.push_back(host_id)
	else:
		print("Dedicated Server Started...")

	return true


# join_as_player2 from youtube
func start_client(host: String, port: int) -> bool:
	var client_peer = ENetMultiplayerPeer.new()
	var err := client_peer.create_client(host, port)
	if err != OK:	
		return false

	multiplayer.multiplayer_peer = client_peer
	print("[NET] Connecting to %s:%d ..." % [host, port])
	return true

# ----------------- Multiplayer signal handlers -----------------

func _connected_to_server() -> void:
	print("[CLIENT] connected (pid=%d)" % multiplayer.get_unique_id())

func _connection_failed() -> void:
	print("[CLIENT] connection_failed")

func _server_disconnected() -> void:
	print("[CLIENT] server_disconnected")
	players.clear()

func _add_player_to_game(id: int) -> void:
	if multiplayer.is_server():
		if players.find(id) == -1:
			players.push_back(id)
		rpc("rpc_send_players", players)
		print("[HOST] peer_connected -> %d ; players=%s" % [id, str(players)])

func _del_player(id: int) -> void:
	if multiplayer.is_server():
		var idx := players.find(id)
		if idx != -1:
			players.remove_at(idx)
		rpc("rpc_send_players", players)
		print("[HOST] peer_disconnected -> %d ; players=%s" % [id, str(players)])
		
# ------------------- RPCs --------------------
@rpc("any_peer", "reliable")
func rpc_request_players():
	if multiplayer.is_server():
		rpc_id(multiplayer.get_remote_sender_id(), "rpc_send_players", players)

@rpc("any_peer", "reliable")
func rpc_send_players(server_players: PackedInt32Array) -> void:
	players = server_players
	emit_signal("players_changed", players)

@rpc("any_peer", "reliable")
func rpc_start_game(level_name: String) -> void:
	if not multiplayer.is_server():
		return
	rpc("rpc_open_level", level_name)

@rpc("any_peer", "call_local", "reliable")
func rpc_open_level(level_name: String) -> void:
	SceneManager.switch_scene(level_name)
