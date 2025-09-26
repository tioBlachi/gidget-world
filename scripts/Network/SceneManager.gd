extends Node

const SCENES: Dictionary = {
	"Herding Cats": "res://scenes/Levels/herding_cats.tscn",
	"Lab Escape": "res://scenes/Levels/lab-escape.tscn",
	"Urban Uprising": "res://scenes/Levels/urban_uprising.tscn",
	"Car Dodge": "res://scenes/Levels/carDodge.tscn",
	"Main Menu": "res://scenes/UI/MainMenu.tscn"
}

func switch_scene(scene_name: String) -> void:
	var path = SCENES.get(scene_name, "")
	if path == "":
		push_error("[SceneManager] Unknown scene name: %s" % scene_name)
		return

	print("The selected level path is: ", path)
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("[SceneManager] Failed to load %s (err=%d)" % [path, err])
