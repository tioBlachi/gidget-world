extends Node

signal player_connected(id: int)
signal player_disconnected(id: int)

const NET_VERSION := "V1-min"
const DEFAULT_PORT := 8080
const DEFAULT_MAX_CLIENTS := 2

var players: PackedInt32Array = []  # client peer IDs; host is only added in non-dedicated builds

func _ready() -> void:
	print("Net autoloader ready. Version: ", NET_VERSION, " Server=", multiplayer.is_server())

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_connected_to_server)
	multiplayer.connection_failed.connect(_connection_failed)
	multiplayer.server_disconnected.connect(_server_disconnected)

	# In dedicated/headless builds, auto-host exactly once.
	if _is_dedicated_server() and not is_hosting():
		if start_server(DEFAULT_PORT):
			print("Net: Dedicated/headless server listening on %d" % DEFAULT_PORT)

# ----------------------
# Helpers & guards
# ----------------------

func _is_dedicated_server() -> bool:
	return OS.has_feature("dedicated_server") or OS.has_feature("headless")

func _peer_status_string(p: MultiplayerPeer) -> String:
	if p == null:
		return "NULL"
	match p.get_connection_status():
		MultiplayerPeer.CONNECTION_DISCONNECTED: return "DISCONNECTED"
		MultiplayerPeer.CONNECTION_CONNECTING:   return "CONNECTING"
		MultiplayerPeer.CONNECTION_CONNECTED:    return "CONNECTED"
		_: return str(p.get_connection_status())

# True only if an ENet server is actually bound & connected. Working so far
func is_hosting() -> bool:
	var p := multiplayer.multiplayer_peer
	return p != null \
		and p is ENetMultiplayerPeer \
		and p.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED \
		and multiplayer.is_server()

# For debugging: force a clean restart of the server (clears stale peers)
# Possibly not needed? Was a just in case type of function
func force_start_server(port: int) -> bool:
	var p := multiplayer.multiplayer_peer
	if p != null:
		print("[HOST] force_start: closing stale peer (status=%s)" % _peer_status_string(p))
		p.close()
		multiplayer.multiplayer_peer = null
	players.clear()
	return _create_server_peer(port)

# ----------------------
# Server / Client API
# ----------------------

func start_server(port: int) -> bool:
	var p := multiplayer.multiplayer_peer
	print("[HOST] start_server called. peer=%s status=%s is_server=%s" %
		[ str(p), _peer_status_string(p), str(multiplayer.is_server()) ])

	# if already hosting, do nothing.
	if is_hosting():
		print("Net: Already hosting (peer_id=%d)." % multiplayer.get_unique_id())
		return true

	# If there’s a non-connected peer just "there", get rid of it. Should solve bug
	if p != null and p.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		print("[HOST] clearing non-connected stale peer (status=%s)" % _peer_status_string(p))
		p.close()
		multiplayer.multiplayer_peer = null

	return _create_server_peer(port)

func _create_server_peer(port: int) -> bool:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, DEFAULT_MAX_CLIENTS)
	print("[HOST] create_server(port=%d, max=%d) -> err=%d" % [port, DEFAULT_MAX_CLIENTS, err])

	if err != OK:
		push_error("Net: cannot host on %d (err=%d)" % [port, err])
		return false

	multiplayer.multiplayer_peer = peer
	print("[HOST] set multiplayer_peer. status=%s" % _peer_status_string(multiplayer.multiplayer_peer))

	var host_id := multiplayer.get_unique_id()

	if not _is_dedicated_server():
		if players.find(host_id) == -1:
			players.push_back(host_id)
			player_connected.emit(host_id)

	print("Net: Hosting on UDP %d (server peer_id=%d)" % [port, host_id])
	print("[HOST] listening; players=", players)
	return true

func start_client(host: String, port: int) -> bool:
	if _is_dedicated_server():
		push_error("Net: headless/dedicated build cannot start a client.")
		return false

	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(host, port)
	print("[CLIENT] create_client(%s:%d) -> err=%d" % [host, port, err])

	if err != OK:
		push_error("Net: cannot connect to %s:%d (err=%d)" % [host, port, err])
		return false

	multiplayer.multiplayer_peer = peer
	print("[CLIENT_AFTER_SET_PEER] pid=%s is_server=%s peer=%s" %
		[ str(multiplayer.get_unique_id()), str(multiplayer.is_server()), str(multiplayer.multiplayer_peer) ])
	print("Net: Connecting to %s:%d ..." % [host, port])
	return true

# ----------------------
# Multiplayer signal handlers
# ----------------------

func _connected_to_server() -> void:
	print("[CLIENT] connected_to_server fired. pid=%d" % multiplayer.get_unique_id())

func _connection_failed() -> void:
	print("[CLIENT] connection_failed")

func _server_disconnected() -> void:
	print("[CLIENT] Disconnected from server.")
	players.clear()

func _on_peer_connected(id: int) -> void:
	if multiplayer.is_server():
		if players.find(id) == -1:
			players.push_back(id)
		print("[HOST] peer_connected -> %d" % id)
		if not _is_dedicated_server():
			print("[HOST DEBUG] players now: ", players)
		player_connected.emit(id)
		print("[HOST] players: ", players)

func _on_peer_disconnected(id: int) -> void:
	if multiplayer.is_server():
		var idx := players.find(id)
		if idx != -1:
			players.remove_at(idx)
		print("[HOST] peer_disconnected -> %d" % id)
		player_disconnected.emit(id)
		print("[HOST] players: ", players)
