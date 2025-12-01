extends Node

var current_level_idx: int

const SCENES: Dictionary = {
	"Bird Hopping" : "res://scenes/Levels/BirdHopping.tscn",
	"Sewer Climb" : "res://scenes/Levels/sewer_climb.tscn",
	"Sewer Dive" : "res://scenes/Levels/FallingInSewer.tscn",
	"Blob Chase" : "res://scenes/Levels/BlobChase.tscn",
	"Alligator Dentistry" : "res://scenes/Levels/alligator_dentistry.tscn",
	"Herding Cats": "res://scenes/Levels/herding_cats.tscn",
	"Lab Escape": "res://scenes/Levels/lab-escape.tscn",
	"Urban Uprising": "res://scenes/Levels/urban_uprising.tscn",
	"Car Dodge": "res://scenes/Levels/carDodge.tscn",
	"Lawnmower Madness": "res://scenes/Levels/lawnmower_madness.tscn",
	"Rooftop Runner": "res://scenes/Levels/Rooftop_Runner.tscn",
	"Title": "res://scenes/UI/Title.tscn",
	"Testing" : "res://scenes/DevTools/Testing.tscn",
	"Lobby" : "res://scenes/UI/Lobby.tscn",
	"Final" : "res://scenes/Levels/Final.tscn",
	"Portal Fight" : "res://scenes/Levels/Portal_Fight.tscn",
	"Fin" : "res://scenes/UI/Fin.tscn",
	"Keycard Kollector" : "res://scenes/Levels/Keycard Kollector.tscn"
}

const LEVEL_ORDER := [
	"Lab Escape",
	"Keycard Kollector",
	"Sewer Dive",
	"Alligator Dentistry",
	"Sewer Climb",
	"Herding Cats",
	"Lawnmower Madness",
	"Car Dodge",
	"Urban Uprising",
	"Bird Hopping",
	"Rooftop Runner",
	"Final",
]

# Level Unlocked State
# Should be updated whenever players complete a level
# SHOULD perisit on server
var level_unlocked := {
	"Lab Escape": true,
	"Sewer Dive": false,
	"Alligator Dentistry": false,
	"Sewer Climb": false,
	"Herding Cats": false,
	"Lawnmower Madness": false,
	"Urban Uprising": false,
	"Bird Hopping": false,
	"Final": false,
}

func _ready() -> void:
	current_level_idx = 0
	
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("next_level"):
		#if multiplayer.get_unique_id() == 1:
		SceneManager.request_next_level.rpc()

	
func _get_level_index(level_name: String) -> int:
	var idx := LEVEL_ORDER.find(level_name)
	return idx if idx != -1 else current_level_idx

func _mark_unlocked(level_name: String) -> void:
	if level_unlocked.has(level_name):
		level_unlocked[level_name] = true


@rpc("authority", "call_local")
func switch_scene(scene_name: String) -> void:
	var path = SCENES.get(scene_name, "")
	if path == "":
		push_error("[SceneManager] Unknown scene name: %s" % scene_name)
		return
	if not OS.has_feature("dedicated_server"):
		print("Switching to Scene: ", path)
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("[SceneManager] Failed to load %s (err=%d)" % [path, err])

@rpc("authority", "call_local")
func start_level(level_name: String) -> void:
	# Align our index with the requested level
	current_level_idx = _get_level_index(level_name)
	_mark_unlocked(level_name)
	switch_scene(level_name)


@rpc("any_peer", "call_local")
func request_next_level() -> void:
	# Only host (peer 1 / server) actually advances the level
	if multiplayer.get_unique_id() == 1:
		next_level.rpc()
		

@rpc("authority", "call_local")
func next_level() -> void:
	current_level_idx += 1

	# If we’re past the last level, go to Fin (or Title)
	if current_level_idx >= LEVEL_ORDER.size():
		switch_scene("Fin")
		return

	var next_name: String = LEVEL_ORDER[current_level_idx]
	_mark_unlocked(next_name)
	switch_scene(next_name)
