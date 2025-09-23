extends Node

func load_level(path: String) -> void:
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("[LevelManager] Failed to load %s (err=%d)" % [path, err])
