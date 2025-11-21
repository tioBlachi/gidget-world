extends Node

var current_level_idx: int

const SCENES: Dictionary = {
	"Bird Hopping" : "res://scenes/Levels/BirdHopping.tscn",
	"Sewer Climb" : "res://scenes/Levels/sewer_climb.tscn",
	"Sewer Dive" : "res://scenes/Levels/FallingInSewer.tscn",
	"Blob Chase" : "res://scenes/Levels/BlobChase.tscn",
	"Alligator Dentistry" : "res://scenes/Levels/alligator_dentistry.tscn",
	"Herding Cats": "res://scenes/Levels/HerdingCats.tscn",
	"Lab Escape": "res://scenes/Levels/lab-escape.tscn",
	"Urban Uprising": "res://scenes/Levels/urban_uprising.tscn",
	"Car Dodge": "res://scenes/Levels/carDodge.tscn",
	"Lawnmower Madness": "res://scenes/Levels/lawnmower_madness.tscn",
	"Title": "res://scenes/UI/Title.tscn",
	"Testing" : "res://scenes/DevTools/Testing.tscn",
	"Lobby" : "res://scenes/UI/Lobby.tscn",
	"Final" : "res://scenes/Levels/Final.tscn"
}

const LEVEL_ORDER := [
	"Lab Escape",
	"Sewer Dive",
	"Alligator Dentistry",
	"Sewer Climb",
	"Herding Cats",
	"Lawnmower Madness",
	"Urban Uprising",
	"Bird Hopping",
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
	"BirdHopping": false,
	"Final": false,
}

func _ready() -> void:
	current_level_idx = 0

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
