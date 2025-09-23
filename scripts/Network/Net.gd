extends Node

const NET_VERSION := "V1-min"
const DEFAULT_PORT := 8080
const DEFAULT_MAX_CLIENTS := 2

func _ready():
	print("Net autoloader ready. Version: ", 
	NET_VERSION, 
	" Server=", 
	multiplayer.is_server())
	
func _is_dedicated_server() -> bool:
	return OS.has_feature("dedicated_server") or OS.has_feature("headless")

func start_server(port: int, max_clients: int = DEFAULT_MAX_CLIENTS) -> bool:
	if _is_dedicated_server():
		print("Net: headless/dedicated build — UI start_server() ignored.")
		return false

	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, max_clients)
	if err != OK:
		push_error("Net: cannot host on %d (err=%d)" % [port, err])
		return false

	multiplayer.multiplayer_peer = peer
	print("Net: Hosting on UDP %d (server peer_id=%d)" % [port, multiplayer.get_unique_id()])
	return true
