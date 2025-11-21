extends Control
@onready var logo := $GidgetWorldLogo

var default_ip := "localhost"
var default_port := 8080
var logo_pulse_tween : Tween

func _ready() -> void:
	$AnimationPlayer.play("Intro")
	$CutPlayer/Camera2D.set_enabled(false)
	play_intro()

	
func join_lobby():
	SoundManager.play_sfx("select", -35.0)
	await SoundManager.sfx_player.finished
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

func play_intro():
	SoundManager.play_track("title1", -30.0)
