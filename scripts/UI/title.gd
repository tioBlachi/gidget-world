extends Control

var default_ip := "18.234.63.242"
var default_port := 8080

func join_lobby():
	if not Net.start_client(default_ip, default_port):
		print("Server Not Started")
		return

	print("Connecting to server...")
	await multiplayer.connected_to_server
	print("Connected!")
	SceneManager.switch_scene("Lobby")
