extends Control

var default_ip := "localhost"
var default_port := 8080

func join_lobby():
	if Net._is_dedicated_server():
		print("[TITLE] Dedicated server build: skipping client join.")
		return

	if not Net.start_client(default_ip, default_port):
		print("[CLIENT] Could not start client peer")
		return

	print("[CLIENT] Connecting to server...")
	await multiplayer.connected_to_server
	print("[CLIENT] Connected!")
	SceneManager.switch_scene("Lobby")
