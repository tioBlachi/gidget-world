extends Node

const SCENES: Dictionary = {
	"lawnmower madness": "res://scenes/Levels/lawnmower_madness.tscn",
	"Herding Cats": "res://scenes/Levels/herding_cats.tscn",
	"Lab Escape": "res://scenes/Levels/lab-escape.tscn",
	"Urban Uprising": "res://scenes/Levels/urban_uprising.tscn",
	"Car Dodge": "res://scenes/Levels/carDodge.tscn",
	"Title": "res://scenes/UI/Title.tscn",
	"Testing" : "res://scenes/DevTools/Testing.tscn",
	"Lobby" : "res://scenes/UI/Lobby.tscn"
}

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
