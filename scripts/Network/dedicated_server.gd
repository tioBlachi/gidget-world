# dedicated_server.gd
extends Node

const DEFAULT_PORT := 8080
const MAX_CLIENTS := 2

func _ready() -> void:
	# Only run this in headless/dedicated mode
	if OS.has_feature("dedicated_server") or OS.has_feature("headless"):
		print("Dedicated server starting...")
		_start_server()
	else:
		print("Not running as headless/dedicated server. Doing nothing.")

func _start_server() -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(DEFAULT_PORT, MAX_CLIENTS)

	if err != OK:
		push_error("ERROR: Couldn't start server on port %d (err=%d)" % [DEFAULT_PORT, err])
		return

	multiplayer.multiplayer_peer = peer
	print("Server listening on UDP port %d (server peer_id=%d)" % [DEFAULT_PORT, multiplayer.get_unique_id()])

	# Connect multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_connected(id: int) -> void:
	print("Client connected with peer_id:", id)

func _on_peer_disconnected(id: int) -> void:
	print("Client disconnected with peer_id:", id)
