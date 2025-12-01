extends Node

var music_player : AudioStreamPlayer
var sfx_player : AudioStreamPlayer

var tracks := {
	"title1" : preload("res://assets/sounds/Music/so-happy-with-my-8-bit-game-301275.mp3"),
	"title2" : preload("res://assets/sounds/Music/Intro.mp3"),
	"boss" : preload("res://assets/sounds/Music/Boss Battle.ogg")
}

var sfx := {
	"select" : preload("res://Sounds/select-003-337609.mp3"),
	"boing" : preload("res://assets/sounds/boing.mp3"),
	"chime" : preload("res://assets/sounds/chime.ogg")
}

func _ready():
	if Engine.is_editor_hint():
		return
		
	music_player = AudioStreamPlayer.new()
	sfx_player = AudioStreamPlayer.new()
	add_child(music_player)
	add_child(sfx_player)
	
func play_track(name: String, volume_db: float = 0.0) -> void:
	if not tracks.has(name):
		push_warning("Unknown music track: %s" % name)
		return

	music_player.stop()
	music_player.stream = tracks[name]
	music_player.volume_db = volume_db
	music_player.play()

@rpc("any_peer", "call_local")
func stop_track() -> void:
	if music_player:
		music_player.stop()

func play_sfx(name: String, volume_db: float = 0.0) -> void:
	if not sfx.has(name):
		push_warning("Unknown sfx : %s" % name)
		return
		
	sfx_player.stop()
	sfx_player.stream = sfx[name]
	sfx_player.volume_db = volume_db
	sfx_player.play()
	
@rpc("any_peer", "call_local")
func stop_sfx():
	if sfx_player:
		sfx_player.stop()
